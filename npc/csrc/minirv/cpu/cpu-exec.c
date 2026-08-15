#include "../monitor/sdb/sdb.h"
#include <isa.h>
#include "common.h"
#include "utils.h"
#include <cpu/cpu.h>
#include <cpu/difftest.h>
#include <locale.h>
#include <stdio.h>
#include <ftrace.h>
/* The assembly code of instructions executed is only output to the screen
 * when the number of instructions executed is less than this value.
 * This is useful when you use the `si' command.
 * You can modify this value as you want.
 */
#define MAX_INST_TO_PRINT 10
#define MAX_IBUF_SIZE 10
#define MAX_FTRACE_STACK_SIZE 500



void device_update();
CPU_state cpu = {};
uint64_t g_nr_guest_inst = 0;
static uint64_t g_timer = 0; // unit: us
static bool g_print_step = false;
static IBuf ibuf[MAX_IBUF_SIZE] = {0};
static int ibf_idx = 0;

#ifdef CONFIG_FTRACE
static int func_cnt = -1;
static FuncStack func_stack[MAX_FTRACE_STACK_SIZE] = {};
// JAL/JALR 且 rd==0：不保存返回地址的跳转（j / jr），可能是尾调用
static bool is_plain_jump(Decode *_this) {
  uint32_t inst = _this->inst;
  if ((inst & 0x3) != 0x3) return false;   // 压缩指令（RVC 未启用，防御性检查）
  uint32_t opcode = inst & 0x7f;
  if (opcode != 0x6f && opcode != 0x67) return false;   // 不是 jal / jalr
  return ((inst >> 7) & 0x1f) == 0;        // rd == 0
}
#endif


static void trace_and_difftest(Decode *_this, vaddr_t dnpc) {
#ifdef CONFIG_ITRACE_COND
  if (ITRACE_COND) {
    log_write("%s\n", _this->logbuf);
  }
#endif
#ifdef CONFIG_WATCHPOINT
  int state = check_watchpoint();

  if (state == 1)
    npc_state.state = NPC_STOP;
  else if (state == -1)
    npc_state.state = NPC_ABORT;
#endif
#ifdef CONFIG_FTRACE
  if(_this->dnpc != _this->snpc){
    if(func_cnt > -1 && _this->dnpc == func_stack[func_cnt].snpc){
      const FuncSymbol *now = func_stack[func_cnt].element;
      printf("0x%08x: ", _this->pc);
      int tab = func_cnt;
      while(tab--) printf(" ");
      printf("ret [%s]\n", now->name);
      func_cnt--;
    }
    else{
      const FuncSymbol *now = get_func_symbol(_this->dnpc);
      if(now != NULL){
        if(func_cnt > -1 && is_plain_jump(_this)){   // 尾调用：跳入新函数但不压返回地址
          func_stack[func_cnt].element = now;        // 替换栈顶帧，snpc 保持原样
          //int tab = func_cnt;
          //printf("0x%08x: ", _this->pc);
          //while(tab--) printf(" ");
          //printf("tail call [%s@0x%08x]\n", now->name, now->addr);
        }
        else{
          func_cnt++;
          Assert(func_cnt < MAX_FTRACE_STACK_SIZE, "Ftrace: funct stack full");
          func_stack[func_cnt].element = now;
          func_stack[func_cnt].snpc = _this->snpc;
          int tab = func_cnt;
          printf("0x%08x: ", _this->pc);
          while(tab--) printf(" ");
          printf("call [%s@0x%08x]\n", now->name, now->addr);
        }
      }
    }
  }
#endif
  if (g_print_step) {
    IFDEF(CONFIG_ITRACE, puts(_this->logbuf));
    /*int number = MAX_IBUF_SIZE, i = ibf_idx;
    while(number--){
      if(ibuf[i].pc[0] != 0) printf("%-12.12s %-25.25s %s\n", ibuf[i].pc, ibuf[i].disas, ibuf[i].inst);
      i = (i + 1) % MAX_IBUF_SIZE;
    }*/
  }
  IFDEF(CONFIG_DIFFTEST, difftest_step(_this->pc, dnpc));
}

