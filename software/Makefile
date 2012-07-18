BINS= $(patsubst %.s,%.bin,$(wildcard *.s))
VMEMS= $(patsubst %.s,%.vmem,$(wildcard *.s))
DISS= $(patsubst %.s,%.dis,$(wildcard *.s))

BINS+= dhry.bin coremark.bin
VMEMS+= dhry.vmem coremark.vmem
DISS+= dhry.dis coremark.dis

ASFLAGS?= -march=74kc

all: $(BINS) $(VMEMS) $(DISS)

dhry.elf:
	make -C ./dhrystone
	mv ./dhrystone/dhry.elf ./dhry.elf

coremark.elf:
	make -C ./coremark PORT_DIR=supermips link
	mv ./coremark/coremark.bin ./coremark.elf

%.elf: %.s
	mips-sde-elf-as $(ASFLAGS) $*.s -o $@

%.bin: %.elf
	mips-sde-elf-objcopy -O binary --set-section-flags .bss=alloc,load,contents $*.elf $@

#%.vmem: %.elf
#	mips-sde-elf-objcopy -O verilog $*.elf $@


%.vmem: %.bin
	ruby post_process.rb $*.bin > $@

%.dis: %.elf
	mips-sde-elf-objdump -d -M reg-names=numeric $*.elf > $@

clean:
	rm -f *.elf *.bin *.vmem *.dis
	make -C ./dhrystone clean
	make -C ./coremark PORT_DIR=supermips clean

disassemble:
	mips-sde-elf-objdump -EB -m mips -b binary -D -M reg-names=numeric *.bin
