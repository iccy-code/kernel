#include "interrrupt.h"
#include "stdint.h"
#include "global.h"

#define IDT_DESC_CNT 0x21		// 目前支持的中断数

struct gate_desc {
	uint16_t func_offset_low_word;
	uint16_t selector;
	uint8_t dcount;				// 此项为双字计数字段, 是门描述符的第4字节, 为固定值, 不用考虑

	uint8_t attribute;
	uint16_t func_offset_high_word;
};

static void make_idt_desc(struct gate_desc* p_gdesc, uint8_t attr, intr_handler function);
static struct gate_desc idt(IDT_DESC_CNT);		// idt是中断描述符, 本质就是中断门描述符数组

extern intr_handler intr_entry_table(IDT_DESC_CNT); 	// 声明引用定义在kernel.asm中的中断处理函数的入口数组


/* 创建中断门描述符 */
static void make_idt_desc(struct gate_desc* p_gdesc, uint8_t attr, intr_handler function) {
	p_gdesc->func_offset_low_word = (uint32_t) function & 0x0000ffff;
	p_gdesc->selector = SELRCTOR_K_CODE;
	p_gdesc->dcount = 0;
	p_gdesc->attribute = attr;
	p_gdesc->func_offset_high_word = ((uint32_t) function & 0xffff0000) >> 16;
}

static void idt_desc_init(void) {
	for(int i = 0; i < IDT_DESC_CNT; i++) {
		make_idt_desc(&idt[i], IDT_DESC_ATTR_DPLO, intr_entry_table[i]);
	}
	put_str("   idt_desc_init done\n");
}

void idt_init() {
	put_str("idt_init start\n");
	idt_desc_init();
	pic_init();

	uint64_t idt_operand = ((sizeof(idt) - 1) | ((uint64_t) ((uint32_t)idt << 16)));
	asm volatile("lidt %0" : : "m" (idt_operand));
	put_str("idt_init done\n");
}