#! /bin/bash

# boot
nasm -I boot/ boot/bootstrap.asm
mv boot/bootstrap build/
nasm -I boot/ boot/loader.asm
mv boot/loader build/

# kernel
gcc -c -o build/main.o init/main.c
ld build/main.o -Ttext 0xc0001500 -e build/main -o build/kernel && rm build/main.o


# dd
dd if=build/bootstrap of=c.img count=1 bs=512 conv=notrunc
dd if=build/loader of=c.img count=4 bs=512 conv=notrunc seek=2
dd if=build/kernel of=c.img count=200 bs=512 conv=notrunc seek=9


bochs -q -f  /usr/local/share/bochs/.bochsrc

rm -r c.img.lock
rm bochs.log