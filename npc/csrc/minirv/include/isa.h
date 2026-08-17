#ifndef __ISA_H__
#define __ISA_H__

#include <common.h>
#include <memory/paddr.h>
#include <stdint.h>

// ---- CPU 状态（riscv32 固定）----
typedef struct {
  word_t gpr[32];
  vaddr_t pc;
} CPU_state;


//---译码信息---------
typedef struct Decode {
  vaddr_t pc;
  vaddr_t snpc; // static next pc
  vaddr_t dnpc; // dynamic next pc
  uint32_t inst;
  IFDEF(CONFIG_ITRACE, char logbuf[128]);
} Decode;

// ---- itrace 环形缓冲条目（cpu-exec.c 使用）----
typedef struct iringbuf {
  char pc[25];
  char inst[25];
  char disas[25];
} IBuf;

extern CPU_state cpu;

// monitor
void init_isa();

// reg
void isa_reg_display();
word_t isa_reg_str2val(const char *name, bool *success);
const char *isa_reg_val2str(int i);


// exec（由 RTL 完成，见 isa/isa.c）
struct Decode;
int isa_exec_once(struct Decode *s);

#define reg_name(i) isa_reg_str2val
bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc);
void isa_difftest_attach();

#endif
