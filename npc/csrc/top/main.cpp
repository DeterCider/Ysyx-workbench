#include <stdio.h>
#include <signal.h>
#include "Vtop.h"
#include "verilated.h"
#include "verilated_fst_c.h"

static bool finish = false;
void sigint_handler(int) { finish = true; }

int main(int argc, char** argv) {
  signal(SIGINT, sigint_handler);
  VerilatedContext* contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  Vtop* top = new Vtop{contextp};
  Verilated::traceEverOn(true);
  VerilatedFstC* tfp = new VerilatedFstC;
  top->trace(tfp, 99);  // Trace 99 levels of hierarchy
  tfp->open("obj_dir/simx.fst");
  while (!contextp->gotFinish() && !finish) { 
    int a = rand() & 1;
    int b = rand() & 1;
    top->a = a;
    top->b = b;
    top->eval();
    printf("a = %d, b = %d, f = %d\n", a, b, top->f);
    tfp->dump(contextp->time());
    contextp->timeInc(1);
    assert(top->f == (a ^ b)); 
  }
  tfp->close();
  delete tfp;
  delete top;
  delete contextp;
  return 0;
}
