	.data
	.text
	.align 2
	.globl _start
	.globl _exit

	.section .text.FIRST
_start:
	li $sp, 0x1FFFFF0
	la $gp, _gp
	#jal _init
	jal main

_exit:
	#jal _fini
	b _exit
