#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t numtostr(char *out, int num){
  size_t i = 0, j = 0, len = 0;
  if(num < 0){
    out[i++] = '-';
    num = -num;
    j = 1;
  }
  while(num){
    out[i++] = (num % 10) + '0';
    num /= 10;
  }
  out[i] = '\0';
  len = i;
  i = (j)? 1: 0;
  j = len-1;
  while(i < j){
    char mid = out[i];
    out[i++] = out[j];
    out[j--] = mid;
  }
  return len;
}

int printf(const char *fmt, ...) {
  panic("Not implemented");
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  panic("Not implemented");
}

int sprintf(char *out, const char *fmt, ...) {
  va_list args;
  va_start(args, fmt);
  size_t i = 0, j = 0;
  while(fmt[i] != '\0'){
    if(fmt[i] == '%'){
      i++;
      if(fmt[i] == 'd'){
        int num = va_arg(args, int);
        size_t len = numtostr(out+j, num);
        j += len;
        i++;
      }
      else if(fmt[i] == 's'){
        char *str = va_arg(args, char*);
        strcat(out+j, str);
        j += strlen(str);
        i++;
      }
    }
    else out[j++] = fmt[i++];
  }
  out[j] = '\0';
  va_end(args);
  return 0;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}


#endif
