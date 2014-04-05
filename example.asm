; ===========================
; EXAMPLE OF LIBNASM
; ===========================


%include "macros.asm"


segment .data
	string prompt1, "Please enter a number: "
	string prompt2, "Please enter another number: "
	string answer, "The sum of these numbers is "
	string endl, 10 ; character 10, aka line-break or \n


segment .bss
	char number, 11 ; char array of 11 characters, reused for everything
					; long values take up to 10 characters, plus one for the line-break

	long number1 ; long = dword
	long number2


segment .text
	global main

	main:
		; input 1
		print prompt1					; prompt
		scan number, 10					; read input
		string_to_long number, number1	; convert
		clear_string number, 11			; clear

		; input 1
		print prompt2					; prompt
		scan number, 10					; read input
		string_to_long number, number2	; convert
		clear_string number, 11			; clear

		; operations (using 64-bit registers here)
		mov rax, [number1]
		mov rbx, [number2]
		add rax, rbx
		mov [number1], rax

		; convert to ascii again
		long_to_string number1, number

		; answer
		print answer, number, endl

		exit


; NOTE :
;	- print autodetects the length of the string to print as long as it ends with a null (\0) character
;	- printl prints whatever length is specified