[bits 16]

%include "boot.inc"
SECTION MBR vstart=0x7c00

	; 寄存器初始化
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov fs, ax
	mov sp, 0x7c00
	mov ax, 0xb800
	mov gs, ax

	; 清屏
	mov ax, 0x600
	mov bx, 0x700
	mov cx, 0
	mov dx, 0x184f

	int 0x10

	; 输出字符串
	mov byte [gs:0x00], '1'
	mov byte [gs:0x01], 0xa4
	mov byte [gs:0x02], ' '
	mov byte [gs:0x03], 0xa4
	mov byte [gs:0x04], 'M'
	mov byte [gs:0x05], 0xa4
	mov byte [gs:0x06], 'B'
	mov byte [gs:0x07], 0xa4
	mov byte [gs:0x08], 'R'
	mov byte [gs:0x09], 0xa4

	; 读取loader块
	mov eax, LOADER_START_SECTOR	; 起始扇区lba地址
	mov bx, LOADER_BASE_ADDR		; 写入的地址
	mov cx, 4						; 待读取的扇区数 ; 防止loader过大, 就直接增大到读取4个扇区(2,3,4,5)
	call rd_disk_m_16				; 调用读取函数

	jmp LOADER_BASE_ADDR + 0x300	; 跳转loader, 直接调到了loader的代码段, 手算出来的, 书上也没有说, 应该是有点问题

; 读取函数
rd_disk_m_16:

	; 备份
	mov esi, eax
	mov di, cx

	; 第一步:设置要读取的扇区数
	mov dx, 0x1f2
	mov al, cl
	out dx, al				; 读取的扇区数

	mov eax, esi			; 恢复ax

	; 第二步:将LBA地址写入0x1f3~0x1f6
	mov dx, 0x1f3
	out dx, al

	mov cl, 8
	shr eax, cl
	mov dx, 0x1f4
	out dx, al

	shr eax, cl
	mov dx, 0x1f5
	out dx, al

	shr eax, cl
	and al, 0x0f
	or al, 0xe0
	mov dx, 0x1f6
	out dx, al

	; 第三步:向0x1f7端口写入读取命令, 0x20
	mov dx, 0x1f7
	mov al, 0x20
	out dx, al

	; 第四步:检查硬盘状态
	.not_ready:
		nop
		in al, dx
		and al, 0x88			; 第四位为1表示已准备好数据, 第七位为1表示未准备好
		cmp al, 0x08
		jnz .not_ready			; 未准备好继续等

	; 第五步:从0x1f0端口读取数据
	mov ax, di
	mov dx, 256
	mul dx
	mov cx, ax					; di为要读取的扇区数, 一个扇区有512字节, 每次读取一个字(两字节), 共需di*512/2次, 所以di*256

	mov dx, 0x1f0
	.go_on_read:
		in ax, dx
		mov [bx], ax
		add bx, 2
		loop .go_on_read
	ret		; 函数返回

times 510-($-$$) db 0
db 0x55, 0xaa
