#include <algorithm>
#include <cstdint>
#include <stdio.h>
#include <signal.h>
#include <assert.h>
#include "Vminirv.h"
#include "verilated.h"
#include "verilated_fst_c.h"

#define MemoryOffset 0x80000000



uint32_t Memory[0x800000] = {
   /* 0x80001537, // 0x80000250: lui   x10, 0x80001
    0x123455B7, // 0x80000254: lui   x11, 0x12345
    0x67858593, // 0x80000258: addi  x11, x11, 0x678
    0x00B52023, // 0x8000025C: sw    x11, 0(x10)
    0x00B52223, // 0x80000260: sw    x11, 4(x10)
    0x800002B7, // 0x80000264: lui   x5, 0x80000
    0x28028293, // 0x80000268: addi  x5, x5, 0x280
    0x000280E7, // 0x8000026C: jalr  x1, x5, 0
    0x800002B7, // 0x80000270: lui   x5, 0x80000
    0x2A828293, // 0x80000274: addi  x5, x5, 0x2A8
    0x000280E7, // 0x80000278: jalr  x1, x5, 0
    0x00000067, // 0x8000027C: jalr  x0, x0, 0   (halt)
    0x00054603, // 0x80000280: lbu   x12, 0(x10)
    0x00C50023, // 0x80000284: sb    x12, 0(x10)
    0x00154683, // 0x80000288: lbu   x13, 1(x10)
    0x00D500A3, // 0x8000028C: sb    x13, 1(x10)
    0x00254703, // 0x80000290: lbu   x14, 2(x10)
    0x00E50123, // 0x80000294: sb    x14, 2(x10)
    0x00354783, // 0x80000298: lbu   x15, 3(x10)
    0x00F501A3, // 0x8000029C: sb    x15, 3(x10)
    0x00008067, // 0x800002A0: jalr  x0, x1, 0
    0x00000013, // 0x800002A4: nop              (填充)
    0x00454603, // 0x800002A8: lbu   x12, 4(x10)
    0x00C50223, // 0x800002AC: sb    x12, 4(x10)
    0x00554683, // 0x800002B0: lbu   x13, 5(x10)
    0x00D502A3, // 0x800002B4: sb    x13, 5(x10)
    0x00654703, // 0x800002B8: lbu   x14, 6(x10)
    0x00E50323, // 0x800002BC: sb    x14, 6(x10)
    0x00754783, // 0x800002C0: lbu   x15, 7(x10)
    0x00F503A3, // 0x800002C4: sb    x15, 7(x10)
    0x00008067, // 0x800002C8: jalr  x0, x1, 0i*/
};
static bool finish = false;
void sigint_handler(int) { finish = true; }
static char *img_file = NULL;
extern "C" int pmem_read(int raddr) {
  return Memory[(raddr-MemoryOffset) >> 2];
  // 总是读取地址为`raddr & ~0x3u`的4字节返回
}
extern "C" void pmem_write(int waddr, int wdata, char wmask) {
  // 总是往地址为`waddr & ~0x3u`的4字节按写掩码`wmask`写入`wdata`
  // `wmask`中每比特表示`wdata`中1个字节的掩码,
  // 如`wmask = 0x3`代表只写入最低2个字节, 内存中的其它字节保持不变
  wmask &= 0xf;
  uint32_t mask = 0xffu;
  waddr = (waddr - MemoryOffset) >> 2;
  while(wmask){
    if(wmask & 1){
      uint32_t mid = wdata & mask;
      Memory[waddr] = (Memory[waddr] & ~mask) | mid;
    }
    mask <<= 8;
    wmask >>= 1;
  }
}

static long load_img() {
  if (img_file == NULL) {
    printf("No image is given. Use the default build-in image.");
    return -1; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  if(fp == NULL){
    printf("Can not open '%s'", img_file);
    return -1;
  }
  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  printf("The image is %s, size = %ld\n", img_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread(Memory, size, 1, fp);
  assert(ret == 1);

  fclose(fp);
  return size;
}



uint32_t PC = 0;

int main(int argc, char** argv) {
  signal(SIGINT, sigint_handler); 
  img_file = argv[argc-1];
  printf("Image file: %s\n", img_file);
  argc--;
  VerilatedContext* contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  Vminirv* minirv = new Vminirv{contextp};
  //Verilated::traceEverOn(true);
  //VerilatedFstC* tfp = new VerilatedFstC;
  //top->trace(tfp, 99);  // Trace 99 levels of hierarchy
  //tfp->open("obj_dir/simx.fst");
  load_img();
  while (!contextp->gotFinish() && !finish) { 
    //tfp->dump(contextp->time());
    minirv->clk = 0;
    minirv->eval();
    if(minirv->halt == 1){
      if(minirv->check == 0){
        printf("\033[32mHIT GOOD TRAP\033[0m\n");
      }
      else printf("\033[31mHIT BAD TRAP\033[0m\n");
      break;
    }
    minirv->clk = 1;
    minirv->eval();
    //contextp->timeInc(1);
  }
//  tfp->close();
//  delete tfp;
  delete minirv;
  delete contextp;
  return 0;
}
