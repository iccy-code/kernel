#! /bin/bash

nasm -I boot/ boot/bootstrap.asm
mv boot/bootstrap build/
nasm -I boot/ boot/loader.asm
mv boot/loader build/

dd if=build/bootstrap of=c.img count=1 bs=512 conv=notrunc
dd if=build/loader of=c.img count=4 bs=512 conv=notrunc seek=2

bochs -q -f  /usr/local/share/bochs/.bochsrc

# rm -r c.img.lock
rm bochs.log