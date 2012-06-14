BINS= $(patsubst %.s,%.bin,$(wildcard *.s))
VMEMS= $(patsubst %.s,%.vmem,$(wildcard *.s))

all: $(BINS) $(VMEMS)

%.elf: %.s
	mips-sde-elf-as $*.s -o $@

%.bin: %.elf
	mips-sde-elf-objcopy -O binary $*.elf $@

%.vmem: %.elf
	mips-sde-elf-objcopy -O verilog $*.elf $@

clean:
	rm -f *.elf *.bin *.vmem
