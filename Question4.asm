# Title: Question 4
# Author: Johnatan Dvoishes
# Input: String, up to 36 chars
# Output: Converted string, sorted from Largest to Smallest, signed and unsigned versions

################# Data segment #####################
.data
stringhex:         .space    37
str:	           .asciiz "Please enter couples of hexa digits seperated by $. Limit to 36 chars\n"
wrong_msg:         .asciiz "Wrong input, please enter again\n"
NUM:               .byte   0,0,0,0,0,0,0,0,0,0,0,0
NUM_BACKUP:	   .byte   -128,-128,-128,-128,-128,-128,-128,-128,-128,-128,-128,-128 #Backup array because we delete NUM array in unsign procedure. I put -128 instead of 0 because negative numbers will be compared to that value.
unsign:            .byte   0,0,0,0,0,0,0,0,0,0,0,0
sign:         	   .byte   0,0,0,0,0,0,0,0,0,0,0,0
str_unsign:        .asciiz "\n Unsigned sorted values\n"
str_sign:          .asciiz "\n Signed sorted values\n"
str_smaller:       .asciiz " > "
unsign_buffer:     .space 12 #Space for converting the number to string format
unsign_buffer_REV: .space 12 #Space for putting the reversed string 
sign_buffer:       .space 12
sign_buffer_REV:   .space 12
################# Code segment #####################
.text
.globl main

#Print message if invalid value
wrong:
	li $v0,4
	la $a0,wrong_msg     #"Invalid String, please enter again"
	syscall

main:	# main program entry
		
	li $v0,4
	la $a0,str     #"please enter a string up to 36 chars"
	syscall


#Get string from the user and put it in array stringhex

	li $a1,37 #Limit to 36 chars
	la $a0,stringhex #Loads the string in aray
	li $v0,8 #Read String
	syscall
	jal is_valid
	beq $v0,$zero,wrong #Will need to input value again if not valid
	
	move $s5,$v0 #Number of couples is stored here, was calculated in is_valid
	
	#Set argument parameters to "convert" procedure and call it
	la $a0,stringhex
	la $a1,NUM
	move $a2,$s5 #Save number of couples in s5
	jal convert 
	
	move $a2,$s5  
	jal backup_array #Create backup of array num because we delete it in sortunsign
	
	#Call to sortunsign with required parameters
	la $a0,unsign
	la $a1,NUM
	move $a2,$s5
	jal sortunsign
	
	#Call to sortsign with required parameters
	la $a0,sign
	la $a1,NUM_BACKUP
	move $a2,$s5
	jal sortsign
	
	#Call to printunsign with required parameters
	la $a0,unsign
	move $a1,$s5
	jal printunsign
	
	#call to printsign with required parameters
	la $a0,sign
	move $a1,$s5
	jal printsign
	
	#Finish program
	b exit
	
	


#Procedure for checking if string input is valid
is_valid:
	
	move $v0,$zero #v0 is return value, reset it to 0
	la $t0,0       #Counter of array for string 
	first:
	#Check first hexa digit
	lb $t1,stringhex($t0)#Insert char from stringhex
	blt $t1,'0',is_invalid
  	bgt $t1,'F',is_invalid
  	beq $t1,10,is_invalid
  	bge $t1,':',check_range_1
  	b second
  	check_range_1: #Will check if the character is in range of ':' and '@'. If yes then it will branch to invalid
  	ble $t1,'@',is_invalid
  	
  	
  	second:
  	#Check second hexa digit
  	addi $t0,$t0,1
  	lb $t1,stringhex($t0)
  	blt $t1,'0',is_invalid
  	bgt $t1,'F',is_invalid
  	beq $t1,10,is_invalid
  	bge $t1,':',check_range_2
  	b dollar
  	check_range_2: 
  	ble $t1,'@',is_invalid
  	
  	#Update counter of hexa couples
  	addi $v1,$v1,1
  	
  	dollar:
  	#Check dollar sign
  	addi $t0,$t0,1
  	lb $t1,stringhex($t0)
  	bne $t1,'$',is_invalid
  	beq $t1,10,is_invalid
  	addi $v0,$v0,1
  	
  	#Check if loop condition is met
  	addi $t0,$t0,1
  	lb $t1,stringhex($t0)
  	bne $t1,10,first #If current char is not equal to newline, it means the string has not ended.
  	
  	bgt $v0,12,is_invalid # Checks if more than 12 pairs
	jr $ra #Return to caller with the number of couples inside $v0
	
	is_invalid: #If value invalid, immediatly return to caller with result 0
	move $v0,$zero
	jr $ra

