#include <stdio.h>
#include <signal.h>
#include "Vminirv.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include "utils.h"     // npc_state / NPC_QUIT

void init_rtl(Vminirv *top, const char *);        // 定义在 isa/rtl.cpp
void init_monitor(int argc, char *argv[]);
void sdb_mainloop();
int is_exit_status_bad();

// Ctrl+C：请求停止（cpu_exec 的循环会检查 npc_state）
void sigint_handler(int) { npc_state.state = NPC_QUIT; }

int main(int argc, char** argv) {
  init_monitor(argc, argv);   // 参数解析 + load_img 到 Memory[] + init_sdb
  
  VerilatedContext* contextp = new VerilatedContext;
  contextp->commandArgs(0, argv);
  Vminirv* minirv = new Vminirv{contextp};
  signal(SIGINT, sigint_handler);
  //顶层会添加一个TOP模块
  init_rtl(minirv, "TOP.minirv.registerFile");


  sdb_mainloop();             // -b 批处理自动 cpu_exec(-1)；否则进入交互式 sdb

  int ret = is_exit_status_bad();
  delete minirv;
  delete contextp;
  return ret;
}
