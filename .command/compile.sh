# ####  此脚本应该在command目录下执行

# if [[ ! -d "../lib" || ! -d "../build" ]];then
# 	echo "dependent dir don\`t exist!"
# 	cwd=$(pwd)
# 	cwd=${cwd##*/}
# 	cwd=${cwd%/}
# 	if [[ $cwd != "command" ]];then
# 		echo -e "you\`d better in command dir\n"
# 	fi
# 	exit
# fi

BIN="cat"
# CFLAGS="-Wall -c -fno-builtin -W -Wstrict-prototypes Wmissing-prototypes -Wsystem-headers"
CFLAGS="-Wall -c -fno-builtin -W -Wstrict-prototypes -Wsystem-headers"
LIBS="-I ../lib/ -I ../lib/kernel/ -I ../lib/user/ -I ../kernel/ -I ../device/ -I ../thread/ -I ../userprog/ -I ../fs/ -I ../shell/"
OBJS="../build/string.o ../build/syscall.o ../build/stdio.o ../build/assert.o start.o"
DD_IN=$BIN
DD_OUT="../c.img"

# nasm -I boot/include/ -o build/bootstrap boot/bootstrap.asm
nasm -f elf -o start.o start.asm
ar rcs simple_crt.a $OBJS start.o
gcc $CFLAGS $LIBS -o cat.o cat.c
ld $BIN".o" simple_crt.a -o $BIN
SEC_CNT=$(ls -l $BIN|awk '{printf("%d", ($5+511)/512)}')

if [[ -f $BIN ]];then
	dd if=./$DD_IN of=$DD_OUT bs=512 count=$SEC_CNT seek=300 conv=notrunc
fi