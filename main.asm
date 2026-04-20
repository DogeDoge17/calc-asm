section .data
    readMessage db "n: "
    %define len 3

section .text

global _start

_start:
    sub rsp, 64 ; stdin buffer
    lea r12, [rsp]

    ; poll the number from the usr
    call _getNumber
    mov r13, rax
    call _getNumber

    ; ADD THE NUMERB
    add rax, r13

    ; convert ts to a string
    lea rdi, [rsp + 63]
    call _itos

    ; print tha numba
    mov rax, 1
    mov rdi, 1
    syscall

    mov eax, 1          ; sys_exit
    xor rbx, rbx
    int 0x80

; polls the user w stdin
_getNumber:
    ; print the prompt
    mov eax, 4           ; sys_write
    mov ebx, 1           ; file descriptor (stdout)
    mov ecx, readMessage ; pointer to message
    mov edx, len         ; message length
    int 0x80             ; call kernel        

    ; read from stdin
    mov rax, 0              ; sys_read
    mov rdi, 0              ; stdin file descriptor
    mov rsi, r12         ; address to store data
    mov rdx, 64             ; max bytes to read
    syscall

    mov rbx, rax
    mov rsi, r12
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
    je .end

    mov dl, [rsi+rcx] ; the ascii number 

    ; make sure its a numebr
    cmp dl, '0'
    jb .continue
    cmp dl, '9'
    ja .continue

    sub dl, '0'
    imul rax, 10
    add rax, rdx

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

; rdi: the buffer to write to
; rax: the integer to convert to
_itos:
    mov rcx, 2
    mov r10, 10
    xor r11, r11

    mov byte [rdi], 10 ; append newline
    dec rdi

    cmp rax, 0
    jge .loop
    neg rax
    mov r11, 1

  .loop:
    ; prepare new digit 
    xor rdx, rdx
    idiv r10
    add rdx, '0'

    mov [rdi], dl
    
    dec rdi
    inc rcx

    ; do while for x+y=0
    test rax, rax
    jz .end

    jmp .loop
  .end:
    test r11, r11 
    jz .realEnd
    mov byte [rdi], '-'
    dec rdi
    inc rcx
  .realEnd: 

    mov rsi, rdi
    mov rdx, rcx
    ret
