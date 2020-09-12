TITLE Designing low-level I/O procedures and Macros     (Project_6.asm)

; Author: Luwey Hon
; Description: This program ask the user for 10 numbers that
; must fit in the 32 bit register. It valides the numbers making
; sure a proper number is inserted. After inserted numbers, it will
; read it as a string and then convert it to a number and store it as
; an array. It then does calculation to find the sum and average.
; aftering finding the number values, it then calls write_val to
; store the numbers as a string. The write_val procedure will 
; be called 12 times. 10 for the array numbers and one each for
; the sum and average.

INCLUDE Irvine32.inc

; macro to display a string
display_string MACRO buffer
	push	edx
	mov		edx, buffer
	call	writestring
	pop		edx
ENDM

; macro to read the string
get_string MACRO var_name
	push	ecx
	push	edx
	mov		edx, var_name
	mov		ecx, 200
	call	ReadString
	pop		edx
	pop		ecx
ENDM

.data

enter_number	BYTE	"Please enter a signed number: ",0
nums_array		SDWORD	100 DUP(?)
user_input		SBYTE	100 DUP(?)
error_msg		BYTE	"ERROR: You entered a number too big or small or not a signed number ",0
string_buffer_1 	SDWORD	100 DUP(?)
string_buffer_2		SDWORD  100 DUP(?)
string_buffer_3		SDWORD  100 DUP(?)
negative_sign	SDWORD	45
some_num		SDWORD	49
str_spacing		BYTE	"   ",0
array_title		BYTE	"You entered the following numbers: ",0
total_sum		SDWORD	?
sum_title		BYTE	"The total sum is: ",0
average			SDWORD	?
avg_title		BYTE	"The average is: ",0
prog_title		BYTE	"Designing low-level I/O procedures               ",0
prog_author		BYTE	"                  by: Luwey Hon",0

.code
main PROC

; introduction
	push OFFSET prog_title
	push OFFSET prog_author
	call introduction

; reads as string and convert to number
	push OFFSET error_msg
	push OFFSET nums_array
	push OFFSET user_input
	push OFFSET enter_number
	call read_val

; calculates the sum
	push OFFSET total_sum
	push OFFSET nums_array
	call calculate_sum

; calculates the rounded average
	push total_sum
	push OFFSET average
	call calculate_avg

; display array in string. calls the sub-procedure write_val ten times for the ten numbers
	push OFFSET array_title
	push OFFSET	str_spacing
	push OFFSET negative_sign
	push OFFSET string_buffer_1
	push OFFSET nums_array
	call display_array

; display the total sum
	call CrLf
	call Crlf
	display_string OFFSET sum_title
	push OFFSET negative_sign
	push OFFSET string_buffer_2
	push OFFSET total_sum
	call write_val

;display rounded avaerage
	call CrlF
	call CrLf
	display_string OFFSET avg_title
	push OFFSET negative_sign
	push OFFSET string_buffer_3
	push OFFSET average
	call write_val
	call CrLf


	exit	; exit to operating system
main ENDP

; procedure for introduction
; recieves: offset of strings for heading
; returns: strings for heading
; preconditions:  none 
; registers changed: ebp, esp, edx
introduction PROC
	push	ebp
	mov		ebp, esp

	display_string [ebp + 12]		; @ prog_title
	display_string [ebp + 8]		; @ prog_author
	call	CrLf
	call	CrLf

	pop		ebp
	ret		8
introduction ENDP


; procedure to read as a string and convert to number
; recieves: OFFSETS for an array, number, and for two different strings print.
; returns: none, but it does save the numbers in an array
; preconditions: none
; registers changed: ebp, esp, eax, ebx, ecx, edx, esi, edi 
;----------------------------------------------------------------------------
; implementation note: It converts a string by reading backwards and
; adding the numbers together with multipliers depending on what digit it
; is. For example, 532 will be calculated by 2 * 1 + 3 * 10 + 5 * 100. 
; 2 is in the 1 digit, 3 is in the 10 digit, and 5 is in the 100 digits.
;----------------------------------------------------------------------------

read_val PROC
	push ebp
	mov ebp, esp
	mov	ecx, 10			; outter loop counters for how many digits
	mov eax, 0			; array pointer
	
; beginning of outter loop	
get_the_string:
	push ecx					; save outter loop counter
	push eax
	display_string	[ebp + 8]			; display string to enter number	
	get_string		[ebp + 12]		; save the string
	cmp eax, 11						
	ja invalid_char					; string length can't be > 11 with sign +/-

	mov esi, [ebp + 12]				; user's input
	add esi, eax					; to get last element	
	dec esi
	mov edi, [ebp + 16]				; the number array
	mov ecx, eax					; string length as inner loop counter
	mov edx, 1					; multiplier for how many digit of current number
	mov ebx, 0					; will hold the converted string number

	
; beginning of inner loop
read_the_string:
	std						; going backwards
	mov eax, 0					; to help stop overflow in future loops
	lodsb						; load the string byte
	cmp eax, 43					; ascii for +
	je positive_num
	cmp eax, 45					; ascii for -
	je negative_num

check_digits:
	cmp	eax, 48				    	; ascii for 0
	jl invalid_char
	cmp eax, 57					; ascii for 9
	ja invalid_char
	sub eax, 48

store_char:	
	push edx
	imul edx			; multiplier for digits
	pop edx
	add ebx, eax			; adds up each digit together
	jo invalid_char			; overflow = invalid number
	cmp ebx, 2147483647		; number is too big
	ja invalid_char
	
