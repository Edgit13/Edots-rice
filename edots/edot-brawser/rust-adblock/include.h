#pragma once
#include <stdbool.h>
#include <stddef.h>
#ifdef __cplusplus
extern "C" {
#endif
void* edot_adblock_create(void);
void* edot_adblock_create_from_text(const char* text);
bool edot_adblock_check(const void* handle, const char* url, const char* source, const char* request_type);
void edot_adblock_free(void* handle);
#ifdef __cplusplus
}
#endif
