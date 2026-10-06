/* Заглушка C ABI для збірки без Rust (-DEDOT_NO_RUST=ON). Нічого не блокує. */
#include <stdbool.h>
#include <stddef.h>
void* edot_adblock_create(void) { static int dummy; return &dummy; }
void* edot_adblock_create_from_text(const char* text) { (void)text; return edot_adblock_create(); }
bool edot_adblock_check(const void* h, const char* u, const char* s, const char* t) { (void)h; (void)u; (void)s; (void)t; return false; }
void edot_adblock_free(void* h) { (void)h; }
