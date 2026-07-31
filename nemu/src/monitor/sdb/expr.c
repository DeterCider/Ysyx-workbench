/***************************************************************************************
 * Copyright (c) 2014-2024 Zihao Yu, Nanjing University
 *
 * NEMU is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan
 *PSL v2. You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 *
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY
 *KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
 *NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 *
 * See the Mulan PSL v2 for more details.
 ***************************************************************************************/

#include <isa.h>

/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include "common.h"
#include "memory/paddr.h"
#include <regex.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

enum {
  TK_NOTYPE = 256,
  TK_EQ,
  TK_NEQ,
  TK_AND,
  TK_DEC,
  TK_HEX,
  TK_MINUS,
  TK_NEG,
  TK_DERF,
  TK_MUL,
  TK_REG

  /* TODO: Add more token types */

};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

    /* TODO: Add more rules.
     * Pay attention to the precedence level of different rules.
     */

    {" +", TK_NOTYPE}, // spaces
    {"u", 'u'},        // unsigned
    {"\\+", '+'},      // plus
    {"==", TK_EQ},     // equal
    {"-", '-'},        // minus or negative
    {"\\*", '*'},      // multiply or dereference
    {"/", '/'},        // divide
    {"!=", TK_NEQ},
    {"&&", TK_AND},
    {"\\(", '('},
    {"\\)", ')'},
    {"\\$[A-Za-z0-9$]{2,3}", TK_REG},
    {"0[xX][0-9a-fA-F]+", TK_HEX},
    {"[0-9]+", TK_DEC}

};

#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

typedef struct token {
  int type;
  char str[32];
} Token;

static Token tokens[100005] __attribute__((used)) = {};
static int nr_token __attribute__((used)) = 0;

static int check_left() {
  if (nr_token != 0 && ((tokens[nr_token - 1].type == TK_DEC) ||
                        (tokens[nr_token - 1].type == TK_HEX) ||
                        (tokens[nr_token - 1].type == TK_REG) ||
                        (tokens[nr_token - 1].type == ')')))
    return 2;
  else
    return 1;
}

static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;

  while (e[position] != '\0') {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 &&
          pmatch.rm_so == 0) {

        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;
        // Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s", i,
        //     rules[i].regex, position, substr_len, substr_len, substr_start);
        position += substr_len;
        if (rules[i].token_type == '-') {
          if (check_left() == 2)
            tokens[nr_token].type = TK_MINUS;
          else
            tokens[nr_token].type = TK_NEG;
        } else if (rules[i].token_type == '*') {
          if (check_left() == 2)
            tokens[nr_token].type = TK_MUL;
          else
            tokens[nr_token].type = TK_DERF;
        } else if (rules[i].token_type == TK_NOTYPE ||
                   rules[i].token_type == 'u')
          break;
        else
          tokens[nr_token].type = rules[i].token_type;

        strncpy(tokens[nr_token].str, substr_start, substr_len);
        tokens[nr_token].str[substr_len] = '\0';
        nr_token++;

        break;
      }
    }

    if (i == NR_REGEX) {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }

  return true;
}

// number stack and operator statck
static word_t val[65536] = {0};
static int op[65536] = {0};
static int vtop = 0, otop = 0;

static int pri(int type) {
  switch (type) {
  case TK_NEG:
  case TK_DERF:
    return 4;
  case TK_MUL:
  case '/':
    return 3;
  case '+':
  case TK_MINUS:
    return 2;
  case TK_EQ:
  case TK_NEQ:
    return 1;
  case TK_AND:
    return 0;
  default:
    return -1; // '(' 等其他
  }
}

static bool pop_and_calc() {
  if (otop == 0)
    return false;
  int o = op[--otop];
  if (o == TK_NEG) {
    if (vtop < 1)
      return false;
    word_t a = val[--vtop];
    val[vtop++] = -a;
  } else if (o == TK_DERF) {
    if (vtop < 1)
      return false;
    word_t addr = val[--vtop];
    val[vtop++] = paddr_read(addr, 4);
  } else {
    // 二元运算符
    if (vtop < 2)
      return false;
    word_t b = val[--vtop];
    word_t a = val[--vtop];
    switch (o) {
    case '+':
      val[vtop++] = a + b;
      break;
    case TK_MINUS:
      val[vtop++] = a - b;
      break;
    case TK_MUL:
      val[vtop++] = a * b;
      break;
    case '/':
      if (b == 0) {
        return false;
      }
      val[vtop++] = a / b;
      break;
    case TK_EQ:
      val[vtop++] = (a == b) ? 1 : 0;
      break;
    case TK_NEQ:
      val[vtop++] = (a != b) ? 1 : 0;
      break;
    case TK_AND:
      val[vtop++] = (a && b) ? 1 : 0;
      break;
    default:
      return false;
    }
  }
  return true;
}
//右结合一定先入栈，如--5
static bool is_right_assoc(int type) {
  return (type == TK_NEG || type == TK_DERF);
}

// 处理运算符入栈（优先级高的先弹出）
static bool push_op(int type) {
  int cur_pri = pri(type);
  while (otop > 0 && op[otop - 1] != '(' &&
         (pri(op[otop - 1]) > cur_pri ||
          (pri(op[otop - 1]) == cur_pri && !is_right_assoc(type)))) {
    if (!pop_and_calc())
      return false;
  }
  op[otop++] = type;
  return true;
}

word_t expr(char *e, bool *success) {
  *success = true;
  if (!make_token(e)) {
    *success = false;
    return 0;
  }
  vtop = 0;
  otop = 0;
  for (int i = 0; i < nr_token; i++) {
    if (!*success)
      break;
    int t = tokens[i].type;
    if (t == TK_DEC || t == TK_HEX) {
      // 数字常量,0可自动匹配进制
      val[vtop++] = strtoul(tokens[i].str, NULL, 0);
    } else if (t == TK_REG) {
      word_t number = isa_reg_str2val(tokens[i].str + 1, success);
      if (!*success)
        break;
      val[vtop++] = number;
    } else if (t == '(') {
      op[otop++] = '(';
    } else if (t == ')') {
      while (otop > 0 && op[otop - 1] != '(') {
        if (!pop_and_calc()) {
          *success = false;
          break;
        }
      }
      if (otop == 0 || op[otop - 1] != '(') {
        // bracket can't match
        *success = false;
        break;
      }
      otop--; // pop ')'
    } else {
      // other operator (include Unary and Binary)
      *success = push_op(t);
    }
  }
  // pop last operator
  while (otop > 0) {
    if (op[otop - 1] == '(' || !pop_and_calc()) {
      *success = false;
      break;
    }
  }
  // number of val Error
  if (vtop != 1) {
    *success = false;
  }
  nr_token = 0;
  return (*success) ? val[0] : 0;
}
