#include <am.h>
#include <nemu.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>

#define SYNC_ADDR (VGACTL_ADDR + 4)

static uint32_t W = 0, H = 0;

void __am_gpu_init() {
  uint32_t value = inl(VGACTL_ADDR);
  W = value >> 16;
  H = value & 0xffff;
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = W, .height = H,
    .vmemsz = 0
  };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  if (ctl->w > 0 && ctl->h > 0){
    uint32_t x = ctl->x, y = ctl->y, w = ctl->w, h = ctl->h;
    for (uint32_t i = 0; i < h; i++){
      uint32_t *out = (uint32_t *)FB_ADDR + ((y+i) * W + x);
      uint32_t *in = (uint32_t *)ctl->pixels + (i*w);
      memcpy(out, in, w * sizeof(uint32_t));
    }
  }
  if (ctl->sync) {
   outl(SYNC_ADDR, 1);
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
