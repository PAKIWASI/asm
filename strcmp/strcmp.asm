section .data
    ; db: define byte
    newline db 0x0a 

    msg_1 db "please enter first string: ", 0x0a, 0 ; newline + null terminated
    msg_1_len equ $ - msg_1

    msg_2 db "please enter second string: ", 0x0a, 0
    msg_2_len equ $ - msg_2



section .bss
    str_1 resb 256  ; resb: reserve byte
    str_2 resb 256



section .text
    global _start


; rdi: buffer ptr
; rsi: buffer len
print_str:
    push rbp
    mov  rbp, rsp
       
    ; sys_write: rax (sys call no) = 1, rdi (fd, stdout = 1) = 1, rsi = buf, rdx = len
    mov  rdx, rsi    ; len     
    mov  rsi, rdi    ; buff
    mov  rdi, 1      ; stdout
    mov  rax, 1      ; syswrite
    syscall

    pop  rbp
    ret



; rdi: buffer ptr
read_str:
    push rbp
    mov rbp, rsp

    mov rsi, rdi
    mov rdx, 255    ; buffer len
    mov rdi, 0      ; stdin
    mov rax, 0      ; read syscall
    syscall

    ; rax contains number of bytes read (or -1 for error)
    ; add null term to that postition
    ; buffer ptr was moved to rsi
    mov byte [rsi + rax], 0   ; add nullterm

    pop rbp
    ret



_start:
    push rbp    
    mov rbp, rsp


    mov rdi, msg_1
    mov rsi, msg_1_len
    call print_str

    mov rdi, str_1
    call read_str


    mov rdi, msg_2
    mov rsi, msg_2_len
    call print_str

    mov rdi, str_2
    call read_str


    mov rdi, str_1
    mov rsi, 256
    call print_str
    
    mov rdi, str_2
    mov rsi, 256
    call print_str



; this runs automatically
program_end:
    mov rax, 60     ; exit syscall
    mov rdi, 0      ; normal exit
    syscall


