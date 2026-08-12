#ifndef __FTRACE_H__
#define __FTRACE_H__

#include <stdint.h>
#include <stddef.h>

typedef struct {
  uint32_t addr;      // 函数入口（已去掉 RISC-V 压缩指令标志位）
  const char *name;   // 指向 .strtab 中的字符串（零拷贝）
} FuncSymbol;

typedef struct {
  const FuncSymbol *element;
  uint32_t snpc;
} FuncStack;

// 解析 ELF 内容，构建函数符号表（内部存储，buf 可立即释放）
void init_ftrace(const uint8_t *buf, size_t size);

// 返回入口地址为 addr 的函数符号，未找到返回 NULL
const FuncSymbol *get_func_symbol(uint32_t addr);

#endif
