section          .data
readMessage      db "n: "
operationMessage db "o: "
%define          len 3

section .text

global _start

_start:
	;   stdin buffer
	sub rsp, 64
	mov r12, rsp

	;    ask for the first number
	call _getNumber
	mov  r13, rax

	;    ask for the operation
	call _getOperation
	mov  r14, rax

.secondNumber:
	;    ask for the second number
	call _getNumber

	;    calculate THE NUMERB
	call r14

	;    convert ts to a string
	lea  rdi, [rsp + 63]
	call _itos

	;   print tha numba
	mov rax, 1
	mov rdi, 1
	syscall

	mov eax, 1; sys_exit
	xor ebx, ebx
	int 0x80

_getOperation:
	mov  r8, operationMessage; pointer to message
	mov  r9, 2; max bytes to read
	call _input

	mov r8b, [rsi]

	cmp r8b, '+'
	mov rax, _add
	je  .found

	cmp r8b, '-'
	mov rax, _sub
	je  .found

	cmp r8b, '*'
	mov rax, _mul
	je  .found

	cmp r8b, '/'
	jne _getOperation
	mov rax, _div

.found:
	ret

	; polls the user w stdin

_getNumber:

	mov  r8, readMessage; pointer to message
	mov  r9, 64; max bytes to read
	call _input

	mov  rbx, rax
	mov  rsi, r12
	call _readNum

	ret

	; rsi -- input string
	; rbx -- string length

_readNum:
	xor rax, rax
	xor rcx, rcx
	xor rdx, rdx

.loop:
	cmp rcx, rbx
	je  .end

	mov dl, [rsi+rcx]; the ascii number

	;   make sure its a numebr
	cmp dl, '0'
	jb  .continue
	cmp dl, '9'
	ja  .continue

	sub  dl, '0'
	imul rax, 10
	add  rax, rdx

.continue:
	inc rcx
	jmp .loop

.end:
	cmp byte [rsi], '-'
	jne .realend
	neg rax

.realend:
	xor rdx, rdx
	ret

	; r8d: the print prompt
	; r9: the amount to read back

_input:
	;   print the prompt
	mov eax, 4; sys_write
	mov ebx, 1; file descriptor (stdout)
	mov rcx, r8; pointer to message
	mov edx, len; message length
	int 0x80; call kernel

	;   read from stdin
	mov rax, 0; sys_read
	mov rdi, 0; stdin file descriptor
	mov rsi, r12; address to store data
	mov rdx, r9; max bytes to read
	syscall

	ret

	; rdi: the buffer to write to
	; rax: the integer to convert

_itos:
	mov rcx, 2
	mov r10, 10
	xor r11, r11

	mov byte [rdi], 10; append newline
	dec rdi

	cmp rax, 0
	jge .loop
	neg rax
	mov r11, 1

.loop:
	;    prepare new digit
	xor  rdx, rdx
	idiv r10
	add  rdx, '0'

	mov [rdi], dl

	dec rdi
	inc rcx

	;    do while for x+y=0
	test rax, rax
	jnz  .loop

.end:
	test r11, r11
	jz   .realEnd
	mov  byte [rdi], '-'
	dec  rdi
	inc  rcx

.realEnd:

	mov rsi, rdi
	mov rdx, rcx
	ret

_mul:
	imul r13

	ret

_div:
	test rax, rax
	jnz  .ok
	pop  rax
	jmp  _start.secondNumber

.ok:
	xchg r13, rax
	cqo
	idiv r13

	ret

_add:
	add rax, r13
	ret

_sub:
	xchg r13, rax
	sub  rax, r13
	ret
