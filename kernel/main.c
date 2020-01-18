#include "print.h"
#include "init.h"
#include "thread.h"
#include "interrupt.h"
#include "console.h"
#include "process.h"
#include "syscall-init.h"
#include "syscall.h"
#include "stdio.h"
#include "memory.h"
#include "dir.h"
#include "fs.h"
#include "assert.h"
#include "shell.h"

#include "ide.h"
#include "stdio-kernel.h"

void init(void);

int main(void) {
	put_str("I am kernel\n");
	init_all();

/*************	 写入应用程序	 *************/
//	uint32_t file_size = 5698; 
//	uint32_t sec_cnt = DIV_ROUND_UP(file_size, 512);
//	struct disk* sda = &channels[0].devices[0];
//	void* prog_buf = sys_malloc(file_size);
//	ide_read(sda, 300, prog_buf, sec_cnt);
//	int32_t fd = sys_open("/cat", O_CREAT|O_RDWR);
//	if (fd != -1) {
//		if(sys_write(fd, prog_buf, file_size) == -1) {
//			printk("file write error!\n");
//			while(1);
//		}
//	}
/*************	 写入应用程序结束	*************/
	cls_screen();
	console_put_str("[rabbit@localhost /]$ ");
	thread_exit(running_thread(), true);
	return 0;
}

/* init进程 */
void init(void) {
	uint32_t ret_pid = fork();
	if(ret_pid) {  // 父进程
		int status;
		int child_pid;
		 /* init在此处不停的回收僵尸进程 */
		 while(1) {
	  child_pid = wait(&status);
	  printf("I`m init, My pid is 1, I recieve a child, It`s pid is %d, status is %d\n", child_pid, status);
		 }
	} else {	  // 子进程
		my_shell();
	}
	panic("init: should not be here");
}








// /* 在线程中运行的函数 */
// void k_thread_a(void* arg) {
// 	char* para = arg;
// 	void* addr1;
// 	void* addr2;
// 	void* addr3;
// 	void* addr4;
// 	void* addr5;
// 	void* addr6;
// 	void* addr7;
// 	console_put_str(" thread_a start\n");
// 	int max = 100;
// 	while (max-- > 0) {
// 		// printf("a: %d\n", max);
// 		int size = 128;
// 		addr1 = sys_malloc(size); 
// 		size *= 2; 
// 		addr2 = sys_malloc(size); 
// 		size *= 2; 
// 		addr3 = sys_malloc(size);
// 		sys_free(addr1);
// 		addr4 = sys_malloc(size);
// 		size *= 2; size *= 2; size *= 2; size *= 2;
// 		size *= 2; size *= 2; size *= 2;
// 		addr5 = sys_malloc(size);
// 		// addr6 = sys_malloc(size);
// 		sys_free(addr5);
// 		size *= 2;
// 		addr7 = sys_malloc(size);
// 		// sys_free(addr6);
// 		sys_free(addr7);
// 		sys_free(addr2);
// 		sys_free(addr3);
// 		sys_free(addr4);
// 	}
// 	console_put_str(" thread_a end\n");
// 	while(1);
// }

// /* 在线程中运行的函数 */
// void k_thread_b(void* arg) {
// 	char* para = arg;
// 	void* addr1;
// 	void* addr2;
// 	void* addr3;
// 	void* addr4;
// 	void* addr5;
// 	void* addr6;
// 	void* addr7;
// 	void* addr8;
// 	void* addr9;
// 	int max = 100;
// 	console_put_str(" thread_b start\n");
// 	while (max-- > 0) {
// 		// printf("b: %d\n", max);
// 		int size = 9;
// 		addr1 = sys_malloc(size);
// 		size *= 2;
// 		addr2 = sys_malloc(size);
// 		size *= 2;
// 		sys_free(addr2);
// 		addr3 = sys_malloc(size);
// 		sys_free(addr1);
// 		addr4 = sys_malloc(size);
// 		addr5 = sys_malloc(size);
// 		addr6 = sys_malloc(size);
// 		sys_free(addr5);
// 		size *= 2;
// 		addr7 = sys_malloc(size);
// 		sys_free(addr6);
// 		sys_free(addr7);
// 		sys_free(addr3);
// 		sys_free(addr4);

// 		size *= 2; size *= 2; size *= 2;
// 		addr1 = sys_malloc(size);
// 		addr2 = sys_malloc(size);
// 		addr3 = sys_malloc(size);
// 		addr4 = sys_malloc(size);
// 		addr5 = sys_malloc(size);
// 		addr6 = sys_malloc(size);
// 		addr7 = sys_malloc(size);
// 		addr8 = sys_malloc(size);
// 		addr9 = sys_malloc(size);
// 		sys_free(addr1);
// 		sys_free(addr2);
// 		sys_free(addr3);
// 		sys_free(addr4);
// 		sys_free(addr5);
// 		sys_free(addr6);
// 		sys_free(addr7);
// 		sys_free(addr8);
// 		sys_free(addr9);
// 	}
// 	console_put_str(" thread_b end\n");
// 	while(1);
// }