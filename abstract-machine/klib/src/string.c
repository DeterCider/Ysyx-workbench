#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  size_t len = 0;
  while(s[len] != '\0') len++;
  return len;
}

char *strcpy(char *dst, const char *src) {
  for(size_t i = 0; ; i++){
    dst[i] = src[i];
    if(src[i] == '\0') break;
  }
  return dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
  size_t vis = 0;
  for(size_t i = 0; i < n; i++){
    if(vis) dst[i] = '\0';
    else{
      dst[i] = src[i];
      if(src[i] == '\0') vis = 1;
    }
  }
  return dst;
}

char *strcat(char *dst, const char *src) {
  size_t i = strlen(dst), j = 0;
  while(src[j] != '\0') dst[i++] = src[j++];
  dst[i] = '\0';
  return dst;
}

int strcmp(const char *s1, const char *s2) {
  for(size_t i = 0; ; i++){
    if(s1[i] != s2[i]) return (s1[i] < s2[i])? -1: 1;
    if(s1[i] == '\0') break;
  }
  return 0;
}

int strncmp(const char *s1, const char *s2, size_t n) {
  for(size_t i = 0; i < n; i++){
    if(s1[i] != s2[i]) return (s1[i] < s2[i])? -1: 1;
    if(s1[i] == '\0') break;
  }
  return 0;
}

void *memset(void *s, int c, size_t n) {
  unsigned char *p = (unsigned char *)s;
  unsigned char val = (unsigned char)c;
  for(size_t i = 0; i < n; i++) p[i] = val;
  return s;
}

void *memmove(void *dst, const void *src, size_t n) {
  unsigned char *d = (unsigned char *)dst;
  const unsigned char *s= (const unsigned char *)src;
  uintptr_t d_addr = (uintptr_t)d;
  uintptr_t s_addr = (uintptr_t)s;
  if(d_addr < s_addr){
    for(size_t i = 0; i < n; i++) d[i] = s[i];
  }
  else if(d_addr > s_addr){
    for(size_t i = n-1; i >= 0; i--) d[i] = s[i];
  }
  return dst;
}

void *memcpy(void *out, const void *in, size_t n) {
  unsigned char *d = (unsigned char *)out;
  const unsigned char *s = (const unsigned char *)in;
  for(size_t i = 0; i < n; i++) d[i] = s[i];
  return out;
}

int memcmp(const void *s1, const void *s2, size_t n) {
  const unsigned char *a = (const unsigned char *)s1;
  const unsigned char *b = (const unsigned char *)s2;
  for(size_t i = 0; i < n; i++){
    if(a[i] != b[i]) return (int)a[i] - (int)b[i];
  }
  return 0;
}

#endif
