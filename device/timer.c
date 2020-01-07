#include "timer.h"
#include "io.h"
#include "print.h"
#include "interrupt.h"
#include "thread.h"
#include "debug.h"

#define IRQO_FREQUENCY		100
#define INPUT_FREQUENCY		1193180
#define COUNTET0_VALUE		(INPUT_FREQUENCY / IRQO_FREQUENCY)
#define CONTRER0_PORT		0x40
#define COUNTER0_NO			0
#define COUNTER_MODE		2
#define READ_WRITE_LATCH	3
#define PIT_CONTROL_PORT	0x43

uint32_t ticks;			// 内核自开中断以来的滴答数

/**
 * 把操作的计数器counter_no,读写锁属性rwl,计数器模式counter_mode写入模式控制寄存器并赋予初始值counter_value
 */
static void frequency_set(	uint8_t counter_port, \
							uint8_t counter_no, \
							uint8_t rwl, \
							uint8_t counter_mode, \
							uint16_t counter_value) {
	// 往控制字寄存器端口0x43中写入控制寄存器
	outb(PIT_CONTROL_PORT, \
	(uint8_t)(counter_no << 16 | rwl << 4 | counter_mode << 1));

	// 先写入counter_value中的低8位
	outb(counter_port, (uint8_t)counter_value);
	// 再写入counter_value中的高8位
	outb(counter_port, (uint8_t)counter_value >> 8);
}

static void intr_time_handler(void) {
	struct task_struct* cur_thread = running_thread();

	ASSERT(cur_thread->stack_magic == 0x19870916);	// 检查栈是否溢出

	cur_thread->elapsed_ticks++;		// 记录此线程占用cpu时间
	ticks++;

	if(cur_thread->ticks == 0) {
		schedule();		// 时间片用完后调度新的进程上cpu
	} else {
		cur_thread->ticks--;
	}
}

void timer_init() {
	put_str("timer_init start\n");
	frequency_set(CONTRER0_PORT, COUNTER0_NO, READ_WRITE_LATCH, COUNTER_MODE, COUNTET0_VALUE);
	register_handler(0x20, intr_time_handler);

	put_str("timer_init done\n");
}