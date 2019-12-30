#! /bin/bash

# 汇编代码编译
nasm -I boot/include/ -o build/bootstrap boot/bootstrap.asm
nasm -I boot/include/ -o build/loader boot/loader.asm
nasm -f elf -o build/print.bin lib/kernel/print.asm
nasm -f elf -o build/kernel.bin kernel/kernel.asm

# C代码编译
gcc -m32 -I lib/kernel -I lib/ -I kernel/ -c -fno-builtin -fno-stack-protector -o build/main.bin kernel/main.c
gcc -m32 -I lib/kernel -I lib/ -I kernel/ -c -fno-builtin -fno-stack-protector -o build/interrupt.bin kernel/interrupt.c
gcc -m32 -I lib/kernel -I lib/ -I kernel/ -c -fno-builtin -fno-stack-protector -o build/init.bin kernel/init.c
gcc -m32 -I lib/kernel -c -o build/timer.bin device/timer.c
gcc -m32 -I lib/kernel -I lib/ -I kernel/ -I device/ -c -fno-builtin -fno-stack-protector -o build/debug.bin kernel/debug.c

# 链接
ld -m elf_i386 -Ttext 0xc0001500 -e main -o build/kernel build/main.bin build/print.bin build/init.bin build/interrupt.bin build/kernel.bin build/timer.bin build/debug.bin

# 写入软盘
dd if=build/bootstrap of=c.img count=1 bs=512 conv=notrunc
dd if=build/loader of=c.img count=4 bs=512 conv=notrunc seek=2
dd if=build/kernel of=c.img count=200 bs=512 conv=notrunc seek=9

# 启动bochs
bochs -q -f  /usr/local/share/bochs/.bochsrc

if [ ! "c.img.lock" ]; then
	rm -r c.img.lock
fi

# rm bochs.log