static void exec_once(Decode *s, vaddr_t pc) {
  s->pc = pc;
  s->snpc = pc;
  isa_exec_once(s);
  cpu.pc = s->dnpc;
#ifdef CONFIG_ITRACE
  char *p = s->logbuf;
  p += snprintf(p, sizeof(s->logbuf), FMT_WORD ":", s->pc);
  snprintf(ibuf[ibf_idx].pc, sizeof(ibuf[ibf_idx].pc), FMT_WORD ":",s->pc);
  int ilen = s->snpc - s->pc;
  int i;
  uint8_t *inst = (uint8_t *)&(s->inst);
#ifdef CONFIG_ISA_x86
  for (i = 0; i < ilen; i++) {
#else

  char *start_p = p;
  for (i = ilen - 1; i >= 0; i--) {
#endif
    p += snprintf(p, 4, " %02x", inst[i]);
  }
  snprintf(ibuf[ibf_idx].inst, sizeof(ibuf[ibf_idx].inst), "%s", start_p);
  int ilen_max = MUXDEF(CONFIG_ISA_x86, 8, 4);
  int space_len = ilen_max - ilen;
  if (space_len < 0)
    space_len = 0;
  space_len = space_len * 3 + 1;
  memset(p, ' ', space_len);
  p += space_len;

  void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
  disassemble(p, s->logbuf + sizeof(s->logbuf) - p,
              MUXDEF(CONFIG_ISA_x86, s->snpc, s->pc), (uint8_t *)&(s->inst),
              ilen);
  disassemble(ibuf[ibf_idx].disas, sizeof(ibuf[ibf_idx].disas),MUXDEF(CONFIG_ISA_x86, s->snpc, s->pc),
              (uint8_t *)&(s->inst), ilen);
  ibf_idx = (ibf_idx + 1) % MAX_IBUF_SIZE;
#endif
}

static void execute(uint64_t n) {
  Decode s;
  for (; n > 0; n--) {
    exec_once(&s, cpu.pc);
    g_nr_guest_inst++;
    trace_and_difftest(&s, cpu.pc);
    if (npc_state.state != NPC_RUNNING)
      break;
    IFDEF(CONFIG_DEVICE, device_update());
  }
}

static void statistic() {
  IFNDEF(CONFIG_TARGET_AM, setlocale(LC_NUMERIC, ""));
#define NUMBERIC_FMT MUXDEF(CONFIG_TARGET_AM, "%", "%'") PRIu64
  Log("host time spent = " NUMBERIC_FMT " us", g_timer);
  Log("total guest instructions = " NUMBERIC_FMT, g_nr_guest_inst);
  if (g_timer > 0)
    Log("simulation frequency = " NUMBERIC_FMT " inst/s",
        g_nr_guest_inst * 1000000 / g_timer);
  else
    Log("Finish running in less than 1 us and can not calculate the simulation "
        "frequency");
}

void assert_fail_msg() {
  isa_reg_display();
  statistic();
}

/* Simulate how the CPU works. */
void cpu_exec(uint64_t n) {
  g_print_step = (n < MAX_INST_TO_PRINT);
  switch (npc_state.state) {
  case NPC_END:
  case NPC_ABORT:
  case NPC_QUIT:
    printf("Program execution has ended. To restart the program, exit NPC and "
           "run again.\n");
    return;
  default:
    npc_state.state = NPC_RUNNING;
  }

  uint64_t timer_start = get_time();

  execute(n);

  uint64_t timer_end = get_time();
  g_timer += timer_end - timer_start;

  switch (npc_state.state) {
  case NPC_RUNNING:
    npc_state.state = NPC_STOP;
    break;

  case NPC_END:
  case NPC_ABORT:
    Log("npc: %s at pc = " FMT_WORD,
        (npc_state.state == NPC_ABORT
             ? ANSI_FMT("ABORT", ANSI_FG_RED)
             : (npc_state.halt_ret == 0
                    ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN)
                    : ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED))),
        npc_state.halt_pc);
    // fall through
  case NPC_QUIT:
    statistic();
  }
}