#Procedure for converting each hexa couple to a byte sized number
convert:

	la $t0,0 #Index of array stringhex
	la $t3,0 #Index of array NUM    
	
	#Loop for converting the numbers
	convert_couple:	
	#Since value inside the hexa is in ascii, need to convert it to numeric. for that we need to substract 48 or 55.
		
	#Get numeric vaue of first hexa number
	lb $t1,stringhex($t0)
	bgt $t1,'@',subtract_55_1
	b subtract_48_1
	subtract_55_1:
	addi $t1,$t1,-55
	b subtract_done_1
	subtract_48_1:
	addi $t1,$t1,-48
	subtract_done_1:
	
   	
	#Get numeric value of second number
	addi $t0,$t0,1
	lb $t2,stringhex($t0)
	bgt $t2,'@',subtract_55_2
	addi $t2,$t2,-48
	b subtract_done_2
	subtract_55_2:
	addi $t2,$t2,-55	
	subtract_done_2:
	
	#Combine the two digits into one using sll and or
	sll $t1,$t1,4
	or $t1,$t1,$t2
	sb $t1,NUM($t3)
	
	#Update indexes and check if reached end of word
	addi $t0,$t0,2
	addi $t3,$t3,1
	lb $t1,stringhex($t0)
	bne $t1,10,convert_couple 
	jr $ra

#Backup NUM array because we will delete NUM after sortunsign
backup_array:
	move $t0,$zero
	backup_loop:
	lb $t1,NUM($t0)
	sb $t1,NUM_BACKUP($t0)
	addi $t0,$t0,1
	beq $t0,$a2,exit_backup
	b backup_loop
	exit_backup:

	jr $ra

#Sort vaues into unsign array
sortunsign:
	
	#Explanation of algorithm: in each loop through NUM, we will find the max value, insert it to unsign and then delete it from NUM array.Repeat until index is equal number count
	move $t2,$zero #Counter of unsign array
	outer_loop:
	beq $t2,$a2,exit_sortunsign
	move $t0,$zero
	lb $t1,NUM($t0) #Start value, t1 holds max
	move $t4,$t0 #t4 holds index of current max in NUM array
		max_test_loop:
		addi $t0,$t0,1
		beq $t0,$a2,exit_max_test
		lb $t3,NUM($t0) #t3 hold value to compare
		bgtu $t1,$t3,not_change_max
		move $t1,$t3
		move $t4,$t0 #Change index of max in num array
		not_change_max:
		b max_test_loop
		
		exit_max_test:
		sb $t1,unsign($t2) #Store value into unsign array
		sb $zero,NUM($t4) #Delete value from NUM
		addi $t2,$t2,1
		b outer_loop
		  		
	exit_sortunsign:

	jr $ra
	
#Sort vaues into sign array
sortsign:#The difference from sortunsign is that we use bgt and the NUM array is started with -128 instead of zeroes
	move $t4,$zero
	move $t2,$zero #Counter of unsign
	outer_loop_sign:
	beq $t2,$a2,exit_sortsign
	move $t0,$zero
	lb $t1,NUM_BACKUP($t0) #Start value, t1 holds max
	move $t4,$t0
		max_test_loop_sign:
		addi $t0,$t0,1
		beq $t0,$a2,exit_max_test_sign
		lb $t3,NUM_BACKUP($t0) #t3 hold value to compare
		bgt $t1,$t3,not_change_max_sign
		move $t1,$t3
		move $t4,$t0#t4 holds the max value
		not_change_max_sign:
		b max_test_loop_sign
		
		exit_max_test_sign:
		sb $t1,sign($t2)
		li $t8,-128 #We load -128 instead of 0 because the numbers can be negative
		sb $t8,NUM_BACKUP($t4) #Delete value from NUM_BACKUP
		addi $t2,$t2,1
		b outer_loop_sign
		
		
    		
	exit_sortsign:

	jr $ra
	
