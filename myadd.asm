# myadd.asm
#Wei Yee Goh

.data
	A: .float -3.55
	B: .float 15.4
	C: .space 4
	
.text
MYADD: 
	move $t0, $a0
	move $t1, $a1
		
	beq $t0, $0, zeroInput		#if zero, return value in $t1
	move $t3, $t0				#swap $t0, $t1
	move $t0, $t1				
	move $t1, $t3
	beq $t0, $0, zeroInput		#if zero, return value in $t1
	move $t3, $t0				#swap $t0, $t1
	move $t0, $t1				
	move $t1, $t3
	
	
	srl $t2, $t0, 31 	#$t2 is the sign for A
	srl $t3, $t1, 31	#$t3 is the sign for B
	
	sll $t4, $t0, 1
	srl $t4, $t4, 24	#$t4 is the exponent for A
	sll $t5, $t1, 1	
	srl $t5, $t5, 24	#$t5 is the exponent for B
	
	li $t6, 1			
	sll $t6, $t6, 23	# $t6 contains 1 bit in the 24th position from right.
	
	sll $t0, $t0, 9
	srl $t0, $t0, 9		#$t0 is the decimal factor for A
	addu $t0, $t0, $t6
	sll $t1, $t1, 9
	srl $t1, $t1, 9		#$t1 is the decimal factor for B
	addu $t1, $t1, $t6
	
	#now we check if its already infinity
	li $t7, 255
	beq $t7, $t2, overFlow
	beq $t7, $t3, overFlow
	
	#now we check if they are positive negatives of same integer
	bne $t4, $t5, skipPosNegCheck	#if exponents are different, no need to check further
	bne $t0, $t1, skipPosNegCheck 	#if fraction are different, no need to check further
	bne $t2, $t3, returnZero		#if sign is different, then return 0
	


skipPosNegCheck:
		
	beq $t4, $t5, skipIncExp	#if t4 and t5 are equal, we dont need to swap and we dont need to increment exp
	li $t6, 0
	slt $t6, $t5, $t4			#if t5 is less than t4, set this to 1 (1 means $t4 isnt smallest)
								#we want to make it so $t4 is the smaller exponent one
	beq $t6, $zero, incExp	#we skip the swap if $t6 is 0 (which means $t4 is already smallest). 
	
	#SWAP so smaller exp is containted in is t0, t2, t4
	move $t6, $t2
	move $t2, $t3
	move $t3, $t6
	
	move $t6, $t4
	move $t4, $t5
	move $t5, $t6
	
	move $t6, $t0
	move $t0, $t1
	move $t1, $t6
	
incExp: 						#increment exp so they are same

	li $t8, 0					#reset t6
	li $t9, 0					#reset t7
	
loopInc:
	beq $t8, $0, skipSetStickyToOne
	li $t9, 1					#set sticky to one here
	
skipSetStickyToOne:
	andi $t8, $t0, 1 			#get the value of the right most bit
	
	addi $t4, $t4, 1			#incrementing exponent	
	srl $t0, $t0, 1				#shift t0 right 1
	bne $t4, $t5, loopInc		#if t4 != t5, we want to keep looping until it is

skipIncExp:
	beq $t2, $0, skipANeg
	nor $t0, $t0, $0
	addi $t0, $t0, 1
	
skipANeg:

	beq $t3, $0, skipBNeg
	nor $t1, $t1, $0
	addi $t1, $t1, 1
skipBNeg:
	add $t0, $t0, $t1			#add the two fractions together
	srl $t1, $t0, 31			#put sign value inside of t1 now
	beq $t1, $0, skipFlipToPos	
	
	nor $t0, $t0, $0			#two's complement it so the fraction is pos
	addi $t0, 1

skipFlipToPos:

	move $t2, $t5				#t2 now holds the exponent for convenience sake
	
	move $t3, $t0				#temporarily hold fraction in t3 so returnable after bne
	srl $t0, $t0, 24			#shift right so we can check 25th bit
	bne $t0, $0, minusOneExp	#if 25th bit is 1, we skip normalizing because we only need to add one to exponent
								#this happens if 25th bit is a 0
	sll $t0, $t3, 8				#putting original fraction back into t0, except fraction is now put to the far left (24th bit is in 32nd bit now)

normalize:
	srl $t3, $t0, 31								#bring far left bit of fraction (including 24th) to 1st bit
	beq $t2, $0, underFlow 						#if our exponent is already 0, we return underflow because we will be subtracting from exponent after this

	bne $t3, $0, combineEverything					#if that bit is a 1, then we found our spot so go to combineEverything
			
	sll $t0, $t0, 1			#shifting it right 1
	nor $t8, $t8, $0		#two's complementing t8 into -1
	addi $t8, 1				#two's complementing t8 into -1
	add $t0, $t0, $t8		#adding R bit into mantissa (basically in case R is 1)
							#now we decrement exponent	
	li $t7, 1				#creating negative 1
	nor $t7, $t7, $0
	addi $t7, 1
	add $t2, $t2, $t7		#adding negative 1
	
	li $t8, 0				#set t8 as 0 because we will be shiting left. Never round from here anymore


	j normalize

	
minusOneExp:
	or $t9 $t9, $t8					#if either t8 or t9 is 1, then sticky will be 1
	andi $t8, $t3, 1				#get right most value of our fraction. This bit will end up in S when we shift
	
	sll $t0, $t3, 7					#bring 25th bit all the way to the far left
	addi $t2, $t2, 1				#add 1 to our exponent value
		
	li $t3, 255
	beq $t2, $t3, overFlow		#check is exponent is equal to 255. if yes, then it is overflow
	
combineEverything:
	li $t7, 0					#this will be our isRound bit
	beq $t8, $0, dontSetRound 
	beq $t9, $0, dontSetRound
	li $t7, 1

dontSetRound:
	sll $t0, $t0, 1			#kill our far left bit (because it is implied)
	srl $t0, $t0, 9			#go right 9 (1 for sign, 8 for exponent)
	
	li $t9, 1
	bne $t7, $t9, noRound	#if t7 is 0, we dont round
	addi $t0, $t0, 1		#because t8 was 1, we now add 1 to our fraction
	
	srl $t4, $t0, 24		#shift right 24 so we can check 25th bit
	bne $t4, $t9, noRound	#if 25th bit from t4 is not 1, then we are good and we can move to next step
	
	srl $t0, $t0, 1			#we shift t0 right 1 so 24th bit holds the 0 now. We do this becz 25th bit is a 1
	addi $t2, $t2, 1		#because 25th bit was 1, we must increment our exponent
	
	li $t4, 255
	beq $t2, $t4, overFlow		#if t2 == 255, then there is overFlow
	
noRound:
	sll $t1, $t1, 31
	addu $t0, $t0, $t1		#adding the sign bit to our fraction section
	
	sll $t2, $t2, 23
	addu $t0, $t0, $t2		#adding our exponent section to our fraction section
	
	move $v0, $t0
	
	jr $ra

overFlow:
	sll $t1, $t1, 31
	li $t7, 255
	sll $t7, $t7, 23
	add $v0, $t7, $t1
	
	jr $ra
	
underFlow:
	li $v0, 0
	jr $ra
	
zeroInput:
	move $v0, $t1
	jr $ra
	
returnZero:
	li $v0, 0
	jr $ra

main: 
	lw $a0, A
	lw $a1, B
	
	jal MYADD
	sw $v0, C
	
	
	li $v0, 10
	syscall
	