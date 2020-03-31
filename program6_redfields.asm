TITLE Macro    (program6_redfields.asm)

; Author: Long Mach
; Last Modified: Mar 15, 2020
; OSU email address: machl@oregonstate.edu
; Course number/section: CS_271_C400
; Project Number: Program 6                Due Date: Mar 15, 2020
; Description: This program will ask the user to input 10 signed decimal integers.
;	then calculate and display them, their sum and their average value.
;	- The input will be read as a string then covert to number and be validated whether it has
;	non-digits (beside '+' or '-') or is too large for 32 bit
;	- includes ReadVal and WriteVal procedures for signed integers to convert string to integer and integer to string.
;	- includes getString and displayString macros that exclusively have ReadString and WriteString

INCLUDE Irvine32.inc

; **************** getString Macro *******************
;
; display a prompt, then get the user’s keyboard input into a memory location
;	Receives: memory location to store string
;	Returns:  store string in a memory location
;**************************************************
getString	MACRO memAddr
	pushad
	mov		edx, memAddr
	mov		ecx, 32
	call	ReadString
	mov		stringSize, eax
	popad
ENDM

; **************** displayString Macro *******************
;
; print the string which is stored in a specified memory location. 
;	Receives: memory location of string
;	Returns:  N/A
;**************************************************
displayString	MACRO memAddr
	pushad
	mov		edx, memAddr
	call	WriteString
	popad
ENDM

;Constants
	LO = 2147483648
	HI = 2147483647
	ARRAYSIZE = 10

.data
;Intro
	header1		BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/0 procedures", 0
	header2		BYTE	"Programmed by Long Mach", 0
	extra1		BYTE	"**EC1: Number each line of user input and display a running subtotal of the numbers.", 0
	
;User input
	intro1		BYTE	"Please provide 10 signed decimal integers", 0	
	intro2		BYTE	"Each number needs to be small enough to fit inside a 32 bit register", 0
	intro3		BYTE	"After you have finished inputting the raw numbers, I will display a list of integers, their sum and their average value.", 0	
	prompt		BYTE	"Please enter a signed number:", 0
	error		BYTE	"ERROR: You did not enter a signed number or your number was too big ", 0
	rePrompt	BYTE	"Please try again:", 0
	listMsg		BYTE	"You entered the following numbers: ", 0
	sumMsg		BYTE	"The sum of these numbers is: ", 0
	aveMsg		BYTE	"the rounded average is: ", 0
	comma		BYTE	", ", 0
	dot			BYTE	". ", 0
	subtotal	BYTE	"Running subtotal: ", 0

;farewell
	goodBye		BYTE	"Thank you for playing!", 0

;array
	listArray	DWORD	ARRAYSIZE	DUP(?)
	;sizeArray	DWORD	ARRAYSIZE	DUP(?)
	temp		DWORD	?
	counterInt	DWORD	?
	counterStr	DWORD	?

;string
	numberStr	BYTE	12 DUP(?)
	outStr		BYTE	12 DUP(?)
	stringSize	DWORD	?


;integer
	minus		DWORD	?
	sumInt		DWORD	?
	aveInt		DWORD	?
	subInt		DWORD	?

.code

main		PROC

	push	OFFSET intro3			;pass the strings by reference on the system stack		
	push	OFFSET intro2
	push	OFFSET intro1
	push	OFFSET extra1
	push	OFFSET header2
	push	OFFSET header1
	call	introduction			;introduce the program
	
	;array, temp, stringSize		;get the input and fill the array
	;push	OFFSET stringSize
	;push	OFFSET temp
	push	OFFSET listArray
	call	fillArray

	push	OFFSET listArray		;calculate and print the result
	call	result

	push	OFFSET goodBye
	call	farewell				;farewell to user
	exit

main		ENDP

; **************** INTRODUCTION *******************
;
; introduction
;	Displays an introduction to greet the user
;	Receives: N/A
;	Returns:  N/A
;**************************************************

