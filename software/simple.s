# Using set noat so that $1 is not used as temp reg $at
.set noat

li $8, 0x3BF20
li $1, 0x0AA10

move $2, $1

add $4,$8,$9

li $4, 0xAABBCCDD
sw $4, 0

lhu $4, 0
lhu $5, 2
