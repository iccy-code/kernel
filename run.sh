#! /bin/bash

# boot
nasm -I boot/ -o build/bootstrap.bin boot/bootstrap.asm
# mv boot/bootstrap build/
nasm -I boot/ -o build/loader.bin boot/loader.asm
# mv boot/loader build/
nasm -f elf -o build/print.bin lib/kernel/print.asm

# kernel
gcc  -m32 -I lib/kernel/ -c -o  build/main.bin kernel/main.c
ld -m elf_i386  -Ttext 0xc0001500 -e main -o build/kernel.bin build/main.bin build/print.bin 


# dd
dd if=build/bootstrap.bin of=c.img count=1 bs=512 conv=notrunc
dd if=build/loader.bin of=c.img count=4 bs=512 conv=notrunc seek=2
dd if=build/kernel.bin of=c.img count=200 bs=512 conv=notrunc seek=9


bochs -q -f  /usr/local/share/bochs/.bochsrc

rm -r c.img.lock
# rm bochs.log