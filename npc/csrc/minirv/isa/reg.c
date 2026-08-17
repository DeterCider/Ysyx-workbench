#include <isa.h>
#include <utils.h>
#include <stdio.h>

static const char *regs[32] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

void isa_reg_display() {
  for (int i = 0; i < 32; i++) {
    printf("%s: 0x%08x      ", regs[i], cpu.gpr[i]);
    if ((i + 1) % 4 == 0) printf("\n");
  }
}

word_t isa_reg_str2val(const char *s, bool *success) {
  for (int i = 0; i < 32; i++) {
    if (strcmp(regs[i], s) == 0) { *success = true; return cpu.gpr[i]; }
  }
  *success = false;
  return 0;
}

const char* isa_reg_val2str(int i){
  assert(0 <= i && i <= 31);
  return regs[i];
}


void init_isa() {
  cpu.pc = RESET_VECTOR;
  cpu.gpr[0] = 0;
}
