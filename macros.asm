; ============================================
; GENERIC CONSTANTS
; ============================================

%define	SYS_EXIT	1
%define	SYS_READ	3
%define	SYS_WRITE	4

%define STDIN		0
%define STDOUT		1


; ============================================
; PREDEFINED TYPES
; <type> <name>[, <array_length>]
; ============================================

; char/byte
%macro char 2
	%1 resb %2
%endmacro
%macro char 1
	char %1, 1
%endmacro

; short/word
%macro short 2
	%1 resw %2
%endmacro
%macro short 1
	short %1, 1
%endmacro

; long/dword
%macro long 2
	%1 resd %2
%endmacro
%macro long 1
	long %1, 1
%endmacro

; long_long/qword
%macro long_long 2
	%1 resq %2
%endmacro
%macro long_long 1
	long_long %1, 1
%endmacro

; string (declare only)
%macro string 2+
	%1: db %2, 0
%endmacro


; ============================================
; GENERIC MACROS
; ============================================

; Clear a register
;>clear reg
%macro clear 1
	xor %1, %1
%endmacro
%macro clear 2-*
	%rep %0
		clear %1
		%rotate 1
	%endrep
%endmacro

; Call the Linux kernel
;>ck
%macro ck 0
	int 0x80
%endmacro

; Exit program with code
;>exit int code
%macro exit 1
	mov rax, 1
	mov rbx, %1
	ck
%endmacro

; Exit program with code 0
;>exit
%macro exit 0
	exit 0
%endmacro

; Push 64-bit abcd regs
;>pushad
%macro pushad 0
	push rax
	push rbx
	push rcx
	push rdx
%endmacro

; Pop 64-bit abcd regs
;>popad
%macro popad 0
	pop rdx
	pop rcx
	pop rbx
	pop rax
%endmacro


; ============================================
; I/O MACROS
; ============================================

; Get data from STDIN
;>scan byte* buffer, int size
%macro scan 2
	%%begin:
		pushad
		
		mov rax, SYS_READ
		mov rbx, STDIN
		mov rcx, %1
		mov rdx, %2
		ck

		; remove all (cr)lf
		add rcx, rdx ; rcx = buffer + size

	%%loopbeg:
		dec rcx ; go back

		cmp byte [rcx], 10 ; if lf
		jz %%remove

		cmp byte [rcx], 13 ; if cr
		jz %%remove

		jmp %%loopend ; else, skip

	%%remove:
		mov byte [rcx], 0

	%%loopend:
		cmp rcx, %1
		jnz %%loopbeg

	%%end:
		popad
%endmacro

; Print string of a defined length
;>print byte* str, int size
%macro printl 2
	pushad
	mov rax, 4
	mov rbx, 1
	mov rdx, %2
	mov rcx, %1
	ck
	popad
%endmacro

; Print string until \0 character
;>print byte* str
%macro print 1
	%%begin:
		pushad
		mov rdx, %1

	%%loop:
		cmp byte [rdx], 0
		jz %%end

		inc rdx
		jmp %%loop

	%%end:
		sub rdx, %1
		printl %1, rdx
		popad
%endmacro

; Print all strings (WILL WORK)
;>print byte* str[, byte* str...]
%macro print 2-*
	%rep %0
		print %1
		%rotate 1
	%endrep
%endmacro


; ============================================
; STRING MANIPULATION MACROS
; ============================================

; Clear n bytes of string str
;>clear_string str, n
%macro clear_string 2
	%%begin:
		pushad

		mov rcx, %1
		add rcx, %2

	%%loop:
		dec rcx
		mov byte [rcx], 0

		cmp rcx, %1
		jz %%end
		jmp %%loop

	%%end:
		popad
%endmacro

