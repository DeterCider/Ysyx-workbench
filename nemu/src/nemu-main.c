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

#include "monitor/sdb/sdb.h"
#include <common.h>
#include <stdio.h>
#include <utils.h>

#ifdef CONFIG_EXPER_TEST
char line[65630];
char expr_str[65536];
#endif

void init_monitor(int, char *[]);
void am_init_monitor();
void engine_start();
int is_exit_status_bad();

int main(int argc, char *argv[]) {
  /* Initialize the monitor. */
#ifdef CONFIG_TARGET_AM
  am_init_monitor();
#else
  init_monitor(argc, argv);
#endif

#ifndef CONFIG_EXPER_TEST
  /* Start engine. */
  engine_start();
#endif
#ifdef CONFIG_EXPER_TEST
  FILE *fp = fopen("input", "r");
  if (fp == NULL) {
    _Log(ANSI_FMT("Cannot open input file.\n", ANSI_FG_RED));
  } else {
    int point = 1, accept = 0, error = 0, wa = 0;
    while (fgets(line, sizeof(line), fp)) {
      /* 格式: 期望结果 表达式 */
      unsigned long expected;
      if (sscanf(line, "%lu %[^\n]", &expected, expr_str) == 2) {
        bool success = true;
        uint32_t result = expr(expr_str, &success);
        if (!success) {
          error++;
          _Log(ANSI_FMT("Point %d: Error\n", ANSI_FG_MAGENTA), point);
        } else if (result == expected) {
          accept++;
          _Log(ANSI_FMT("Point %d: Access\n", ANSI_FG_GREEN), point);
        } else {
          wa++;
          _Log(ANSI_FMT("Point %d: Wrong Answer\n", ANSI_FG_RED), point);
        }
      } else {
        error++;
        _Log(ANSI_FMT("Point %d: Error\n", ANSI_FG_MAGENTA), point);
      }
      point++;
    }
    _Log(
        ANSI_FMT("Acccept: %d/%d, Error: %d, Wrong Answer: %d\n", ANSI_FG_CYAN),
        accept, point - 1, error, wa);
    nemu_state.state = NEMU_QUIT;
    fclose(fp);
  }
#endif


  return is_exit_status_bad();
}
