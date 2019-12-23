#include "print.h"
#include "init.h"

void main(void) {
	// put_char('k');
	// put_char('e');
	// put_char('r');
	// put_char('n');
	// put_char('e');
	// put_char('l');
	// put_char('\n');
	// put_char('1');
	// put_char('2');
	// put_char('\b');		// 退格键, 删除'2'
	// put_char('3');

	// put_str("I am kernel\n");
	// put_int(0);
	// put_char('\n');
	// put_int(9);
	// put_char('\n');
	// put_int(0x00021a3f);
	// put_char('\n');
	// put_int(0x12345678);
	// put_char('\n');
	// put_int(0x00000000);
	// put_char('\n');

	put_str("I am kernel\n");
	
	init_all();
	asm volatile ("sti");	// 为演示中断处理, 在此临时开中断
	while(1);
}

