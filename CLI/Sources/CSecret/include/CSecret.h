#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/// 1 = libsecret 已加载。macOS 上恒为 0。
int tollcat_secret_available(void);

/// 写入成功返回 1。
int tollcat_secret_store(const char *reference, const char *secret);

/// 没有这条或加载失败返回 NULL。调用方用 tollcat_secret_free 释放。
char *tollcat_secret_lookup(const char *reference);

/// 删除成功或本来没有都返回 1。
int tollcat_secret_clear(const char *reference);

void tollcat_secret_free(char *value);

#ifdef __cplusplus
}
#endif
