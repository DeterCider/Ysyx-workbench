#include "VwaterledNoNvBoard.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include <signal.h>
#include <stdio.h>

static bool finish = false;
void sigint_handler(int) { finish = true; }

int main(int argc, char **argv) {
  signal(SIGINT, sigint_handler);
  VerilatedContext *contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  VwaterledNoNvBoard *top = new VwaterledNoNvBoard{contextp};
  Verilated::traceEverOn(true);
  VerilatedFstC *tfp = new VerilatedFstC;
  top->trace(tfp, 99); // Trace 99 levels of hierarchy
  tfp->open("obj_dir/simx.fst");
  int clk = 1;
  while (!contextp->gotFinish() && !finish) {
    clk = ~clk;
    top->clk = clk;
    top->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(1);
  }
  tfp->close();
  delete tfp;
  delete top;
  delete contextp;
  return 0;
}
