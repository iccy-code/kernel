BUILD_DIR = ./build
ENTRY_POINT = 0xc0001500
AS = nasm
CC = gcc
LD = ld
LIB = -I lib/ -I lib/kernel/ -I lib/user/ -I kernel/ -I device/
ASFLAGS = -f elf
ASBINLIB = -I boot/include/
CFLAGS = -m32 -Wall $(LIB) -c -fno-builtin -W -Wstrict-prototypes -Wmissing-prototypes -fno-stack-protector
LDFLAGS = -melf_i386 -Ttext $(ENTRY_POINT) -e main -Map $(BUILD_DIR)/kernel.map
OBJS = $(BUILD_DIR)/main.o $(BUILD_DIR)/init.o $(BUILD_DIR)/interrupt.o $(BUILD_DIR)/timer.o $(BUILD_DIR)/debug.o $(BUILD_DIR)/kernel.o  $(BUILD_DIR)/print.o

############################### 引导代码编译 ##################################
$(BUILD_DIR)/bootstrap.bin: boot/bootstrap.asm boot/include/boot.inc
	$(AS) $(ASBINLIB) $< -o $@
$(BUILD_DIR)/loader.bin: boot/loader.asm boot/include/boot.inc
	$(AS) $(ASBINLIB) $< -o $@

############################### C代码编译 ##################################
$(BUILD_DIR)/main.o: kernel/main.c lib/kernel/print.h lib/stdint.h kernel/init.h
	$(CC) $(CFLAGS) $< -o $@
$(BUILD_DIR)/init.o: kernel/init.c kernel/init.h lib/kernel/print.h kernel/interrupt.h lib/stdint.h kernel/init.h
	$(CC) $(CFLAGS) $< -o $@
$(BUILD_DIR)/interrupt.o: kernel/interrupt.c kernel/interrupt.h lib/stdint.h kernel/global.h lib/kernel/io.h lib/kernel/print.h
	$(CC) $(CFLAGS) $< -o $@
$(BUILD_DIR)/timer.o: device/timer.c device/timer.h lib/stdint.h lib/kernel/io.h lib/kernel/print.h
	$(CC) $(CFLAGS) $< -o $@
$(BUILD_DIR)/debug.o: kernel/debug.c kernel/debug.h lib/kernel/print.h lib/stdint.h kernel/interrupt.h
	$(CC) $(CFLAGS) $< -o $@

############################### 汇编代码编译 ##################################
$(BUILD_DIR)/kernel.o: kernel/kernel.asm
	$(AS) $(ASFLAGS) $< -o $@
$(BUILD_DIR)/print.o: lib/kernel/print.asm
	$(AS) $(ASFLAGS) $< -o $@

########################## 链接除boot代码的目标代码 ###########################
$(BUILD_DIR)/kernel.bin: $(OBJS)
	$(LD) $(LDFLAGS) $^ -o $@

.PHONY: build clean all install

build: $(BUILD_DIR)/kernel.bin $(BUILD_DIR)/bootstrap.bin $(BUILD_DIR)/loader.bin
	clear && echo "dd命令开始执行!!!"

clean:
	cd $(BUILD_DIR) && pwd && rm -f ./*.o

all: build
	dd if=$(BUILD_DIR)/bootstrap.bin of=c.img count=1 bs=512 conv=notrunc
	dd if=$(BUILD_DIR)/loader.bin of=c.img count=4 bs=512 conv=notrunc seek=2
	dd if=$(BUILD_DIR)/kernel.bin of=c.img count=200 bs=512 conv=notrunc seek=9

install: all clean
	bochs -q -f  /usr/local/share/bochs/.bochsrc
	if [ ! "c.img.lock" ]; then	rm -r c.img.lock fi
