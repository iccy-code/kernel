#include "bitmap.h"
#include "stdint.h"
#include "string.h"
#include "print.h"
#include "interrupt.h"
#include "debug.h"

/**
 * 将位图初始化
 */
void bitmap_init(struct bitmap* btmp) {
	memset(btmp->bits, 0, btmp->btmp_bytes_len);
}

/**
 * 判断bit_idx位是否为1, 若为1则返回true, 否则返回false
 */
bool bitmap_scan_test(struct bitmap* btmp, uint32_t bit_idx) {
	uint32_t byte_idx = bit_idx / 8;	// 向下取整用于索引数组下标
	uint32_t bit_odd = bit_idx % 8;		// 取余用于索引数组内的位
	return (btmp->bits[byte_idx] & (BITMAP_MASK << bit_odd));
}

/**
 * 在位图中连续申请cnt个位, 成功赶回其起始位下标, 失败返回-1
 */
int bitmap_scan(struct bitmap* btmp, uint32_t cnt) {
	uint32_t idx_byte = 0;		// 记录空闲位所在字节
	while((0xff == btmp->bits[idx_byte]) && (idx_byte < btmp->btmp_bytes_len)) {
		idx_byte++;		// 1表示该位已分配, 若为0xff, 表示该字节内已经没有空位了, 向下移动继续寻找
	}

	ASSERT(idx_byte < btmp->btmp_bytes_len);
	if(idx_byte == btmp->btmp_bytes_len) {		// 若该内存池中找不到任何可用空间
		return -1;
	}

	/**
	 * 若在位图数组范围内的某字节内找到了空闲位, 在该字节内逐位比对, 返回空闲位的索引
	 */
	int idx_bit = 0;
	while((uint8_t)(BITMAP_MASK << idx_bit) & btmp->bits[idx_byte]) {
		idx_bit++;
	}

	int bit_idx_start = idx_byte * 8 + idx_bit;		// 空闲位的下标
	if(1 == cnt) {
		return bit_idx_start;
	}

	uint32_t bit_left = (btmp->btmp_bytes_len * 8 - bit_idx_start);		// 记录还有多少位可用判断
	uint32_t next_bit = bit_idx_start + 1;
	uint32_t count = 1;		// 记录找到的空闲位个数

	bit_idx_start = -1;		// 现将其置为-1, 若找不到连续的位就直接返回
	while(bit_left-- > 0) {
		if(!(bitmap_scan_test(btmp, next_bit))) {
			count++;
		} else {
			count = 0;
		}
		if(count == cnt) {		// 若是找到连续的cnt个空闲位
			bit_idx_start = next_bit + 1;
			break;
		}
		next_bit++;
	}

	return bit_idx_start;
}

/**
 * 将位图中的bit_idx位设置位value
 */
void bitmap_set(struct bitmap* btmp, uint32_t bit_idx, int8_t value) {
	ASSERT((0 == value) || (1 == value));
	uint32_t byte_idx = bit_idx / 8;
	uint32_t bit_odd = bit_idx % 8;

	if(value) {
		btmp->bits[byte_idx] |= (BITMAP_MASK << bit_odd);
	} else {
		btmp->bits[byte_idx] &= ~(BITMAP_MASK << bit_odd);
	}
}