introduction		PROC
;Introduction
	mov		eax, 2
	push	ebp
	mov		ebp, esp
intro:	
	mov		edx, [ebp + eax * 4]
	displayString	edx	
	call	CrLf
	inc		eax
	cmp		eax, 7
	jle		intro

	call	CrLf
	pop		ebp
	ret		28
introduction		ENDP

; *********************************************************************
;	Procedure to fill the array with 10 signed integers from user.
;	Receives: address of array, counterInt, temp, stringSize
;	Returns: fill listArray with input integer
;***********************************************************************
fillArray	PROC
	pushad
	mov		ebp, esp
	mov		edi, [ebp + 8]
	;mov		edi, OFFSET listArray		;@list
	mov		ecx, 10
	mov		counterInt, 1		
	mov		subInt, 0

fill:
	mov		esi, OFFSET counterInt		;number each line of user input
	mov		eax, [esi]
	mov		temp, eax
	call	WriteVal
	mov		edx, OFFSET dot
	displayString	edx

	mov		temp, 0
	call	readVal
	mov		eax, temp
	mov		[edi], eax					;fill in array
	add		edi, 4						;next element
	mov		eax, stringSize	

	mov		ebx, counterInt
	inc		ebx
	mov		counterInt, ebx

	mov		edx, OFFSET subtotal		;calculate running subtotal
	displayString	edx
	mov		eax, temp
	add		subInt, eax
	mov		esi, OFFSET subInt	
	mov		eax, [esi]
	mov		temp, eax
	call	WriteVal
	call	Crlf
	call	Crlf

	loop	fill

	call	calculation

	popad
	ret		4
fillArray	ENDP

; **************** readVal *******************
;
; invoke readString, validate and convert string to number
;	Receives: N/A
;	Returns:  N/A
;**************************************************
readVal			PROC
	pushad
	mov		ebp, esp

	mov		edx, OFFSET prompt		;prompt
	displayString	edx	

input:
	
	mov		edx, OFFSET numberStr
	getString		edx				;get the string
	
	mov		eax, stringSize

prepare:
	mov		esi, OFFSET numberStr	;set address
	mov		ecx, eax				;set counter for loop with size of string
	cmp		ecx, 11
	ja		notValid
	dec		ecx
	cld
	xor		edx, edx
	xor		eax, eax
	mov		minus, 0
	or		eax, 0				;clear overflow flag

firstDigit:
	lodsb
	cmp		al, 45				;check if first letter is '-'
	je		negative
	cmp		al, 43				;check if first letter is '+'
	je		positive
	cmp		al, 48				;'0' is character 48
	jb		notValid
	cmp		al, 57				;'9' is character 57
	ja		notValid	
	sub		al, 48
	;mov		ebx, HI				;set ebx as HI to validate the range
	add		edx, eax

	cmp		ecx, 0
	ja		secondDigit
	jmp		convert

negative:
	mov		minus, 1
	dec		stringSize
	jmp		secondDigit

positive:	
	mov		minus, 0
	dec		stringSize

secondDigit:
	imul	edx, 10
	jo		notValid			;invalid if the number overflow 32 bit register
	lodsb
	cmp		al, 48				;'0' is character 48
	jb		notValid
	cmp		al, 57				;'9' is character 57
	ja		notValid
	sub		al, 48

	add		edx, eax
	loop	secondDigit

convert:
	cmp		minus, 1
	je		negation
	jmp		noNeg

negation:	
	neg		edx

noNeg:
	mov		temp, edx			;save the number to temp	
	call	Crlf
	jmp		ending				

notValid:							
	mov		edx, OFFSET error
	displayString	edx
	call	Crlf
	mov		edx, OFFSET rePrompt
	displayString	edx
	jmp		input

ending:
	popad
	ret				
readVal				ENDP