; increase multiplier by 10 for each digit
	mov eax, edx			; edx holds multiplier
	push ebx
	mov ebx, 10			; multiply by 10
	imul ebx
	pop ebx
	mov edx, eax		; new multipler back in edx. 
				; It goes 1, 10 , 100, 1000... for digit multiplier

	loop read_the_string	; end of beginning loop
	jmp fill_array
	
	negative_num:
	;cmp ebx, -2147483648		; for outlier case at minimum 32 bit sign value
	;je fill_array
	cmp ecx, 1			; ecx 1 checks the last reversed spot which is either a +/- or digit
	jne invalid_char		; if a - sign is found in wrong location
	neg ebx				; turn the number negative

	positive_num:
	cmp ecx, 1
	jne invalid_char		; if a + sign is found in wrong location
	dec ecx

fill_array:
	mov edi, [ebp + 16]		; the number array
	pop eax
	mov [edi + eax], ebx		; ebx holds the converted string number
	add eax, 4
	pop ecx				; restore outter loop counter
	dec ecx
	cmp ecx, 0
	je finished
	jmp get_the_string		; end of outter loop
	
invalid_char:
	;neg ebx
	;cmp ebx, -2147483648			; checking in case overflow read minimum sign value
	;je read_the_string
	pop eax					; allign stack
	pop ecx
	mov edx, 0
	display_string [ebp + 20]		; display error message
	call CrLF
	jmp get_the_string
	
finished:
	pop ebp
	ret 16

read_val ENDP

; procedure to caclualte the sum
; recieves: OFFSET of array of numbers and an empty variable to hold sum
; returns: none
; preconditions: none
; registers changed: ebp, esp, esi, edi, eax, ebx, ecx, edx
calculate_sum PROC
	push ebp
	mov ebp, esp
	mov esi, [ebp + 8]
	mov edi, [ebp + 12]
	mov ebx, 0				; array pointer
	mov edx, 0				; total count

	mov ecx, 10				; loop counter

; loops everytime to caclulate sum of array values
	calculate:
	mov eax, [esi + ebx]
	add edx, eax
	add ebx, 4
	loop calculate

	mov [edi], edx		; stores it in the variable

	pop ebp
	ret 8
calculate_sum ENDP

; procedure to calculate average
; recieves: OFFSET to hold average and total sum (value)
; returns: none
; preconditions: total sum has a value
; registers changed: ebp, esp, edi, esi, eax, ebx, edx
calculate_avg PROC
	push ebp
	mov ebp, esp
	mov edi, [ebp + 8]		; OFFSET of average variable

	; divide by 10 number
	mov eax, [ebp +12]		; total_sum
	cdq
	mov ebx, 10
	idiv ebx

	; store avg (pdf says it can round down)
	mov [edi], eax

	pop ebp
	ret 8
calculate_avg ENDP


; procedure to display array of numbers in string
; recieves: OFFSETs of array_title, str_spacing, negative_sign, empty string, array of numbers
; returns: a title and numbers in string
; preconditions: array has numbers
; registers changed: ebp, esp, esi, edi, esi, eax, ebx, ecx, edx
display_array PROC
	push ebp
	mov ebp, esp 
	mov esi, [ebp + 8]		; @ numbers array
	mov ecx, 10			; 10 numbers for counter
	mov edx, 0			; array pointer

	;prints the title
	call CrLf
	display_string [ebp + 24]
	call CrLf

	; loop to iterate through the array and print the number as string
	iterate_array:
	pushad
	push [ebp + 16]			; @ string to print negative sign
	push [ebp + 12]			; @ empty string to fill in the array
	push esi				
	call write_val			; sub-procedure to print number in strings
	popad
	add esi, 4
	display_string [ebp + 20]  ; prints the spacing between array

	loop iterate_array

	pop ebp
	ret 20

display_array ENDP

; procedure to convert the number to string
; recieves: OFFSET of some number, empty string, and a negative sign
; returns: the string number
; preconditions: must have a number in the offset of some number
; registers changed: ebp, esp, esi, edi, eax, ebx, ecx, edx
; -----------------------------------------------------------------
; implementation notes: 
; This is reused 12 times to convert the 10 array numbers, the
; average and the total sum.
;------------------------------------------------------------------
write_val PROC
	push ebp
	mov ebp, esp
	mov edi, [ebp + 12]		; @ stirng buffer to store
	mov ecx, 0			; array pointer
	mov esi, [ebp +8]		; @ some number
	mov eax, [esi]
	cmp eax, 0
	jnl check_positive		; if it is a positive number
	neg eax				; negate negative number to make it positive

check_negative:
	cdq
	mov ebx, 10
	idiv ebx				; dividing by 10
	add edx, 48				; convert remainder to ascii
	mov [edi + ecx], edx	; store it in array
	add ecx, 4				; point to next index
	cmp eax, 0				; when you cant divide anymore. stop loop
	je	finish_neg
	jmp	check_negative

check_positive:
	cdq
	mov ebx, 10
	idiv ebx				; dividing by 10
	add edx, 48				; convert reminader to ascii
	mov [edi + ecx], edx			; store it in array
	add ecx, 4				; point to next index
	cmp eax, 0				; when you cant divide anymore. stop loop
	je	finish_pos			
	jmp	check_positive

finish_neg:
display_string [ebp + 16]		; ascii for negative sign printed

finish_pos:

; reads the array backwards and display as string
	add edi, ecx			; points to last element
	check_num:
	sub edi, 4			; to read backwards
	display_string edi		; macro to display string
	sub ecx, 3			; allign DWORD loop
	loop check_num

	pop ebp
	ret 12
write_val ENDP


END main
