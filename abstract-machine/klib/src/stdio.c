#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t numtostr(char *out, int num){
  size_t i = 0, j = 0, len = 0;
  unsigned int abs  = 0;
  if(num < 0){
    out[i++] = '-';
    abs = -(unsigned int)num;
    j = 1;
  }
  else if(num == 0){
    out[i++] = '0';
    out[i++] = '\0';
    return 1;
  }
  else abs = (unsigned int) num;
  while(abs){
    out[i++] = (abs % 10) + '0';
    abs /= 10;
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

int format_to_buf(char *out, const char *fmt, va_list args){
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
      else if(fmt[i] == 'c'){
        int str = va_arg(args, int);
        out[j++] = str;
        i++;
      }
      else panic("other function not complieted");
    }
    else out[j++] = fmt[i++];
  }
  out[j] = '\0';
  return 0;
}


int printf(const char *fmt, ...) {
  char buf[1000] = {};
  va_list args;
  va_start(args, fmt);
  format_to_buf(buf, fmt, args);
  for(int i = 0; buf[i] != '\0'; i++){
    putch(buf[i]);
    buf[i] = 0;
  }
  va_end(args);
  return 0;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  panic("Not implemented");
}

int sprintf(char *out, const char *fmt, ...) {
  va_list args;
  va_start(args, fmt);
  format_to_buf(out, fmt, args);
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
