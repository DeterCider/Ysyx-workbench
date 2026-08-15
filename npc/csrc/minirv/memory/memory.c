#include <common.h>
#include <memory/paddr.h>

// 128MB SoC 内存，与 RTL 通过 DPI-C 共享（paddr.c 引用同一数组）
uint32_t Memory[CONFIG_MSIZE / 4] = {0};

// RTL 取指/读数据：保持旧语义——永远按 4 字节对齐读
extern "C" unsigned int pmem_read(unsigned int raddr) {
#ifdef CONFIG_MTRACE
  if(raddr >= CONFIG_MTRACE_START && raddr <= CONFIG_MTRACE_END) printf("Read Memory: 0x%08x\n", raddr);
#endif
  return paddr_read((paddr_t)((uint32_t)raddr & ~3u), 4);
}

// RTL 写数据：按字节掩码逐字节写（wdata 已由 LSU 按 addr[1:0] 预移位）
extern "C" void pmem_write(unsigned int waddr, unsigned int wdata, char wmask) {
#ifdef CONFIG_MTRACE
  if(waddr >= CONFIG_MTRACE_START && waddr <= CONFIG_MTRACE_END) printf("Write Memory: 0x%08x Data: %u\n", waddr, wdata);
#endif 
  for (int i = 0; i < 4; i++) {
    if (wmask & (1 << i)) {
      paddr_write((paddr_t)(((uint32_t)waddr & ~3u) + i), 1, (wdata >> (8 * i)) & 0xff);
    }
  }
}
