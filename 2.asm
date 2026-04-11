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
    push    rbp
    mov     rbp, rsp

    ; sys_write: rax (sys call no) = 1, rdi (fd, stdout = 1) = 1, rsi = buf, rdx = len
    mov     rdx, rsi    ; len
    mov     rsi, rdi    ; buff
    mov     rdi, 1      ; stdout
    mov     rax, 1      ; syswrite
    syscall

    pop     rbp
    ret

; rdi: num (unsigned, 64-bit)
print_num:
    push    rbp
    mov     rbp, rsp

    ; 303
    ; 303 % 10 = 3
    ; 303 / 10 = 30

.loop:
    mov     rax, rdi    ; dividend (low 64 bits)
    xor     rdx, rdx    ; dividend (high 64 bits) = 0, MUST clear this
    mov     rsi, 10     ; divisor
    div     rsi         ; rax = rax / 10, rdx = rax % 10

    test    rax, rax
    jnz     .loop       ; why it's a loop label if we manually have to call it everytime?
                        ; shouldn't this be the exit statement?




; rdi: first num
; rsi: second num
; rax: return value (sum)
sum_two_nums:
    push    rbp
    mov     rbp, rsp

    mov     rax, rdi
    add     rax, rsi

    pop     rbp
    ret



_start:
    push    rbp
    mov     rbp, rsp

    mov     rdi, hello_wrld
    mov     rsi, hello_wrld_len
    call    print_str

    mov     rdi, 10
    mov     rsi, 5
    call    sum_two_nums
    ; rax has sum
    
    mov     rdi, rax
    call    print_num


; called automatically
exit_program:
    mov     rax, 60            ; sys_exit
    mov     rdi, 0             ; exit code: 0 (success)
    syscall



