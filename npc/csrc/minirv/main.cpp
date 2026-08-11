#include <algorithm>
#include <cstdint>
#include <stdio.h>
#include <signal.h>
#include <assert.h>
#include <sys/time.h>
#include "Vminirv.h"
#include "verilated.h"
#include "verilated_fst_c.h"

#define MemoryOffset 0x80000000u
#define CLINT_MMIO 0x10000000u
#define TIME_BASE 0x48u
#define SERIAL_PORT 0x3f8u


long boot_time = 0;
uint32_t Memory[0x800000] = {0};
static bool finish = false;
void sigint_handler(int) { finish = true; }
static char *img_file = NULL;

long long gettimeval(){
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return (long long)tv.tv_sec * 1000000 + tv.tv_usec - boot_time;
}

extern "C" int pmem_read(int raddr) {
  if(raddr == CLINT_MMIO + TIME_BASE){
    long long uptime = gettimeval();
    int lo = uptime;
    return lo;
  }
  else if(raddr == CLINT_MMIO + TIME_BASE + 4){
    long long uptime = gettimeval();
    int hi = uptime >> 32;
    return hi;
  }
  else return Memory[(raddr - MemoryOffset) >> 2];
  // 总是读取地址为`raddr & ~0x3u`的4字节返回
}
extern "C" void pmem_write(int waddr, int wdata, char wmask) {
  // 总是往地址为`waddr & ~0x3u`的4字节按写掩码`wmask`写入`wdata`
  // `wmask`中每比特表示`wdata`中1个字节的掩码,
  // 如`wmask = 0x3`代表只写入最低2个字节, 内存中的其它字节保持不变
  if(waddr == CLINT_MMIO + SERIAL_PORT){
    putchar(wdata);
  }
  else{
    waddr = ((uint32_t) waddr - MemoryOffset) >> 2;
    wmask &= 0xf;
    uint32_t mask = 0xffu;
    while(wmask){
      if(wmask & 1){
        uint32_t mid = wdata & mask;
        Memory[waddr] = (Memory[waddr] & ~mask) | mid;
      }
      mask <<= 8;
      wmask >>= 1;
    }
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
  struct timeval tv;
  gettimeofday(&tv, NULL);
  boot_time = (long long)tv.tv_sec * 1000000 + tv.tv_usec;
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