; ***************************** Calculation *******************************
;
; Calculate the sum and average of the input numbers 
;	Receives: goodbye(reference)
;	Returns:  N/A
;***********************************************************************
calculation	PROC
	pushad
	mov		ebp, esp
	;mov		esi, [ebp + 8]
	mov		esi, OFFSET listArray
	mov		ecx, ARRAYSIZE
	mov		eax, 0

sum:								;calculate sum
	add		eax, [esi]
	add		esi, 4
	loop	sum
	mov		sumInt, eax
	
average:							;calculate average
	cdq
	mov		ebx, ARRAYSIZE
	idiv	ebx
	mov		aveInt, eax

	popad
	ret		
calculation	ENDP

; **************** writeVal *******************
;
; convert numeric value to string of digits
;	Receives: address of integers, of output string
;	Returns:  N/A
;**************************************************
writeVal	PROC
	pushad
	mov		ebp, esp
	
	mov		minus, 0
	mov		eax, temp
	mov		edi, OFFSET numberStr	
	mov		ecx, 0					;counter for loop
	cmp		eax, 0	
	jl		negative
	jmp		convert

negative:						;if the number is negative, make it positive and set minus as 1
	neg		eax
	mov		minus, 1

convert:
	mov		edx, 0
	mov		ebx, 10
	div		ebx
	mov		ebx, edx
	add		ebx, 48
	push	eax
	mov		eax, ebx
	stosb
	pop		eax
	inc		ecx
	cmp		eax, 0
	je		endConvert
	jmp		convert

endConvert:
	cmp		minus, 1			;if number is negative jmp to negate
	je		negate
	stosb
	jmp		finished

negate:
	mov		eax, '-'
	inc		ecx
	stosb
	mov		eax, 0
	stosb

finished:							;reverse the code
	mov		esi, OFFSET numberStr
	add		esi, ecx
	dec		esi
	mov		edi, OFFSET outStr

;**************************************************
; code borrowed from demo program #6
;**************************************************
reverse:
	std
	lodsb
	cld
	stosb
	loop	reverse

	mov		eax, 0
	stosb

	mov		edx, OFFSET outStr
	displayString	edx

	popad
	ret			
writeVal	ENDP


; **************** result *******************
;
; display the list of inputs, their sum and average
;	Receives: N/A
;	Returns:  N/A
;**************************************************
result	PROC
	pushad
	mov		ebp, esp
	
	mov		edx, OFFSET listMsg
	displayString	edx
	call	Crlf
	;mov		esi, [ebp + 8]
	mov		esi, OFFSET listArray	;input list's address
	mov		ecx, 10					;counter for loop
				
inputList:							;print the list
	mov		eax, [esi]
	mov		temp, eax
	call	WriteVal
	add		esi, 4
	cmp		ecx, 1
	je		sum
	mov		edx, OFFSET comma
	displayString	edx
	loop	inputList
	
sum:								;print the sum
	call	Crlf
	mov		edx, OFFSET sumMsg
	displayString	edx
	mov		esi, OFFSET sumInt
	mov		eax, [esi]
	mov		temp, eax
	call	WriteVal
	call	Crlf

average:							;print the average
	mov		edx, OFFSET aveMsg
	displayString	edx
	mov		esi, OFFSET aveInt
	mov		eax, [esi]
	mov		temp, eax
	call	WriteVal
	call	Crlf
	
	popad
	ret		4	
result	ENDP


; ***************************** FAREWELL *******************************
;
; farwell
;	Bids the user farewell.
;	Receives: goodbye(reference)
;	Returns:  N/A
;***********************************************************************
farewell	PROC
	call	CrLf
	call	CrLf
	push	ebp
	mov		ebp, esp

	mov		edx, [ebp + 8]
	displayString	edx	
	call	CrLf
	call	CrLf
	
	pop		ebp
	ret		4
farewell	ENDP

END main
