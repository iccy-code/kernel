#include "string.h"
#include "global.h"
#include "debug.h"

/**
 * 将dst_起始的Size个字节置为value, 可用于内存区域的数据初始化
 */
void memset(void* dst_, uint8_t value, uint32_t size) {
	ASSERT(dst_ != NULL);
	uint8_t* dst = (uint8_t)dst_;
	while(size-- > 0) {
		*dst++ = value;
	}
}

/**
 * 将src_起始的size个字节复制到dst_, 用于内存数据拷贝
 */
void memcpy(void* dst_, const void* src_, uint32_t size) {
	ASSERT(dst_ != NULL && src_ != NULL);
	uint8_t* dst = dst_;
	const uint8_t* src = src_;
	while(size-- > 0) {
		*dst++ = *src++;
	}
}

/**
 * 连续比较以地址a_和地址b_开头的size个字节, 若相等则返回0, 若a_大于b_, 返回+1, 否则返回-1, 用于内存数据比较
 */
int memcmp(const void* a_, const void* b_, uint32_t size) {
	const char* a = a_;
	const char* b = b_;
	ASSERT(a != NULL && b != NULL);
	while(size-- > 0) {
		if(*a != *b) {
			return *a > *b ? 1 : -1;
		}
		a++;
		b++;
	}
	return 0;
}

/**
 * 将字符串从src_复制到dst_
 */
char* strcpy(char* dst_, const char* src_) {
	ASSERT(dst_ != NULL && src_ != NULL);
	char* r = dst_;		// 返回目的字符串的起始地址
	while((*dst_++ = *src_++));		// 有点意思
	return r;
}

/**
 * 返回字符串长度, 有意思, p和*p的关系
 */
uint32_t strlen(const char* str) {
	ASSERT(str != NULL);
	const char* p = str;
	while(*p++);
	return (p - str - 1);
}

