%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR	; 栈指针地址

; 构建GDT及其内部描述符
GDT_BASE: 	dd 0x00000000		; 全局描述符表GDT, 也是第零个段描述符
			dd 0x00000000

; 第一到第三个段描述符, 第零个是不可用
CODE_DESC:	dd 0x0000ffff			; 代码段描述符
			dd DESC_CODE_HIGH4
DATA_SRACK_DESC:	dd 0x0000ffff	; 数据段及栈段描述符
					dd DESC_DATA_HIGH4
VIDEO_DESC:	dd 0x80000007			; 显存段描述符, limit = (0xbffff - 0xb8000) / 4k = 0x7
			dd DESC_VIDEO_HIGH4


GDT_SIZE 	equ $ - GDT_BASE		; 获得GDT大小
GDT_LIMIT	equ GDT_SIZE - 1
times 60 dq 0	; 空一段预留

; 代码段, 数据段及栈段, 显存段的选择子
SELECTOR_CODE 	equ (0x0001 << 3) + TI_GDT + RPL0
; 相当于(CODE_DESC - GDT_BASE) / 8 + TI_GDT _ RPL0
SELECTOR_DATA 	equ (0x0002 << 3) + TI_GDT + RPL0
SELECTOR_VIDEO 	equ (0x0003 << 3) + TI_GDT + RPL0

total_mem_bytes dd 0x0				; 存放内存容量, 以字节为单位, 先放一个值标示一下

; 以下是gdt指针, 前两字节是gdt界限, 后四字节是gdt起始地址
gdt_ptr dw GDT_LIMIT
		dd GDT_BASE

; 人工对齐, total_mem_bytes(4) + gdt_ptr(6) + ards_buf(244) + ards_nr(2) = 256, 按照前面说的total_mem_bytes所在位置是0xb00, 这里又是人工对齐, 可能ards_nr的位置是0xc00, 有可能要自己修改
ards_buf times 244 db 0
ards_nr dw 	0						; 用于记录ARDS结构体数量


; 经过手算, 该地址是0x300, 所以真实地址是0xc00
loader_start:
	xor ebx, ebx					; 第一次调用时, 要初始化
	mov edx, 0x534d4150				; 只赋值一次, 不会改变, 固定签名, 是SMAP的ASCII码
	mov di, ards_buf				; ards结构缓冲区

.e820_mem_get_loop:
	mov eax, 0x0000e820				; 调用int 0x15后eax值会改变, 所以每次循环都要初始化
	mov ecx, 20						; ARDS地址范围描述符结构大小是20字节
	int 0x15
	jc .e820_failed_so_try_e801		; 若cf位为1则有错误, 尝试0xe801子功能

	add di, cx						; 若没有出错使di增加20字节指向新的ARDS结构位置
	inc word [ards_nr]				; 记录ARDS数量, inc指令: 加一指令
	cmp ebx, 0						; 若ebx为0且cf位不为1说明ards全部返回, 当前是最后一个
	jnz .e820_mem_get_loop			; 不是就继续


	;找出(base_add_low + length_low)即内存的容量
	mov cx, [ards_nr]				; 循环条件
	mov ebx, ards_buf				; 缓冲区
	xor edx, edx					; edx为最大内存容量, 清零

.find_max_mem_area:					; 无需判断type是否为1, 最大内存块一定是可被使用的
	mov eax, [ebx]					; base_add_low: 基地址的低32位
	add eax, [ebx + 8]				; length_low: 内存长度的低32位, 以字节为单位
	add ebx, 20						; ARDS结构体大小为20字节, 去下一个, 上面eax是32位(4字节)
	cmp edx, eax					; 判断大小
	jge .next_ards					; 冒泡排序, 找出内存的最大值
	mov edx, eax

.next_ards:
	loop .find_max_mem_area
	jmp .mem_get_ok

.e820_failed_so_try_e801:			; 最大支持4GB内存, ax, cx以kb为单位(为低16MB), bx, dx以64kb为单位(16MB到4GB)
	mov ax, 0xe801
	int 0x15
	jc .e801_failed_so_try88		; 当e801方法失败, 尝试0x88方法

	; 若没有该方法没有失败
	mov cx, 0x400					; 用作乘数 ==1024
	mul cx							; 乘法指令, 
	shl edx, 16
	and eax, 0x0000ffff
	or edx, eax
	add edx, 0x100000				; ax是15MB, 故要加1MB, 历史遗留问题
	mov esi, edx					; 备份edx

	; 将16MB以上的内存转换成byte为单位, bx, dx中是以64kb为单位的内存容量
	xor eax, eax
	mov ax, bx
	mov ecx, 0x10000
	mul ecx

	add esi, eax					; 此方法只能测得4GB以内的内存, 故32为eax即可
	mov edx, esi
	jmp .mem_get_ok

.e801_failed_so_try88:				; 只能获取64MB内存, 再大也不行, ax存入的是以kb为单位的内存容量
	mov ah, 0x88
	int 0x15						; ax是以kb为单位的内存容量
	jc .error_hlt
	and eax, 0x0000ffff

	mov cx, 0x400
	mul cx
	shl edx, 16
	or edx, eax
	add edx, 0x100000				; 0x88子方法只能获取1MB以上的内存, 故要加上1MB, 是转换成了以byte为单位的大小, 加上0x100000是没错的

