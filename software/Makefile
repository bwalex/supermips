BINS= nop.bin

all: $(BINS)

%.elf: %.s
	mips-sde-elf-as $*.s -o $@

%.bin: %.elf
	mips-sde-elf-objcopy -O binary $*.elf $@

clean:
	rm -f *.elf *.bin
