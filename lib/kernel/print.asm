TI_GDT equ 0
RPLO equ -
SELECTOR_VIDEO equ (0x0003 << 3) + TI_GDT + RPLO

[bits 32]
section .text
;---------------------put_char----------------------
; 把栈中的一个字符写入光标所在处
;---------------------------------------------------
global put_char
put_char:
	pushad			; 备份32位寄存器环境
	mov ax, SELECTOR_VIDEO
	mov gs, ax


	; 获取当前光标位置
	mov dx, 0x03d4		; 索引寄存器
	mov al, 0x0e		; 提供光标的高8位
	out dx, al
	mov dx, 0x03d5		; 读写该端口获取或设置光标位置
	in al, dx			; 得到光标高8位
	mov ah, al


	; 再得到低8位
	mov dx, 0x03d4
	mov al, 0x0f
	out dx, al
	mov dx, 0x03d5
	in al, dx

	; 将光标存入bx
	mov bx, ax

	; 拿到待打印的字符
	mov ecx, [esp + 36]		; pushad压入4 * 8 == 32字节
							; 加上主调函数的返回地址, 故esp + 36
	cmp cl, 0xd			; CR是0x0d, LF是0x0a
	jz .is_carriage_return
	cmp cl, 0xa
	jz .is_line_feed

	cmp cl, 0x8			; BS(backspace)的ascii码是8
	jz .is_backspace
	jmp .put_other

.is_backspace:
	; 看书上P280
	dec bx
	shl bx, 1

	mov byte [gs:bx], 0x20
	inc bx
	mov byte [gs:bx], 0x07
	shr bx, 1
	jmp .set_cursor

.put_other:
	shl bx, 1

	mov [gs: bx], cl
	inc bx
	mov byte [gs:bx], 0x07
	shr bx, 1
	inc bx
	cmp bx, 2000			; 超出2000个字符了
	jl .set_cursor


.is_line_feed:			; \n
.is_carriage_return:	; \r	将光标移到行首即可

	xor dx, dx
	mov ax, bx
	mov ax, bx
	mov si, 80

	div si
	sub bx, dx

.is_carriage_return_end:		; 回车符CR处理结束
	add bx, 80
	cmp bx, 2000
.is_line_feed_end:				; 若是LF, 将光标 + 80即可
	jl .set_cursor



; 屏幕范围是0~24, 滚屏原理就是将1~24行搬运到0~23, 覆盖第0行, 就空了第24行
.roll_screen:
	cld				; 清除方向位
	mov ecx, 960	; 一次搬运4字节, 共960次

	mov esi, 0xc00b80a0		; 第一行行首
	mov edi, 0xc00b8000		; 第零行行首
	rep movsd

	; 将最后一行填充空白
	mov ebx, 3840
	mov ecx, 80

.cls:
	mov word [gs:ebx], 0x0720	; 黑底白字的空格键
	add ebx, 2
	loop .cls
	mov bx, 1920				; 将光标重置为1920

.set_cursor:
; 设置光标位置
	mov dx, 0x03d4
	mov al, 0x0e
	out dx, al
	mov dx, 0x03d5
	mov al, bh
	out dx, al

	mov dx, 0x03d4
	mov al, 0x0f
	out dx, al
	mov dx, 0x03d5
	mov al, bl
	out dx, al

.put_char_done:
	popad
	ret