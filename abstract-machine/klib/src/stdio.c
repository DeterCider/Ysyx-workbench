#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

static int num_to_str(char *buf, uint64_t val, unsigned base, int upper) {
  static const char lower[] = "0123456789abcdef";
  static const char UPPER[] = "0123456789ABCDEF";
  const char *tbl = upper ? UPPER : lower;
  char tmp[24];
  int i = 23;
  tmp[i--] = '\0';
  do {
    tmp[i--] = tbl[val % base];
    val /= base;
  } while (val);
  int len = 23 - i - 1;
  memcpy(buf, tmp + i + 1, len);
  return len;
}

static char parse_spec(const char **fmt, int *flags, int *width, int *prec, int *len) {
  const char *f = *fmt;
  *flags = 0; *width = 0; *prec = -1; *len = 0;

  while (*f == '-' || *f == '0') {
    if (*f == '-') *flags |= 1;
    else           *flags |= 2;
    f++;
  }
  if (*f >= '0' && *f <= '9') {
    const char *s = f;
    while (*f >= '0' && *f <= '9') f++;
    *width = atoi(s);
  }
  if (*f == '.') {
    f++;
    const char *s = f;
    while (*f >= '0' && *f <= '9') f++;
    *prec = (s == f) ? 0 : atoi(s);
  }
  if (*f == 'l') {
    *len = 1; f++;
    if (*f == 'l') { *len = 2; f++; }
  }
  char spec = *f;
  if (spec) f++;
  *fmt = f;
  return spec;
}

#define MAX_FIELD 128

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  char *p = out;
  uintptr_t lim = (uintptr_t)out;
  if (n) {
    lim += n - 1;
    if (lim < (uintptr_t)out) lim = (uintptr_t)-1;  // 溢出回绕（vsprintf 的 SIZE_MAX）→ 钳到地址空间顶
  }
  char *limit = (char *)lim;
  int total = 0;

#define OUTC(ch) do { \
    total++; \
    if (p < limit) *p++ = (ch); \
  } while (0)

#define OUT(s, len) do { \
    total += (len); \
    size_t avail = (p < limit) ? (size_t)(limit - p) : 0; \
    size_t w = (size_t)(len) < avail ? (size_t)(len) : avail; \
    memcpy(p, (s), w); \
    p += w; \
  } while (0)

#define ArgsGet(left, right) (left) va_arg(ap, right)

  while (*fmt) {
    if (*fmt != '%') { OUTC(*fmt); fmt++; continue; }

    fmt++;
    if (*fmt == '\0') break;

    int flags, width, prec, len;
    char spec = parse_spec(&fmt, &flags, &width, &prec, &len);
    if (!spec) break;

    if (width > MAX_FIELD) width = MAX_FIELD;
    if (prec  > MAX_FIELD) prec  = MAX_FIELD;

    int left = flags & 1, zero = flags & 2;

    if (spec == 'd' || spec == 'u' || spec == 'x' || spec == 'X') {
      uint64_t uval;
      char sign = 0;
      if (spec == 'd') {
        int64_t sval =
          len == 0 ? ArgsGet(int64_t, int)
          : len == 1 ? ArgsGet(int64_t, long)
          : ArgsGet(int64_t, long long);
        if (sval < 0) {
          sign = '-';
          uval = -(uint64_t)sval;
        } else {
          uval = (uint64_t)sval;
        }
      } else {
        uval =
          len == 0 ? ArgsGet(uint64_t, unsigned)
          : len == 1 ? ArgsGet(uint64_t, unsigned long)
          : ArgsGet(uint64_t, unsigned long long);
      }

      unsigned base = (spec == 'x' || spec == 'X') ? 16 : 10;
      char digits[24];
      int dlen = num_to_str(digits, uval, base, spec == 'X');

      int zeros = 0;
      int eff_prec = (prec < 0) ? 1 : prec;
      if (eff_prec == 0 && uval == 0) {
        dlen = 0;
      } else if (eff_prec > dlen) {
        zeros = eff_prec - dlen;
      }

      if (!left && zero && prec < 0) {
        int core = (sign ? 1 : 0) + dlen;
        if (width > core) zeros = width - core;
      }
      char tmp[MAX_FIELD + 2];
      int t = 0;
      if (sign) tmp[t++] = sign;
      while (zeros--) tmp[t++] = '0';
      memcpy(tmp + t, digits, dlen);
      t += dlen;

      while (!left && width > t) { OUTC(' '); width--; }
      OUT(tmp, t);
      while (left && width > t) { OUTC(' '); width--; }

    } else if (spec == 's') {
      char *s = ArgsGet(char *, char *);
      if (!s) s = "(null)";
      int slen = strlen(s);
      if (prec >= 0 && slen > prec) slen = prec;

      while (!left && width > slen) { OUTC(' '); width--; }
      OUT(s, slen);
      while (left && width > slen) { OUTC(' '); width--; }

    } else if (spec == 'c') {
      int ch = ArgsGet(int, int);
      while (!left && width > 1) { OUTC(' '); width--; }
      OUTC(ch);
      while (left && width > 1) { OUTC(' '); width--; }

    } else if (spec == '%') {
      while (!left && width > 1) { OUTC(' '); width--; }
      OUTC('%');
      while (left && width > 1) { OUTC(' '); width--; }

    } else {
      OUTC('%');
      OUTC(spec);
    }
  }

  if (n) *p = '\0';
  return total;

#undef ArgsGet
#undef OUTC
#undef OUT
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  return vsnprintf(out, SIZE_MAX, fmt, ap);
}

int sprintf(char *out, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int ret = vsprintf(out, fmt, ap);
  va_end(ap);
  return ret;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int ret = vsnprintf(out, n, fmt, ap);
  va_end(ap);
  return ret;
}

int printf(const char *fmt, ...) {
  char buf[512];
  va_list ap;
  va_start(ap, fmt);
  int ret = vsnprintf(buf, sizeof(buf), fmt, ap);
  va_end(ap);
  for (int i = 0; i < ret; i++) putch(buf[i]);
  return ret;
}

#endif
