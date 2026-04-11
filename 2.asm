section .data
    ; Newline character for output
    newline        db  10

    hello_wrld     db  "Hello World", 10
    hello_wrld_len equ $ - hello_wrld

    minus_sign  db  '-'


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


; rdi: num
print_num:
    push    rbp
    mov     rbp, rsp

    ; test does AND sets sign flag
    test    rdi, rdi        ; rdi AND rdi = rdi, but SF was set
    jns     .positive       ; jump if not signed (positive or zero)

    ; negative path
    push    rdi             ; save original value
    mov     rdi, minus_sign ; print '-'
    mov     rsi, 1
    call    print_str
    pop     rdi             ; restore original value
    neg     rdi             ; negate: e.g. -42 becomes 42

.positive:
    ; store the address where first digit will be pushed
    lea     rcx, [rsp]

    ; in 64bit, div divides 128 bit number [rdx | rax]
    ; answer is in rax, remainer in rdx
    mov     rax, rdi    ; dividend (low 64 bits)
    mov     rsi, 10     ; divisor
.div_loop:
    xor     rdx, rdx    ; dividend (high 64 bits) = 0, MUST clear this
    div     rsi         ; rax = rax / 10, rdx = rax % 10

    ; pushing digits onto stack in reverse order
    add     rdx, '0'    ; rdx has num 0-9, convert to ascii
    push    rdx

    ; continue loop
    test    rax, rax
    jnz     .div_loop

    ; div loop ended
    ; now to print the ascii digits

    mov     rdi, rsp            ; buffer ptr
    mov     rsi, rcx            ; old rsp
    sub     rsi, rdi            ; length = bytes pushed
    call    print_str

    mov     rsp, rbp
    pop     rbp
    ret


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

    mov     rdi, hello_wrld
    mov     rsi, hello_wrld_len
    call    print_str

    mov     rdi, -1000
    mov     rsi, 4
    call    sum_two_nums
    ; rax has sum
    
    mov     rdi, rax
    call    print_num
    mov     rdi, newline
    mov     rsi, 1
    call    print_str


; called automatically
exit_program:
    mov     rax, 60            ; sys_exit
    mov     rdi, 0             ; exit code: 0 (success)
    syscall



