#! /bin/bash

# boot
nasm -I boot/ -o build/bootstrap.bin boot/bootstrap.asm
# mv boot/bootstrap build/
nasm -I boot/ -o build/loader.bin boot/loader.asm
# mv boot/loader build/
nasm -f elf -o build/print.bin lib/kernel/print.asm

nasm -f elf -o build/kernel.bin kernel/kernel.asm



# kernel
gcc -m32 -I lib/kernel -I lib/ -I kernel/ -c -fno-builtin -fno-stack-protector -o build/main.bin kernel/main.c
gcc -m32 -I lib/kernel -I lib/ -I kernel/ -c -fno-builtin -fno-stack-protector -o build/interrupt.bin kernel/interrupt.c
gcc -m32 -I lib/kernel -I lib/ -I kernel/ -c -fno-builtin -fno-stack-protector -o build/init.bin kernel/init.c

ld -m elf_i386 -Ttext 0xc0001500 -e main -o build/kernel build/main.bin build/print.bin build/init.bin build/interrupt.bin build/kernel.bin



# dd
dd if=build/bootstrap.bin of=c.img count=1 bs=512 conv=notrunc
dd if=build/loader.bin of=c.img count=4 bs=512 conv=notrunc seek=2
dd if=build/kernel of=c.img count=200 bs=512 conv=notrunc seek=9


bochs -q -f  /usr/local/share/bochs/.bochsrc

if [ ! "c.img.lock" ]; then
	rm -r c.img.lock
fi

# rm bochs.log