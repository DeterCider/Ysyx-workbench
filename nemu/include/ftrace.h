#ifndef __FTRACE_H__
#define __FTRACE_H__

#include <stdint.h>
#include <stddef.h>

typedef struct {
  uint32_t addr;
  const char *name;   // 指向 .strtab 中的字符串（零拷贝）
} FuncSymbol;

// 解析 ELF 内容，构建函数符号表（内部存储，buf 可立即释放）
void init_ftrace(const uint8_t *buf, size_t size);

// 按函数入口地址二分查找，未找到返回 NULL
const char *get_func_name(uint32_t addr);

#endif
