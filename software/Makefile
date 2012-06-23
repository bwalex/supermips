BINS= $(patsubst %.s,%.bin,$(wildcard *.s))
VMEMS= $(patsubst %.s,%.vmem,$(wildcard *.s))
DISS= $(patsubst %.s,%.dis,$(wildcard *.s))

all: $(BINS) $(VMEMS) $(DISS)

%.elf: %.s
	mips-sde-elf-as $*.s -o $@

%.bin: %.elf
	mips-sde-elf-objcopy -O binary $*.elf $@

#%.vmem: %.elf
#	mips-sde-elf-objcopy -O verilog $*.elf $@


%.vmem: %.bin
	ruby post_process.rb $*.bin > $@

%.dis: %.elf
	mips-sde-elf-objdump -D $*.elf > $@

clean:
	rm -f *.elf *.bin *.vmem *.dis

disassemble:
	mips-sde-elf-objdump -EB -m mips -b binary -D *.bin
