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

#include "debug.h"
#include "sdb.h"
#include <assert.h>
#include <stdint.h>

#define NR_WP 32

typedef struct watchpoint {
  int NO;
  struct watchpoint *next;
  char expr[32];
  uint32_t oldstate;

} WP;

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
  }
  // used head;
  head = NULL;
  // pool head;
  free_ = wp_pool;
}

void new_wp(char exp[], int state) {
  if (free_ == NULL)
    assert(0);
  WP *new_wp = free_;
  // delete from pool;
  free_ = free_->next;
  strncpy(new_wp->expr, exp, sizeof(new_wp->expr));
  // add used wp;
  new_wp->oldstate = state;
  new_wp->next = head;
  head = new_wp;
}

void free_wp(WP *wp) {
  if (wp == head) {
    head = wp->next;
  } else {
    WP *last = head;
    while (last->next != wp)
      last = last->next;
    last->next = wp->next;
  }
  wp->next = free_;
  free_ = wp;
}

int free_wp_byNo(int N) {
  WP *now = head;
  while (now != NULL && now->NO != N)
    now = now->next;
  if (now == NULL)
    return -1;
  else {
    free_wp(now);
    return 0;
  }
}

int check_watchpoint() {
  WP *now = head;
  bool vis = false;
  while (now != NULL) {
    bool success = false;
    uint32_t now_value = expr(now->expr, &success);
    if (!success)
      return -1;
    if (now_value != now->oldstate) {
      Log("The Value of the expression '%s' has changed", now->expr);
      vis = true;
      now->oldstate = now_value;
    }
    now = now->next;
  }
  if (vis)
    return 1;
  else
    return 0;
}

void display_watchpoint() {
  WP *now = head;
  printf("%-4s %-20s %s\n", "Num", "Expression", "Now Value");
  while (now) {
    printf("%-4d %-20s 0x%08x (%u)\n", now->NO, now->expr, now->oldstate,
           now->oldstate);
    now = now->next;
  }
}
/* TODO: Implement the functionality of watchpoint */
