


section .data
    ; Newline character for output
    newline        db  0x0a

    hello_wrld     db  "Hello World", 0x0a
    hello_wrld_len equ $ - hello_wrld


section .bss



section .text
    global _start


; rdi: buffer ptr
; rsi: buffer len
print_str:
    push rbp
    mov  rbp, rsp
       
    ; sys_write: rax (sys call no) = 1, rdi (fd, stdout = 1) = 1, rsi = buf, rdx = len
    mov rdx, rsi    ; len     
    mov rsi, rdi    ; buff
    mov rdi, 1      ; stdout
    mov rax, 1      ; syswrite
    syscall

    pop rbp
    ret

exit_program:
    mov  rax, 60            ; sys_exit
    mov  rdi, 0             ; exit code: 0 (success)
    syscall                 ; goodbye!

_start:
    push rbp
    mov  rbp, rsp

    mov rdi, hello_wrld
    mov rsi, hello_wrld_len
    call print_str

    call exit_program



