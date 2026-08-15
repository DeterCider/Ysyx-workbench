#include <common.h>
#include <isa.h>
#include <memory/paddr.h>
#include <utils.h>
#include <stdio.h>

// SoC 内存（定义在 memory/memory.c，与 RTL 通过 DPI-C 共享）
extern uint32_t Memory[CONFIG_MSIZE / 4];

uint8_t* guest_to_host(paddr_t paddr) {
  return (uint8_t *)Memory + paddr - CONFIG_MBASE;
}

paddr_t host_to_guest(uint8_t *haddr) {
  return (paddr_t)(haddr - (uint8_t *)Memory) + CONFIG_MBASE;
}

void init_mem() {
  Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
}

static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = 0;
  uint8_t *p = guest_to_host(addr);
  for (int i = 0; i < len; i++) ret |= (word_t)p[i] << (8 * i);
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
 uint8_t *p = guest_to_host(addr);
  for (int i = 0; i < len; i++) p[i] = (data >> (8 * i)) & 0xff;
}

// ---- SoC 外设 MMIO（与 AM 的 riscv32-npc 平台约定一致）----
#define CLINT_MMIO   0x10000000u
#define TIME_BASE    0x48u
#define SERIAL_PORT  0x3f8u

word_t paddr_read(paddr_t addr, int len) {
  if (likely(in_pmem(addr))) return pmem_read(addr, len);
  if (addr == CLINT_MMIO + TIME_BASE)     return (word_t)(uint32_t)get_time();
  if (addr == CLINT_MMIO + TIME_BASE + 4) return (word_t)(uint32_t)(get_time() >> 32);
  panic("address = " FMT_PADDR " is out of bound at pc = " FMT_WORD, addr, cpu.pc);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
  if (likely(in_pmem(addr))) { pmem_write(addr, len, data); return; }
  if (addr == CLINT_MMIO + SERIAL_PORT) { putc(data & 0xff, stderr); return; }
  panic("address = " FMT_PADDR " is out of bound at pc = " FMT_WORD, addr, cpu.pc);
}
