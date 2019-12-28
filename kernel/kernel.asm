[bits 32]
%define ERROR_CODE nop		; 若在相关异常中CPU已经自动压入了错误码, 在这里不做其他操作
%define ZERO push 0			; 若没有错误码, 其在这压入0, 保持格式一样, 使栈指针是在同一个地方

;extern put_str				; 声明外部函数
extern idt_table

section .data
;intr_str db "interrupt occur!", 0xa, 0
global  intr_entry_table
intr_entry_table:

%macro VECTOR 2
section .text
intr%1entry:				; 每个中断处理程序都要压入中断向量号, 所以一个中断类型一个中断处理程序知道自己的中断向量号的值, 标号不能重复, 所以有个%1, 

;----------------------旧版
;	%2
;	push intr_str
;	call put_str
;	add esp, 4				; 跳过参数
;
;	; 如果是从片上进入的中断, 除了往从片上发送EOI外, 还要往主片上发送EOI
;	mov al, 0x20			; 中断结束命令EOI
;	out 0xa0, al			; 向从片发送
;	out 0x20, al			; 向主片发送
;
;	add esp, 4				; 跨过error_code
;	iret					; 从中断返回, 32位下等同指令iretd
;
;section .data
;	dd intr%1entry			; 存储各个中断入口程序的地址, 形成intr_entry_table数组

;------------------------新版

	%2			; 保存上下文环境
	push ds
	push es
	push fs
	push gs
	pushad		; 该指令压入32位寄存器, 其入栈顺序是: EAX, ECX, EDX, EBX, ESP, EBP, EDI. eax最先入栈

	mov al, 0x20	; 中断结束命令EOI
	out 0xa0, al	; 向从片发送
	out 0x20, al	; 向主片上发送chen
	

	push %1			; 不管idt_table中的目标程序是否需要参数, 一律压入中断向量号, 调试方便

	call [idt_table + %1*4]		; 调用idt_table中的C版本中断处理函数
	jmp intr_exit

section .data
	dd intr%1entry					; 存储各个中断入口程序的地址, 形成intr_entry_table数组

%endmacro

section .text
global intr_exit
intr_exit:				; 恢复上下文环境
	add esp, 4			; 跳过中断号
	popad
	pop gs
	pop fs
	pop es
	pop ds
	add esp, 4			; 跳过error_code
	iretd

VECTOR 0x00, ZERO
VECTOR 0x01, ZERO
VECTOR 0x02, ZERO
VECTOR 0x03, ZERO
VECTOR 0x04, ZERO
VECTOR 0x05, ZERO
VECTOR 0x06, ZERO
VECTOR 0x07, ZERO
VECTOR 0x08, ERROR_CODE
VECTOR 0x09, ZERO
VECTOR 0x0a, ERROR_CODE
VECTOR 0x0b, ERROR_CODE
VECTOR 0x0c, ZERO
VECTOR 0x0d, ERROR_CODE
VECTOR 0x0e, ERROR_CODE
VECTOR 0x0f, ZERO
VECTOR 0x10, ZERO
VECTOR 0x11, ERROR_CODE
VECTOR 0x12, ZERO
VECTOR 0x13, ZERO
VECTOR 0x14, ZERO
VECTOR 0x15, ZERO
VECTOR 0x16, ZERO
VECTOR 0x17, ZERO
VECTOR 0x18, ERROR_CODE
VECTOR 0x19, ZERO
VECTOR 0x1a, ERROR_CODE
VECTOR 0x1b, ERROR_CODE
VECTOR 0x1c, ZERO
VECTOR 0x1d, ERROR_CODE
VECTOR 0x1e, ERROR_CODE
VECTOR 0x1f, ZERO
VECTOR 0x20, ZERO