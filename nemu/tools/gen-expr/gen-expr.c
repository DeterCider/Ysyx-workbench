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

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define MAX_LENGTH 65530

// this should be enough
static char buf[65536] = {};
const char hex_digits[] = "0123456789abcdef";
static int buf_p = 0;
static char code_buf[65536 + 128] = {}; // a little larger than `buf`
static char *code_format = "#include <stdio.h>\n"
                           "int main() { "
                           "  unsigned result = %s; "
                           "  printf(\"%%u\", result); "
                           "  return 0; "
                           "}";

static int choose(int boarder) { return rand() % boarder; }

static int min(int a, int b) {
  if (a <= b)
    return a;
  else
    return b;
}

static int max(int a, int b) {
  if (a >= b)
    return a;
  else
    return b;
}

static void gen_num(int length) {
  assert(length != 0);
  int now = max(2, choose(length));
  int hex_on = (now >= 4) ? choose(2) : 0;
  if (hex_on) {
    buf[buf_p++] = '0';
    buf[buf_p++] = 'x';
    now -= 2;
    for (int i = 1; i < now; i++)
      buf[buf_p++] = hex_digits[choose(16)];
  } else {
    for (int i = 1; i < now; i++) {
      if (i == 1)
        buf[buf_p++] = choose(9) + 1 + '0';
      else
        buf[buf_p++] = choose(10) + '0';
    }
  }
  buf[buf_p++] = 'u';
}

static void gen_rand_op(int length) {
  assert(length != 0);
  int logic_on = (length >= 4) ? choose(2) : 0;
  if (logic_on) {
    switch (choose(3)) {
    case 0: {
      buf[buf_p++] = ' ';
      buf[buf_p++] = '=';
      buf[buf_p++] = '=';
      buf[buf_p++] = ' ';
      break;
    }
    case 1: {
      buf[buf_p++] = ' ';
      buf[buf_p++] = '!';
      buf[buf_p++] = '=';
      buf[buf_p++] = ' ';
      break;
    }
    case 2: {
      buf[buf_p++] = ' ';
      buf[buf_p++] = '&';
      buf[buf_p++] = '&';
      buf[buf_p++] = ' ';
      break;
    }
    }
  } else {
    switch (choose(4)) {
    case 0: {
      buf[buf_p++] = ' ';
      buf[buf_p++] = '+';
      buf[buf_p++] = ' ';
      break;
    }
    case 1: {
      buf[buf_p++] = ' ';
      buf[buf_p++] = '-';
      buf[buf_p++] = ' ';
      break;
    }
    case 2: {
      buf[buf_p++] = ' ';
      buf[buf_p++] = '*';
      buf[buf_p++] = ' ';
      break;
    }
    case 3: {
      buf[buf_p++] = ' ';
      buf[buf_p++] = '/';
      buf[buf_p++] = ' ';
      break;
    }
    }
  }
}

static void gen_rand_expr(int length) {
  assert(length >= 0);
  int branch = (length >= 6) ? choose(3) : (length >= 3) ? choose(2) : 0;
  switch (branch) {
  case 0: {
    gen_num(min(7, length));
    break;
  }
  case 1: {
    buf[buf_p++] = '(';
    gen_rand_expr(length - 2);
    buf[buf_p++] = ')';
    break;
  }
  default: {
    int start = buf_p;
    gen_rand_expr(length - 5);
    gen_rand_op(length - (buf_p - start) - 1);
    gen_rand_expr(length - (buf_p - start));
    break;
  }
  }
  buf[buf_p] = '\0';
}

int main(int argc, char *argv[]) {
  int seed = time(0);
  srand(seed);
  int loop = 1;
  if (argc > 1) {
    sscanf(argv[1], "%d", &loop);
  }
  while (loop--) {
    buf_p = 0;
    gen_rand_expr(MAX_LENGTH);

    sprintf(code_buf, code_format, buf);

    FILE *fp = fopen("/tmp/.code.c", "w");
    assert(fp != NULL);
    fputs(code_buf, fp);
    fclose(fp);

    int ret = system("gcc /tmp/.code.c -o /tmp/.expr");
    if (ret != 0)
      continue;

    fp = popen("/tmp/.expr", "r");
    assert(fp != NULL);

    int result;
    ret = fscanf(fp, "%d", &result);
    int status = pclose(fp);
    if (status) {
      loop++;
      continue; // 不计入结果，直接下一轮
    }
    printf("%u %s\n", result, buf);
  }
  return 0;
}
