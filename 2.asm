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
    mov  rdx, rsi    ; len     
    mov  rsi, rdi    ; buff
    mov  rdi, 1      ; stdout
    mov  rax, 1      ; syswrite
    syscall

    pop  rbp
    ret
    
; rdi: num (unsigned, 64-bit)
print_num:
    push rbp
    mov  rbp, rsp
    sub  rsp, 16            ; local storage for the digit byte

    ; --- special case: 0 ---
    test rdi, rdi
    jnz  .divide_loop   ; jump if test not zero
    mov  byte [rsp], '0'
    mov  rax, 1             ; sys_write
    mov  rdi, 1             ; stdout
    lea  rsi, [rsp]         ; load address of rsp into rsi
    mov  rdx, 1
    syscall
    jmp  .done

    ; --- phase 1: push digits onto the stack (reversed) ---
.divide_loop:
    mov  rax, rdi           ; number to divide
    xor  r8, r8             ; digit count

.push_digits:
    test rax, rax
    jz   .pop_digits    ; jump if test zero
    xor  rdx, rdx
    mov  rcx, 10
    div  rcx                ; rdx = rax % 10, rax = rax / 10
    add  rdx, '0'           ; ASCII
    push rdx                ; push the digit byte (8 bytes, but only low byte matters)
    inc  r8
    jmp  .push_digits

    ; --- phase 2: pop and write each digit ---
.pop_digits:
    test r8, r8
    jz   .done
    pop  rdx                ; rdx = digit in low byte
    mov  [rsp], dl          ; store to local scratch
    mov  rax, 1
    mov  rdi, 1
    lea  rsi, [rsp]
    mov  rdx, 1
    syscall
    dec  r8
    jmp  .pop_digits

.done:
    add  rsp, 16    ; pop what we pushed
    pop  rbp
    ret


; rdi: first num
; rsi: second num
; rax: return value (sum)
sum_two_nums:
    push rbp
    mov  rbp, rsp

    mov  rax, rdi
    add  rax, rsi

    pop  rbp
    ret
    

exit_program:
    mov  rax, 60            ; sys_exit
    mov  rdi, 0             ; exit code: 0 (success)
    syscall

_start:
    push  rbp
    mov   rbp, rsp

    mov  rdi, hello_wrld
    mov  rsi, hello_wrld_len
    call print_str

    mov  rdi, 10
    mov  rsi, 5
    call sum_two_nums
    ; rax has sum
    
    mov rdi, rax
    call print_num

    call exit_program



