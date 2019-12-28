#include "interrupt.h"
#include "stdint.h"
#include "global.h"
#include "print.h"
#include "io.h"

#define IDT_DESC_CNT 0x21		// 目前支持的中断数

#define PIC_M_CTRL 0x20			// 主片的控制端口是0x20
#define PIC_M_DATA 0x21			// 主片的数据端口是0x21
#define PIC_S_CTRL 0xa0			// 从片的控制端口是0xa0
#define PIC_S_DATA 0xa1			// 从片的数据端口是0xa1

struct gate_desc {
	uint16_t func_offset_low_word;
	uint16_t selector;
	uint8_t dcount;				// 此项为双字计数字段, 是门描述符的第4字节, 为固定值, 不用考虑

	uint8_t attribute;
	uint16_t func_offset_high_word;
};

static void make_idt_desc(struct gate_desc* p_gdesc, uint8_t attr, intr_handler function);

static struct gate_desc idt[IDT_DESC_CNT];		// idt是中断描述符, 本质就是中断门描述符数组
extern intr_handler intr_entry_table[IDT_DESC_CNT]; 	// 声明引用定义在kernel.asm中的中断处理函数的入口数组

char* intr_name[IDT_DESC_CNT];			// 用于保存异常的名字
intr_handler idt_table[IDT_DESC_CNT];	// 定义中断处理程序数组, 可kernel.asm中定义的intrXXentry, 只是中断处理程序的入口, 最终调用的是ide_table中的处理程序

/* 创建中断门描述符 */
static void make_idt_desc(struct gate_desc* p_gdesc, uint8_t attr, intr_handler function) {
	p_gdesc->func_offset_low_word = (uint32_t)function & 0x0000FFFF;
	p_gdesc->selector = SELECTOR_K_CODE;
	p_gdesc->dcount = 0;
	p_gdesc->attribute = attr;
	p_gdesc->func_offset_high_word = ((uint32_t)function & 0xffff0000) >> 16;
}

static void idt_desc_init(void) {
	for(int i = 0; i < IDT_DESC_CNT; i++) {
		make_idt_desc(&idt[i], IDT_DESC_ATTR_DPL0, intr_entry_table[i]);
	}
	put_str("idt_desc_init done\n");
}



/**
 * 初始化可编程中断控制器8259A
 */
static void pic_init(void) {
	/* 初始化主片 */
	outb(PIC_M_CTRL, 0x11);		// ICW1: 边沿触发, 级联8259, 需要ICW4
	outb(PIC_M_DATA, 0x20);		// ICW2: 起始中断向量号为0x20

	outb(PIC_M_DATA, 0x04);		// ICW3: IR2接从片
	outb(PIC_M_DATA, 0x01);		// ICW4: 8086模式, 正常EOI

	/*初始化从片 */
	outb(PIC_S_CTRL, 0x11);		// ICW1: 边沿触发, 级联8259, 需要ICW4
	outb(PIC_S_DATA, 0x28);		// ICW2: 起始中断向量号为0x28, 也就是IR[8-15]为0x28~0x28

	outb(PIC_S_DATA, 0x02);		// ICW3: 设置从片连接到主片的IR2引脚
	outb(PIC_S_DATA, 0x01);		// ICW4: 8086模式, 正常EOI

	/* 打开主片上的IR0, 也就是目前只接受时钟产生的中断 */
	outb(PIC_M_DATA, 0xfe);
	outb(PIC_S_DATA, 0xff);

	put_str("pic_init done\n");
}

static void general_intr_handler(uint8_t vec_nr) {
	if(vec_nr == 0x27 || vec_nr == 0x2f) {
		return;
	}

	put_str("int vector : 0x");
	put_int(vec_nr);
	put_char('\n');
}

static void exception_init(void) {
	for(int i = 0; i < IDT_DESC_CNT; i++) {
		idt_table[i] = general_intr_handler;
		intr_name[i] = "unknown";
	}

	intr_name[0] = "#DF Divide Error";
	intr_name[1] = "#DB Debug Exception";
	intr_name[2] = "NMI Interrupt";
	intr_name[3] = "#BP Breakpoint Exception";
	intr_name[4] = "#OF Overflow Exception";
	intr_name[5] = "#BR BOUND Range Exceeded Exception";
	intr_name[6] = "#UD Invalid Opcode Exception";
	intr_name[7] = "#NM Device Not Available Exception";
	intr_name[8] = "#DF Double Fault Exception";
	intr_name[9] = "Coprocessor Segment Overrun";
	intr_name[10] = "#TS Invalid TSS Excrption";
	intr_name[11] = "#NP Segment Not Present";
	intr_name[12] = "#SS Stack Fault Exception";
	intr_name[13] = "#GP General Protection Exception";
	intr_name[14] = "#PF Page-Fault Exception";
	// intr_name[15] = "";	保留项
	intr_name[16] = "#MF x87 FPU Floating-Point Error";
	intr_name[17] = "#AC Alignment Check Exception";
	intr_name[18] = "#MC Machine-Check Exception";
	intr_name[19] = "#XF SIMD Floating-Point Exception";
}



/**
 * 完成有关中断的所有初始化工作
 */
void idt_init() {
	put_str("idt_init start\n");
	idt_desc_init();	// 初始化中断描述符
	exception_init();
	pic_init();			// 初始化8259A

	uint64_t idt_operand = ((sizeof(idt) - 1) | ((uint64_t)(uint32_t)idt << 16));
	asm volatile ("lidt %0" : : "m" (idt_operand));
	put_str("idt_init done\n");
}