/***************************************************************************************
 * Copyright (c) 2014-2024 Zihao Yu, Nanjing University
 *
 * NEMU is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan
 * PSL v2. You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 *
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR ANY
 * KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
 * NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 *
 * See the Mulan PSL v2 for more details.
 ***************************************************************************************/

#include <ftrace.h>
#include <common.h>

static FuncSymbol *funcs = NULL;
static int nfuncs = 0, cap = 0;

static uint32_t r32(const uint8_t *p) {
  uint32_t v;
  memcpy(&v, p, 4);
  return v;
}

static uint16_t r16(const uint8_t *p) {
  uint16_t v;
  memcpy(&v, p, 2);
  return v;
}

static int cmp_addr(const void *a, const void *b) {
  const FuncSymbol *x = a, *y = b;
  return (x->addr > y->addr) - (x->addr < y->addr);
}

static void add_symbol(uint32_t addr, const char *name) {
  if (nfuncs == cap) {
    //倍增变长数组
    cap = cap ? cap * 2 : 64;
    funcs = realloc(funcs, cap * sizeof(*funcs));
    Assert(funcs, "realloc funcs failed");
  }
  funcs[nfuncs].addr = addr & ~1u;  // 去掉 RISC-V 压缩指令标志位
  funcs[nfuncs].name = name;
  nfuncs++;
}

void init_ftrace(const uint8_t *buf, size_t size) {
  if (size < 4 || buf[0] != 0x7f || buf[1] != 'E' || buf[2] != 'L' || buf[3] != 'F')
    Assert(0, "Not a standard ELF file");

  uint32_t e_shoff    = r32(buf + 0x20);
  uint16_t e_shnum    = r16(buf + 0x30);
  uint16_t e_shstrndx = r16(buf + 0x32);

  // 读出 .shstrtab 的内容段，用它匹配各节区名字
  const uint8_t *shstr_hdr = buf + e_shoff + (size_t)e_shstrndx * 0x28;
  uint32_t shstr_off = r32(shstr_hdr + 0x10);
  uint32_t shstr_sz  = r32(shstr_hdr + 0x14);
  const char *shstr  = (const char *)(buf + shstr_off);

  uint32_t sym_off = 0, sym_sz = 0, str_off = 0, str_sz = 0;
  for (int i = 0; i < e_shnum; i++) {
    const uint8_t *sh = buf + e_shoff + (size_t)i * 0x28;
    uint32_t name_off = r32(sh + 0x00);
    if (name_off >= shstr_sz) continue;
    const char *name = shstr + name_off;
    if (strcmp(name, ".symtab") == 0) {
      sym_off = r32(sh + 0x10);
      sym_sz  = r32(sh + 0x14);
    } else if (strcmp(name, ".strtab") == 0) {
      str_off = r32(sh + 0x10);
      str_sz  = r32(sh + 0x14);
    }
  }
  Assert(sym_off && str_off, "No .symtab/.strtab in ELF");

  // 拷贝 .strtab 到自有内存，函数名零拷贝指向其中
  char *strtab = malloc(str_sz);
  Assert(strtab, "malloc strtab failed");
  memcpy(strtab, buf + str_off, str_sz);

  //symtab表项
  int nsyms = sym_sz / 0x10;
  for (int i = 0; i < nsyms; i++) {
    const uint8_t *s = buf + sym_off + (size_t)i * 0x10;
    if ((s[12] & 0x0f) != 2) continue;   // 只要 FUNC
    if (r16(s + 14) == 0) continue;      // 滤掉未定义引用
    uint32_t value = r32(s + 4);
    uint32_t name_off = r32(s + 0);
    if (value == 0 || name_off >= str_sz) continue;
    add_symbol(value, strtab + name_off);
  }
  //地址单调有序后可使用二分查找(感觉写了没啥必要)
  qsort(funcs, nfuncs, sizeof(*funcs), cmp_addr);
  Log("ftrace: %d functions loaded", nfuncs);
}

const char *get_func_name(uint32_t addr) {
  int l = 0, r = nfuncs - 1;
  while (l <= r) {
    int m = (l + r) / 2;
    if (funcs[m].addr == addr) return funcs[m].name;
    if (funcs[m].addr < addr) l = m + 1;
    else r = m - 1;
  }
  return NULL;
}
