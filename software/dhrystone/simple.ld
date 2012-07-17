ENTRY(_start)
SECTIONS
{
	.text :
	{
		CREATE_OBJECT_SYMBOLS
		_ftext = .;
		*(.text.FIRST)
		. = ALIGN(8);
		*(.text.*)
		*(.lit)
		. = ALIGN (8);
		_etext = .;
	}
	.data : ALIGN (8)
	{
		*(.got.plt) *(.got)
		*(.shdata)
		*(.data .data.* .gnu.linkonce.d.*)
		. = ALIGN(8);
		_gp = . + 0x8000;
		*(.lit8)
		*(.lit4)
		*(.sdata .sdata.* .gnu.linkonce.s.*)
		. = ALIGN(8);
		*(.ram)
		. = ALIGN(8);
		_edata = .;
	}
	.bss : ALIGN (8)
	{
		*(.sbss .sbss.* .gnu.linkonce.sb.*)
		*(.scommon)
		*(.shbss)
		*(.bss .bss.* .gnu.linkonce.b.*)
		*(COMMON)
		. = ALIGN (8);
		*(.ram.b .bss.ram)
		. = ALIGN (8);
		_end = .;
		__end = .;
	}
}