.mem_get_ok:
	mov [total_mem_bytes], edx



;---------------注释---------------
;loadermsg db '2 loader in real'
;
; 现实文字
;loader_start:
;	mov sp, LOADER_BASE_ADDR
;	mov bp, loadermsg
;	mov cx, 17
;	mov ax, 0x1301
;	mov bx, 0x001f
;	mov dx, 0x1800
;	int 0x10
;--------------end------------------


; -------------进入保护模式-----------
; 打开A20
; 加载gdt
; 将cr0的pe位置1

	; 打开A20
	in al, 0x92
	or al, 0000_0010b
	out 0x92, al

	; 加载gdt
	lgdt [gdt_ptr]

	; cr0第0位置置1
	mov eax, cr0
	or eax, 0x00000001
	mov cr0, eax

	jmp dword SELECTOR_CODE:p_mode_start	; 刷新流水线

.error_hlt:							; 出错则挂起
	hlt

[bits 32]
p_mode_start:
	mov ax, SELECTOR_DATA
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov esp, LOADER_STACK_TOP
	mov ax, SELECTOR_VIDEO
	mov gs, ax


; --------------------------分页机制---------------

	; 创建页目录及页表并初始化内存位图
	call setup_page

	sgdt [gdt_ptr]			; 将描述符地址及偏移量写进内存gdt_ptr, 等下用新地址重新加载

	mov ebx, [gdt_ptr + 2]	; 将gdt描述符中显卡段的基地址加上0xc0000000
	or dword [ebx + 0x18 + 4], 0xc0000000		; 显卡段是第三个, 每个8字节, 故0x18, 段描述符的高4字节是段基址的第31~24位

	; 将gdt的基址加上0xc0000000使其成为内核的高地址
	add dword [gdt_ptr + 2], 0xc0000000
	add esp, 0xc0000000			; 将栈指针同样映射到内核地址


	mov eax, PAGE_DIR_TABLE_POS	; 应该是这的代码有问题, 这个物理地址有问题
	mov cr3, eax

	mov eax, cr0
	or eax, 0x80000000
	; 有问题, physical address not available, 还不知道是为什么, 只知道是物理内存无效, 难不成是分页机制找不到cr0了?
	mov cr0, eax

	lgdt [gdt_ptr]

	mov byte [gs:160], 'V'
	mov byte [gs:162], 'i'
	mov byte [gs:164], 'r'
	mov byte [gs:166], 't'
	mov byte [gs:168], 'u'
	mov byte [gs:170], 'a'
	mov byte [gs:172], 'l'

jmp $

setup_page:

	; 将页目录表的空间清零
	mov ecx, 4096				; 循环次数, 4096个字节是4k大小, 刚好放下页目录表, 位置在0x100000~0x101000之间(不包括0x101000)
	mov esi, 0

.clear_page_dir:
	mov byte [PAGE_DIR_TABLE_POS + esi], 0
	inc esi
	loop .clear_page_dir

	; 开始创建页目录项(PDE)
.create_pde:
	mov eax, PAGE_DIR_TABLE_POS
	add eax, 0x1000			; 此时eax是第一个页表的偏移地址, 在1MB又4kb的地方, 就是页目录表刚结束就立即放一个页表, 是其物理地址, 0x101000
	mov ebx, eax

	or eax, PG_US_U | PG_RW_W | PG_P		; 该页表的属性, 这一串表达式的值是7, eax == 0x101007
	mov [PAGE_DIR_TABLE_POS + 0x0], eax		; 正式在页目录表的第0个项放下第1个页表的偏移地址及属性, 偏移地址要加上页目录表的起始地址才是页表的物理地址, 

	mov [PAGE_DIR_TABLE_POS + 0xc00], eax	; 该偏移地址是0x100c00, 是0xc00 / 4个页表的地址, 就是第768个页表, 实际上就是第4GB内存起始处的一个页表, 也刚好是系统内存(3GB~4GB)的第一个页表, 
	sub eax, 0x1000							; 偏移地址为0? 第1023个页目项那不就是指向页目录表自己吗
	mov [PAGE_DIR_TABLE_POS + 4092], eax
	
	; 开始创建页表项(PTE)
	mov ecx, 256
	mov esi, 0
	mov edx, PG_US_U | PG_RW_W | PG_P

.create_pte:
	mov [ebx + esi * 4], edx

	add edx, 4096
	inc esi
	loop .create_pte

	mov eax, PAGE_DIR_TABLE_POS
	add eax, 0x2000
	or eax, PG_US_U | PG_RW_W | PG_P
	mov ebx, PAGE_DIR_TABLE_POS
	mov ecx, 254
	mov esi, 769

.create_kernel_pde:
	mov [ebx + esi * 4], eax
	inc esi
	add eax, 0x1000
	loop .create_kernel_pde
	
	ret


