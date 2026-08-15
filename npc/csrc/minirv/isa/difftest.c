#include <isa.h>
#include <cpu/difftest.h>

#define NR_GPR MUXDEF(CONFIG_RVE, 16, 32)

bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
  for(int i = 0; i < NR_GPR; i++){
    if(ref_r->pc != cpu.pc || ref_r->gpr[i] != cpu.gpr[i]){
      Error("Inconsistent with the reference program behavior");
      Error("DUT:%s:0x%08x  REF:%s:0x%08x", isa_reg_val2str(i), cpu.gpr[i], isa_reg_val2str(i), ref_r->gpr[i]);
      return false;
    }
  }
  return true;
}

void isa_difftest_attach() {
}
