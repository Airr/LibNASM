; ===========================
; EXAMPLE OF LIBNASM
; ===========================


%include "../LibNASM/macros.asm"


segment .data
	string prompt1, "Please enter a number: "
	string prompt2, "Please enter another number: "
	string answerdec, "The decimal sum of these numbers is "
	string answerhex, "The hexadecimal sum of these numbers is "

	string endl, 10


segment .bss
	char input1, 20 ; char array of 20 characters
	char input2, 20
	char outputdec, 20
	char outputhex, 20

	long_long num1 ; qword
	long_long num2


segment .text
	global main

	main:
		; input 2
		print prompt1
		scan input1, 19

		; input 1
		print prompt2
		scan input2, 19

		; conversion
		string_to_long_long input1, num1
		string_to_long_long input2, num2

		; operations
		mov rax, [num1]
		mov rbx, [num2]
		add rax, rbx
		mov [num1], rax

		; reconversion
		long_long_to_string num1, outputdec
		long_long_to_hexstring num1, outputhex

		; dec answer
		print answerdec
		printl outputdec, 20

		; hex answer
		print endl, answerhex
		printl outputhex, 20

		print endl

		exit


; NOTE :
;	- print autodetects the length of the string to print as long as it ends with a null (\0) characters
;	- printl prints whatever length is specified