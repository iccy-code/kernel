#ifndef __KERNEL_MEMORY_H
#define __KERNEL_MEMORY_H

#include "stdio.h"
#include "bitmap.h"

/**
 * 内存池标记, 用于判断用于哪个内存池
 */
enum pool_flags {
	PF_KERNEL = 1,		// 内核内存池
	PF_USER = 2		// 用户内存池
};

#define PG_P_1 1	// 页表项或页目录项存在属性位, 表示P位, 此内存已存在
#define PG_P_0 0	// 页表项或页目录项存在属性位, 表示P位, 此内存不存在
#define PG_RW_R 0	// R/W属性位值, 允许读/执行
#define PG_RW_W 2	// R/W属性位值, 蕴蓄读/写/执行
#define PG_US_S 0	// U/S属性位值, 系统级, 只允许特权级别0,1,2的程序访问
#define PG_US_U 4	// U/S属性位值, 用户级, 所有特权级都可以访问

/**
 * 虚拟地址池, 用于虚拟地址管理
 */
struct virtual_addr {
	struct bitmap vaddr_bitmap;		// 虚拟地址用的的位图结构
	uint32_t vaddr_start;			// 虚拟地址的起始地址
};

extern struct pool kernel_pool, user_pool;
void mem_init(void);
void* get_kernel_pages(uint32_t pg_cnt);
void* malloc_page(enum pool_flags pf, uint32_t pg_cnt);
void malloc_init(void);
uint32_t* pte_ptr(uint32_t vaddr);
uint32_t* pde_ptr(uint32_t vaddr);
#endif