; Adjust string
;>adjust_string byte* str, int size
%macro adjust_string 2
	%%begin:
		pushad
		clear rdi, rsi

		mov rdi, %1
		mov rsi, rdi

	%%loop:
		cmp byte [rsi], 0
		jz %%endloop
		cmp rsi, rdi
		jz %%endloop

		mov byte dl, [rsi]
		mov byte [rdi], dl
		mov byte [rsi], 0

	%%endloop:
		; move rsi
		inc rsi
		cmp rsi, %1+%2
		jz %%end

		; move rdi if non-null
		cmp byte [rdi], 0
		jz %%loop
		inc rdi
		jmp %%loop

	%%end:
		popad
%endmacro


; ============================================
; CONVERSION MACROS
; ============================================

; Convert long to string
;>long_to_string dword* num, byte* str
%macro long_to_string 2
	%%begin:
		pushad

		mov eax, [%1] ; the number
		mov ebx, 10 ; divisor
		mov ecx, 10 ; string cursor, 10-digits for dwords

	%%loop:
		dec ecx ; adjust cursor

		clear edx
		div ebx ; divide

		add dl, '0' ; adjust to ascii
		mov [%2+ecx], dl ; remain

		; looping!
		cmp eax, 0
		jnz %%loop

	%%end:
		popad
		adjust_string %2, 10
%endmacro

; Convert long_long to string
;>long_long_to_string qword* num, byte* str
%macro long_long_to_string 2
	%%begin:
		pushad

		mov rax, [%1] ; the number
		mov rbx, 10 ; divisor
		mov rcx, 20 ; string cursor, 20-digits for qwords

	%%loop:
		dec rcx ; adjust cursor

		clear rdx
		div rbx ; divide

		add dl, '0' ; adjust to ascii
		mov [%2+rcx], dl ; remain

		; looping!
		cmp rax, 0
		jnz %%loop

	%%end:
		popad
		adjust_string %2, 20
%endmacro

; Convert long_long to hex string
;>long_long_to_hexstring qword* num, byte* str
%macro long_long_to_hexstring 2
	%%begin:
		pushad

		mov rax, [%1] ; the number
		mov rbx, 0x10 ; divisor
		mov rcx, 20 ; string cursor, 20-digits for qwords

	%%loop:
		dec rcx ; adjust cursor

		clear rdx
		div rbx ; divide

		add dl, '0' ; adjust to ascii

		cmp dl, '9'
		ja %%hexadjust ; if dl > '9'
		jmp %%move ; else

	%%hexadjust:
		add dl, 7

	%%move:
		mov [%2+rcx], dl ; remain

		; looping!
		cmp rax, 0
		jnz %%loop

	%%end:
		dec rcx
		mov byte [%2+rcx], 'x'

		dec rcx
		mov byte [%2+rcx], '0'

		popad
%endmacro

; Convert string to long
;>string_to_long_long byte* str, dword* num
%macro string_to_long 2
	%%begin:
		pushad

		clear eax ; int number
		mov ebx, 10 ; multiplier
		mov ecx, %1 ; cursor = str
		clear edx ; char

	%%loop: ; find null character
		cmp byte [ecx], 0 ; if *ecx == 0
		jz %%end

		mul ebx ; make space
		clear edx

		mov dl, [rcx] ; move next char
		sub dl, '0' ; adjust char
		add eax, edx ; send to int

		inc ecx ; move cursor
		jmp %%loop ; go back

	%%end:
		mov [%2], eax

		popad
%endmacro

; Convert string to long_long
;>string_to_long_long byte* str, qword* num
%macro string_to_long_long 2
	%%begin:
		pushad

		clear rax ; int number
		mov rbx, 10 ; multiplier
		mov rcx, %1 ; cursor = str
		clear rdx ; char

	%%loop: ; find null character
		cmp byte [rcx], 0 ; if *rcx == 0
		jz %%end

		mul rbx ; make space
		clear rdx

		mov dl, [rcx] ; move next char
		sub dl, '0' ; adjust char
		add rax, rdx ; send to int

		inc rcx ; move cursor
		jmp %%loop ; go back

	%%end:
		mov [%2], rax

		popad
%endmacro