printunsign:
	move $s1,$ra #save $ra before jal overwrites it
	li $v0,4
	la $a0,str_unsign    
	syscall
	
	#Loop for printing from unsign array
	move $t0,$zero
	print_unsign_loop:
	beq $t0,$s5,exit_print_unsign
	
	#Convert the number to string using a special procedure "convert_to_string"
	lb $t1,unsign($t0)
	move $a0, $t1 
	la $a1,unsign_buffer
	li $a2,0 #Insert argument 0 so the number will be handled as unsigned
	la $a3,unsign_buffer_REV #Will put the reversed string inside this buffer
	jal convert_to_string #Go to method that converts to string
	
	
	#Print the String
	li $v0, 4          
   	la $a0, unsign_buffer_REV    
    	syscall
    	addi $t0,$t0,1
    	
    	#Clear buffer for next number
    	move $t4,$zero
    	clear_unsign_buffer_loop:
    	beq $t4,12,exit_clear_unsign_buffer_loop
    	sb $zero,unsign_buffer($t4)
    	addi $t4,$t4,1
    	b clear_unsign_buffer_loop
    	exit_clear_unsign_buffer_loop:
    	move $t4,$zero
    	
    	#Print "<" symbol
    	beq $t0,$s5,print_unsign_loop
    	li $v0,4
	la $a0,str_smaller   
	syscall
	
    	b print_unsign_loop
    	
    	exit_print_unsign:
    	move $ra,$s1 # Restore $ra
	jr $ra
printsign:
	move $s1,$ra #save $ra before jal overwrites it
	li $v0,4
	la $a0,str_sign    
	syscall
	
	#Loop for printing from sign array
	move $t0,$zero
	print_sign_loop:
	beq $t0,$s5,exit_print_sign
	
	#Convert the number to string using a special procedure "convert_to_string"
	lb $t1,sign($t0)
	move $a0, $t1
	la $a1,sign_buffer
	li $a2,1 #Insert argument 1 so the number will be handled as signed. 0 is for unsigned
	la $a3,sign_buffer_REV #Will put the reversed string inside this buffer
	
	
	#Clear temporary before string
	move $t1,$zero
	jal convert_to_string #Go to method that converts to string
	
	
	
	#Print the string
	li $v0, 4   
   	la $a0, sign_buffer_REV #Print from buffer      
    	syscall
   
    	addi $t0,$t0,1
    	
    	#Clear buffer for next number
    	move $s4,$zero
    	clear_sign_buffer_loop:
    	beq $s4,12,exit_clear_sign_buffer_loop
    	sb $zero,sign_buffer($s4)
    	addi $s4,$s4,1
    	b clear_sign_buffer_loop
    	exit_clear_sign_buffer_loop:
    	move $s4,$zero
    	
    	#Print "<" symbol
    	beq $t0,$s5,print_sign_loop
    	li $v0,4
	la $a0,str_smaller   
	syscall
	
    	b print_sign_loop
    	
    	exit_print_sign:
    	move $ra,$s1 # Restore $ra
	jr $ra

convert_to_string:
	
	#Explanation of algorithm: to get each digit we will divide number by 10 and convert it to ascii.
	#We will store each digit inside the corresponding buffer array.
	#if number is negative will add "-" sign. Will need to reverse string in order to print it correctly.
	
	bne $a2,1,handle_unsigned #Check if should handle signed or unsigned
	bltz $a0, add_minus #Check if smaller than zero. Should add minus sign
	li $t9, 0 #Index used for "Reverse" function
	move $t6, $zero # Number of digits , used for "Reverse" function
	
    	j convert_string
	
	#Adds minus ascii sign to string
	add_minus:
    	li $t4, 45            
    	sb $t4, sign_buffer_REV($zero)        
    	addi $a3, $a3, 1 
    	li $t9, 1 #Index is incremented by 1 to make room for "-" sign
    	li $t6, 1    
    	#Need to turn number to positive if negative
    	sub $a0, $zero, $a0 
    	b convert_string
    	
    	handle_unsigned:
    	andi $a0,$a0,0x000000FF #Zero extend so the unsigned number will be shown as positive 

	convert_string:
   	li $t5, 10            #Will divide by 10
    	
    	#Loop that divides the number by 10 and stores each digit in buffer
	convert_loop:
    	beq $a0, $zero, reverse_string 
    	
    	div $a0, $t5                 # Divide number by 10
    	mfhi $t8                     # Save Remainder 
   	mflo $a0                     # Save Quotient
    	addi $t8, $t8, 48            # Convert to ASCII
    	sb $t8, 0($a1)               # Store Remainder in buffer as digit
    	
    	addi $a1, $a1, 1                
    	addi $t6, $t6, 1                
    	j convert_loop

	reverse_string:

	reverse_loop:
    	beq $t9, $t6, done_convert 
   	sub $a1, $a1, 1  
   	#Load the digit and store it in reverse order    
   	lb $t8, 0($a1)
   	sb $t8, 0($a3)       
   	addi $a3, $a3, 1     
   	addi $t9, $t9, 1 
   	j reverse_loop

	done_convert:
    	sb $zero, 0($a3)     # Add Null terminator
	jr $ra	
	
#########Terminate Program################
exit:
	li $v0,10
	syscall
	
