#include <am.h>
#include <nemu.h>

#define KEYDOWN_MASK 0x8000
#define CLINT_MMIO 0xa0000000
#define KEYBOARD_BASE 0x60


void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  int k = AM_KEY_NONE;
  k = *(volatile uint32_t *)(CLINT_MMIO + KEYBOARD_BASE);
  kbd->keydown = (k & KEYDOWN_MASK ? true : false);
  kbd->keycode = k & ~KEYDOWN_MASK;
}
