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

#include "sdb.h"
#include "memory/paddr.h"
#include "utils.h"
#include <common.h>
#include <cpu/cpu.h>
#include <isa.h>
#include <readline/history.h>
#include <readline/readline.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>

static int is_batch_mode = false;

void init_regex();
void init_wp_pool();

/* We use the `readline' library to provide more flexibility to read from stdin.
 */
static char *rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(nemu) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}

static int cmd_q(char *args) {
  nemu_state.state = NEMU_QUIT;
  return -1;
}

static int cmd_step(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");

  if (arg == NULL) {
    cpu_exec(1);
  } else {
    char *endptr;
    long val = strtol(arg, &endptr, 10);
    if (endptr == arg || *endptr != '\0' || val < 0)
      return -1;
    cpu_exec((uint64_t)val);
  }
  return 0;
}

static int cmd_info(char *args) {
  char *arg = strtok(NULL, " ");
  if (*arg == 'r') {
    isa_reg_display();
  } else if (*arg == 'w') {
    display_watchpoint();
  } else
    return -1;
  return 0;
}

static int cmd_scanmem() {
  char *arg1 = strtok(NULL, " ");
  char *arg2 = strtok(NULL, " ");
  if (arg1 == NULL || arg2 == NULL)
    return -1;
  char *endptr;
  uint32_t n = strtoul(arg1, &endptr, 10);
  if (*arg1 == '-' || endptr == arg1 || *endptr != '\0')
    return -1;
  bool success = false;
  uint32_t addr = expr(arg2, &success);
  for (uint32_t i = 0; i < n; i++) {
    if (addr > 0x87ffffff || !success)
      return -1;
    if (i % 4 == 0) {
      if (i != 0)
        printf("\n");
      printf("0x%08x: ", addr);
    }
    uint32_t val = paddr_read(addr, 4);
    printf("0x%08x ", val);
    addr += 4;
    if ((i == n - 1) && (i % 4 != 0))
      printf("\n");
  }
  return 0;
}

static int cmd_express(char *args) {
  bool success = true;
  uint32_t value = expr(args, &success);
  if (success) {
    printf("Result: %u\n", value);
    return 0;
  } else
    return -1;
}

static int cmd_setwatchpoint(char *args) {
  bool success = false;
  uint32_t value = expr(args, &success);
  if (success) {
    new_wp(args, value);
    return 0;
  } else {
    printf("Invalid expression\n");
    return -1;
  }
}

static int cmd_rmpoint(char *args) {
  char *arg1 = strtok(NULL, " ");
  int No = strtol(arg1, NULL, 10);
  int state = free_wp_byNo(No);
  if (state != 0)
    printf("Invalid Watchpoint Number\n");
  return 0;
}

static int cmd_help(char *args);

static struct {
  const char *name;
  const char *description;
  int (*handler)(char *);
} cmd_table[] = {
    {"help", "Display information about all supported commands", cmd_help},
    {"c", "Continue the execution of the program", cmd_c},
    {"q", "Exit NEMU", cmd_q},
    {"si", "Execute one step of the program", cmd_step},
    {"info", "Display information about GPRS or watchpoint", cmd_info},
    {"x", "Scan Memory", cmd_scanmem},
    {"p", "Calculate expressions", cmd_express},
    {"w", "Set watchpoint", cmd_setwatchpoint},
    {"d", "Remove watchpoint by No", cmd_rmpoint}
    /* TODO: Add more commands */

};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  } else {
    for (i = 0; i < NR_CMD; i++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

void sdb_set_batch_mode() { is_batch_mode = true; }

void sdb_mainloop() {
  if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }

  for (char *str; (str = rl_gets()) != NULL;) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) {
      continue;
    }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }

#ifdef CONFIG_DEVICE
    extern void sdl_clear_event_queue();
    sdl_clear_event_queue();
#endif

    int i;
    for (i = 0; i < NR_CMD; i++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) {
          return;
        }
        break;
      }
    }

    if (i == NR_CMD) {
      printf("Unknown command '%s'\n", cmd);
    }
  }
}

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
}
