# Title: Question 3
# Author: Johnatan Dvoishes
# Input: String, up to 30 chars
# Output: Count of unequal chars at sides. If 0 then print Palindrome

#Explanation about algorithm: the program will find the length of the input string and will use it as an index.
#It will then use this index and another index that starts at 0 to compare the characters of the string, until both indexes are equal.

################# Data segment #####################
.data
buf:     .space    31
str:	 .asciiz "Please enter a string up to 30 chars\n"
unequal: .asciiz "\n The number of unequal chars in sides is: \n"
pal:     .asciiz "\n The String is a Palindrome\n"     
     
################# Code segment #####################
.text
.globl main
main:	# main program entry
		
	li $v0,4
	la $a0,str     #"please enter a string up to 30 chars"
	syscall


########## get string from the user ######

	li $a1,31 #Limit to 31 chars
	la $a0,buf #Address of input buffer
	li $v0,8 #Read String
	syscall
								
########## Get length of String ################

	move $s0,$zero #set Counter for unequal chars
	la $t0,0       #Counter of array for string 
	lb $t1,buf($t0)#Insert first char from array in memory
	
get_length: #Function for getting the length of string
	beq $t1,10,done_getting_length #Will branch when char has ascii value of 10
	addi $t0,$t0,1
	lb $t1,buf($t0)
	b get_length

	done_getting_length:
	move $t2,$t0 # Save the length parameter to $t2
	addi $t2,$t2,-1 #Remove excess 
	move $t0,$zero #Restart array counter 
	
########## Compare chars ################
	
compare: #Function to compare each char from both sides
	bge $t0,$t2,done #Will branch when start index is equal to end index
	lb $t3,buf($t0) #Load char in t3 and t4 to compare
	lb $t4,buf($t2)
	beq $t3,$t4,equal #Will not add 1 to unequal char counter if characters are equal
	addi $s0,$s0,1
	equal:
	addi $t0,$t0,1
	addi $t2,$t2,-1
	b compare
	
	
########## Print results ################
done:
	li $v0,4
	la $a0,unequal    #"Number of unequal chars is"
	syscall
	
	li $v0,1
	move $a0,$s0     #"Unequal char counter"
	syscall
	
	bne $s0,$zero,not_palindrome #Not a palindrome if unequal char counter is not zero
	li $v0,4
	la $a0,pal     	#"Is a palindrome"
	syscall
	
	not_palindrome:
	

#########Terminate Program################
exit:
	li $v0,10
	syscall
	
