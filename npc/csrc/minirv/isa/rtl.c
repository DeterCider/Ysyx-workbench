#include <cstdint>
#include <isa.h>
#include <memory/paddr.h>
#include <utils.h>
#include "Vminirv.h"
#include "Vminirv__Dpi.h"
#include <svdpi.h>

static Vminirv *rtl_top = nullptr;
static uint32_t rtl_halt = 0, rtl_check = 0;
static svScope scope = NULL;

// main.cpp 在创建 Vminirv 后调用，注入电路句柄, 设置DPI函数作用域
void init_rtl(Vminirv *top, const char *regname) { 
  rtl_top = top;
  scope = svGetScopeFromName(regname);
  Assert(scope, "Not Found This Register Module");
  svSetScope(scope);
}



void rtl_step_once() {
  assert(rtl_top != NULL);
  rtl_top->clk = 0; rtl_top->eval();
  rtl_halt  = rtl_top->halt;   // 当前指令是否 ebreak
  rtl_check = rtl_top->check;  // ebreak 时 a0（退出码）
  rtl_top->clk = 1; rtl_top->eval();
}

extern void c_rtl_update_reg(unsigned int *regs);

uint32_t rtl_get_pc()    { return rtl_top->Pcout; }
uint32_t rtl_halted()    { return rtl_halt; }
uint32_t rtl_check_val() { return rtl_check; }


void set_npc_state(int state, vaddr_t pc, int halt_ret) {
  npc_state.state = state;
  npc_state.halt_pc = pc;
  npc_state.halt_ret = halt_ret;
}

void invalid_inst(vaddr_t thispc) {
  set_npc_state(NPC_ABORT, thispc, -1);
}

// 取代 NEMU 的 inst.c：C 侧只做取指镜像与状态同步，译码执行全在 RTL 里
int isa_exec_once(Decode *s) {
  s->pc = cpu.pc;
  s->snpc = s->pc + 4;
  s->inst = paddr_read(s->pc, 4);
  rtl_step_once();                       // RTL 执行一拍
  s->dnpc = rtl_get_pc();                // RTL 给出的下一 PC
  cpu.pc = s->dnpc;
  c_rtl_update_reg(cpu.gpr);
  if (rtl_halted()) {                    // ebreak → 程序结束
    set_npc_state(NPC_END, s->pc, rtl_check_val());
  }
  return 0;
}
