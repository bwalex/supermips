# Using set noat so that $1 is not used as temp reg $at
.set noat

start:
	li $8, 0x2a840 # AA10h * 4
	li $1, 0x0AA10

	beq $1, $8, f2
	add $1, $1, $1

	jal start
f2:
	add $4,$8,$9
	srl $1, 4
