#include "verilated.h"
#include "verilated_fst_c.h"
#include <Vkeyboard.h>
#include <nvboard.h>
#include <signal.h>

static TOP_NAME top;

void nvboard_bind_all_pins(TOP_NAME *top);
bool finish = true;
static void single_cycle() {
  top.clk = 0;
  top.eval();
  // tfp->dump(contextp->time());
  // contextp->timeInc(1);
  top.clk = 1;
  top.eval();
  // tfp->dump(contextp->time());
  // contextp->timeInc(1);
}
void sigint_handler(int) { finish = false; }
int main(int argc, char **argv) {
  signal(SIGINT, sigint_handler);
  // Verilated::traceEverOn(true);
  nvboard_bind_all_pins(&top);
  nvboard_init();
  // VerilatedContext *contextp = new VerilatedContext;
  // contextp->commandArgs(argc, argv);
  // VerilatedFstC *tfp = new VerilatedFstC;
  // top.trace(tfp, 99); // Trace 99 levels of hierarchy
  // tfp->open("build/simx.fst");
  top.reset = 1;
  top.eval();
  top.reset = 0;
  top.eval();
  while (finish) {
    nvboard_update();
    single_cycle();
  }
  // tfp->close();
  // delete tfp;
  // delete contextp;
  return 0;
}
