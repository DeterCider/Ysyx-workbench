#include <am.h>
#include <nemu.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>

#define SYNC_ADDR (VGACTL_ADDR + 4)
#define VMEM_ADDR 0xa1000000

static int W = 0, H = 0;

void __am_gpu_init() {
  W = io_read(AM_GPU_CONFIG).width;
  H = io_read(AM_GPU_CONFIG).height;
  /*uint32_t *fb = (uint32_t *)(uintptr_t)VMEM_ADDR;
  for (int i = 0; i < w * h; i ++) fb[i] = i;
  outl(SYNC_ADDR, 1);*/
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width =  (*(volatile uint32_t *) VGACTL_ADDR) >> 16,
    .height = (*(volatile uint32_t *) VGACTL_ADDR) & 0xffff,
    .vmemsz = 0
  };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  if (ctl->w > 0 && ctl->h > 0){
    int x = ctl->x, y = ctl->y, w = ctl->w, h = ctl->h;
    uint32_t *fb = (uint32_t *)(uintptr_t) VMEM_ADDR;
    for (int i = 0; i < h; i++)  memcpy(&fb[(y + i) * W + x], ctl->pixels + i * w, w * sizeof(uint32_t));
  }
  if (ctl->sync) {
   outl(SYNC_ADDR, 1);
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
