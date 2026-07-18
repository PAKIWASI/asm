; =============================================================================
; x86-64 NASM COMPLETE TUTORIAL
; Covers: MOV, PUSH, POP, CALL, RET, Stack frames, Calling Convention
; Target: Linux x86-64 (System V AMD64 ABI)
; Assemble: nasm -f elf64 tutorial.asm -o tutorial.o
; Link:     ld tutorial.o -o tutorial
; Run:      ./tutorial
; =============================================================================


; =============================================================================
; THEORY: MEMORY & REGISTERS OVERVIEW
; =============================================================================
;
;  Registers are tiny storage slots INSIDE the CPU — fastest memory possible.
;  Main general-purpose registers (64-bit):
;
;    rax, rbx, rcx, rdx   — general purpose
;    rsi, rdi              — source/destination index (also arg registers)
;    rsp                   — Stack Pointer  → always points to TOP of stack
;    rbp                   — Base Pointer   → anchors a stack frame
;    r8  – r15             — extra general-purpose registers
;
;  Each 64-bit register has smaller "views" into it:
;
;    rax  (64-bit)
;    eax  (lower 32 bits)
;     ax  (lower 16 bits)
;     ah  (bits 8–15)
;     al  (bits 0–7)
;
; =============================================================================


; =============================================================================
; THEORY: THE STACK
; =============================================================================
;
;  The stack is a region of memory that works LIFO (Last In, First Out).
;  It GROWS DOWNWARD — toward lower addresses.
;
;  RSP always points to the CURRENT TOP of the stack (lowest used address).
;
;  Memory layout (simplified):
;
;    High addresses  ┌─────────────────┐
;                    │   environment   │
;                    │   command args  │
;                    ├─────────────────┤
;                    │                 │  ← stack starts here
;                    │   stack grows   │
;                    │      ↓          │
;                    │                 │
;                    │   (unused)      │
;                    │                 │
;                    │      ↑          │
;                    │   heap grows    │
;                    ├─────────────────┤
;                    │   .bss          │  (uninitialised data)
;                    │   .data         │  (initialised data)
;                    │   .text         │  (code)
;    Low addresses   └─────────────────┘
;
; =============================================================================


; =============================================================================
; THEORY: MOV INSTRUCTION
; =============================================================================
;
;  MOV is the most common instruction. It copies a value from src to dst.
;  It does NOT "move" — it COPIES. The source is unchanged.
;
;  Syntax:   mov  destination, source
;
;  Valid forms:
;    mov rax, 42          ; load immediate value into register
;    mov rax, rbx         ; copy register to register
;    mov rax, [rbx]       ; load from memory address stored in rbx
;    mov [rbx], rax       ; store rax into memory at address rbx
;    mov [var], rax       ; store rax into a named memory location
;
;  Rules:
;    - Both operands must be the same size
;    - You CANNOT mov memory → memory directly (need a register in between)
;    - Immediate values cannot be 64-bit in most forms (use movabs for that)
;
; =============================================================================


; =============================================================================
; THEORY: PUSH & POP
; =============================================================================
;
;  PUSH  — decrements RSP by 8 (on 64-bit), then writes value to [RSP]
;
;    push rax
;    ; is exactly equivalent to:
;    sub rsp, 8
;    mov [rsp], rax     ; rsp points to an address, mov val in rax into that address
;
;  POP   — reads value from [RSP], then increments RSP by 8
;
;    pop rbx
;    ; is exactly equivalent to:
;    mov rbx, [rsp]
;    add rsp, 8
;
;  Visual example — pushing 3 values:
;
;    Initial RSP = 0x7fff0030
;
;    push 10        RSP → 0x7fff0028   [0x7fff0028] = 10
;    push 20        RSP → 0x7fff0020   [0x7fff0020] = 20
;    push 30        RSP → 0x7fff0018   [0x7fff0018] = 30
;
;    pop rbx        rbx = 30,  RSP → 0x7fff0020
;    pop rcx        rcx = 20,  RSP → 0x7fff0028
;    pop rdx        rdx = 10,  RSP → 0x7fff0030  (back to original)
;
;  IMPORTANT: Every PUSH must have a matching POP before returning,
;  otherwise RSP is wrong and your RET will jump to garbage.
;
; =============================================================================


; =============================================================================
; THEORY: CALL & RET
; =============================================================================
;
;  CALL label
;    1. Pushes the return address (address of the NEXT instruction) onto stack
;    2. Jumps to label
;
;    call foo
;    ; equivalent to:
;    push  <address of instruction after call>
;    jmp   foo
;
;  RET
;    1. Pops the return address from the stack
;    2. Jumps to it
;
;    ret
;    ; equivalent to:
;    pop   rip        ; (rip = instruction pointer, not directly writable)
;
;  This is why RSP must be EXACTLY the same value at RET as it was
;  when CALL happened — RET blindly pops whatever is at [RSP].
;  If you pushed extra stuff and didn't clean it up, RET reads garbage.
;
; =============================================================================


; =============================================================================
; THEORY: STACK FRAMES & RBP
; =============================================================================
;
;  A "stack frame" is the region of stack a function owns.
;  RBP (Base Pointer) acts as a stable reference point inside a frame.
;
;  Standard prologue (function entry):
;    push rbp          ; save caller's base pointer
;    mov  rbp, rsp     ; RBP now points to our frame base
;    sub  rsp, N       ; allocate N bytes of local variable space
;
;  Standard epilogue (function exit):
;    mov  rsp, rbp     ; restore RSP (discards local variables)
;    pop  rbp          ; restore caller's RBP
;    ret               ; pop return address and jump back
;
;  With RBP set, locals are at negative offsets: [rbp - 8], [rbp - 16], ...
;  Caller's args (if any were on stack) are at positive offsets: [rbp + 16], ...
;
;  Stack layout during a function call:
;
;    Higher addresses
;    ┌─────────────────┐
;    │  caller's frame │
;    ├─────────────────┤  ← caller's RSP before CALL
;    │  return address │  ← CALL pushed this (8 bytes)
;    ├─────────────────┤  ← our RBP points here (after push rbp + mov rbp,rsp)
;    │  saved old RBP  │  ← we pushed this
;    ├─────────────────┤
;    │  local var 1    │  [rbp -  8]
;    │  local var 2    │  [rbp - 16]
;    │  ...            │
;    ├─────────────────┤  ← RSP (after sub rsp, N)
;    Lower addresses
;
; =============================================================================


; =============================================================================
; THEORY: SYSTEM V AMD64 CALLING CONVENTION (Linux)
; =============================================================================
;
;  Arguments (integer/pointer) passed in registers, in this order:
;    1st: rdi
;    2nd: rsi
;    3rd: rdx
;    4th: rcx
;    5th: r8
;    6th: r9
;    7th+: pushed on stack (right to left), caller cleans up
;
;  Return value:  rax  (and rdx for 128-bit)
;
;  Caller-saved (volatile) — callee may freely destroy these:
;    rax, rcx, rdx, rdi, rsi, r8, r9, r10, r11
;
;  Callee-saved (non-volatile) — callee MUST preserve these:
;    rbx, rbp, r12, r13, r14, r15
;
;  Stack alignment:
;    RSP must be 16-byte aligned BEFORE a CALL instruction.
;    (The CALL itself pushes 8 bytes, making RSP misaligned by 8 inside
;     the callee — the prologue's "push rbp" fixes that back to 16.)
;
; =============================================================================


; =============================================================================
; DATA SECTION — initialised data lives here
; =============================================================================
section .data

    ; Newline character for output
    newline     db  0x0a

    ; Labels for each section of the tutorial output
    hdr_mov     db  "=== MOV DEMO ===", 0x0a
    hdr_mov_len equ $ - hdr_mov

    hdr_push    db  "=== PUSH/POP DEMO ===", 0x0a
    hdr_push_len equ $ - hdr_push

    hdr_call    db  "=== CALL/RET DEMO ===", 0x0a
    hdr_call_len equ $ - hdr_call

    hdr_conv    db  "=== CALLING CONVENTION DEMO ===", 0x0a
    hdr_conv_len equ $ - hdr_conv

    hdr_frame   db  "=== STACK FRAME DEMO ===", 0x0a
    hdr_frame_len equ $ - hdr_frame

    ; Result strings (we print single digits for simplicity)
    msg_rax     db  "rax holds: "
    msg_rax_len equ $ - msg_rax

    msg_add     db  "add(4, 7)  = "
    msg_add_len equ $ - msg_add

    msg_mul     db  "mul(3, 6)  = "
    msg_mul_len equ $ - msg_mul

    msg_sum3    db  "sum3(1,2,3)= "
    msg_sum3_len equ $ - msg_sum3

    msg_nested  db  "nested()   = "
    msg_nested_len equ $ - msg_nested

    msg_local   db  "local vars result: "
    msg_local_len equ $ - msg_local


; =============================================================================
; BSS SECTION — uninitialised (zeroed) data
; =============================================================================
section .bss
    ; A buffer to convert a number to its ASCII digit character
    digit_buf   resb 1  ; reserve a byte


; =============================================================================
; TEXT SECTION — executable code lives here
; =============================================================================
section .text
    global _start


; =============================================================================
; HELPER: print_string
;   Prints a string to stdout using sys_write.
;   Arguments (System V):
;     rdi = pointer to string
;     rsi = length
;   Clobbers: rax, rdx (caller-saved, so fine)
; =============================================================================
print_string:
    push rbp
    mov  rbp, rsp

    ; sys_write: rax=1, rdi=fd(1=stdout), rsi=buf, rdx=len
    mov  rdx, rsi       ; length (3rd arg)
    mov  rsi, rdi       ; buffer (2nd arg)
    mov  rdi, 1         ; stdout fd (1st arg)
    mov  rax, 1         ; syscall number: sys_write
    syscall

    pop  rbp
    ret


; =============================================================================
; HELPER: print_digit
;   Prints a single decimal digit (0–9) to stdout.
;   Arguments:
;     rdi = digit value (0–9)
;   Clobbers: rax, rsi, rdx
; =============================================================================
print_digit:
    push rbp
    mov  rbp, rsp

    ; Convert number to ASCII: ASCII '0' = 48, so digit + 48 = ASCII char
    add  rdi, 48
    mov  [digit_buf], dil       ; dil = lowest byte of rdi

    ; print that single byte
    mov  rsi, digit_buf         ; buffer address
    mov  rdx, 1                 ; length = 1 byte
    mov  rdi, 1                 ; stdout
    mov  rax, 1                 ; sys_write
    syscall

    ; print newline
    mov  rsi, newline
    mov  rdx, 1
    mov  rdi, 1
    mov  rax, 1
    syscall

    pop  rbp
    ret


; =============================================================================
; FUNCTION: add_two
;   Demonstrates a clean function with prologue/epilogue.
;   Adds two integers.
;
;   Arguments (System V):
;     rdi = first number  (a)
;     rsi = second number (b)
;   Returns:
;     rax = a + b
; =============================================================================
add_two:
    ; --- PROLOGUE ---
    ; Save caller's RBP so we can restore it on return.
    ; Then set our own RBP = RSP, establishing our stack frame base.
    push rbp            ; RSP -= 8, [RSP] = caller's rbp
    mov  rbp, rsp       ; our frame base is now fixed

    ; No local variables needed here, so we skip "sub rsp, N"

    ; --- BODY ---
    ; rdi = a, rsi = b (already in the right registers from the caller)
    mov  rax, rdi       ; rax = a
    add  rax, rsi       ; rax = a + b
    ; Result is in rax — that's the return value by convention

    ; --- EPILOGUE ---
    ; Restore RSP to our frame base (no-op here since we didn't sub rsp)
    ; then restore caller's RBP, then return.
    mov  rsp, rbp       ; undo any local allocation (none here, but good habit)
    pop  rbp            ; restore caller's rbp
    ret                 ; pop return address → jump back to caller


; =============================================================================
; FUNCTION: multiply_two
;   Multiplies two integers using IMUL.
;   Shows that callee-saved registers (rbx) must be preserved.
;
;   Arguments:
;     rdi = a
;     rsi = b
;   Returns:
;     rax = a * b
; =============================================================================
multiply_two:
    push rbp
    mov  rbp, rsp

    ; We want to use rbx (a callee-saved register).
    ; We MUST save it first — the caller expects rbx to be unchanged after CALL.
    push rbx            ; save rbx on the stack

    ; Store 'a' in rbx so we can safely use rdi/rsi for other things if needed
    mov  rbx, rdi       ; rbx = a  (preserved safely)

    ; IMUL: multiplies rax by the operand, result in rdx:rax
    ; We put 'a' in rax and multiply by 'b' (rsi)
    mov  rax, rbx       ; rax = a
    imul rax, rsi       ; rax = a * b  (we ignore rdx overflow for small nums)

    ; Restore rbx BEFORE returning — caller-saved contract
    pop  rbx            ; rbx restored

    mov  rsp, rbp
    pop  rbp
    ret


; =============================================================================
; FUNCTION: sum_three
;   Adds three integers.
;   Shows using all three first argument registers.
;
;   Arguments:
;     rdi = a
;     rsi = b
;     rdx = c
;   Returns:
;     rax = a + b + c
; =============================================================================
sum_three:
    push rbp
    mov  rbp, rsp

    mov  rax, rdi       ; rax = a
    add  rax, rsi       ; rax = a + b
    add  rax, rdx       ; rax = a + b + c

    mov  rsp, rbp
    pop  rbp
    ret


; =============================================================================
; FUNCTION: nested_calls
;   Calls add_two and multiply_two internally.
;   Demonstrates that a callee can itself be a caller.
;   Computes: (2 + 3) * 4 = 20 ... but we print single digits so we'll do
;   (1 + 2) * 3 = 9.
;
;   Returns:
;     rax = (1 + 2) * 3 = 9
; =============================================================================
nested_calls:
    push rbp
    mov  rbp, rsp

    ; --- Call add_two(1, 2) ---
    ; rdi = 1st arg, rsi = 2nd arg
    mov  rdi, 1
    mov  rsi, 2
    call add_two        ; CALL pushes return address, jumps to add_two
                        ; add_two runs, returns with rax = 3
    ; Now rax = 3 (result of 1+2)

    ; We need to pass rax as first arg to multiply_two.
    ; But CALL will clobber rdi/rsi — so set them right before the call.
    mov  rdi, rax       ; 1st arg = 3  (result from add_two)
    mov  rsi, 3         ; 2nd arg = 3

    call multiply_two   ; rax = 3 * 3 = 9

    ; rax = 9, that's our return value
    mov  rsp, rbp
    pop  rbp
    ret


; =============================================================================
; FUNCTION: local_vars_demo
;   Demonstrates local variables stored on the stack.
;   Allocates space for 2 local ints, works with them, returns their sum.
;
;   Returns:
;     rax = local_a + local_b   (should be 5 + 3 = 8)
; =============================================================================
local_vars_demo:
    push rbp
    mov  rbp, rsp

    ; Allocate space for 2 local variables (each 8 bytes = 64-bit)
    ; Total: 16 bytes. RSP moves DOWN by 16.
    sub  rsp, 16

    ; Stack frame now looks like:
    ;   [rbp +  0]  = saved old rbp   (pushed in prologue)
    ;   [rbp -  8]  = local_a         ← we'll store 5 here
    ;   [rbp - 16]  = local_b         ← we'll store 3 here
    ;   RSP points here (rbp - 16)

    ; Store values into local slots using memory write [rbp - offset]
    mov  qword [rbp -  8], 5    ; local_a = 5
    mov  qword [rbp - 16], 3    ; local_b = 3

    ; Load them back and compute sum
    mov  rax, [rbp -  8]        ; rax = local_a = 5
    add  rax, [rbp - 16]        ; rax = 5 + 3 = 8

    ; Epilogue — mov rsp, rbp discards the 16-byte local allocation cleanly
    mov  rsp, rbp
    pop  rbp
    ret


; =============================================================================
; FUNCTION: demo_push_pop
;   Visually demonstrates PUSH/POP semantics:
;     - Pushes 3 values
;     - POPs them off in reverse order (LIFO)
;   Returns:
;     rax = first value popped (should equal last pushed = 9)
; =============================================================================
demo_push_pop:
    push rbp
    mov  rbp, rsp

    ; Push three values onto the stack
    ; After each push, RSP decreases by 8
    push 3              ; RSP -= 8, stack top = 3
    push 6              ; RSP -= 8, stack top = 6
    push 9              ; RSP -= 8, stack top = 9

    ; Pop in LIFO order — last pushed = first popped
    pop  rax            ; rax = 9,  RSP += 8
    pop  rbx            ; rbx = 6,  RSP += 8  (rbx is callee-saved, restored below)
    pop  rcx            ; rcx = 3,  RSP += 8  (caller-saved, fine to clobber)

    ; rax = 9 (the first value popped = last value pushed)
    mov  rsp, rbp
    pop  rbp
    ret


; =============================================================================
; _start — ENTRY POINT
;   This is where execution begins. Equivalent to main() in C.
;   Note: _start has NO caller, so we must NOT ret — we use sys_exit.
; =============================================================================
_start:

    ; _start has no caller, so no prologue needed for a return,
    ; but we still set up RBP for consistency and local var use.
    push rbp
    mov  rbp, rsp


    ; =========================================================================
    ; SECTION 1: MOV DEMO
    ; =========================================================================

    ; Print the section header
    mov  rdi, hdr_mov
    mov  rsi, hdr_mov_len
    call print_string

    ; Demonstrate various MOV forms
    mov  rax, 42            ; immediate → register
    mov  rbx, rax           ; register → register
    ; rbx is now 42

    ; Print label
    mov  rdi, msg_rax
    mov  rsi, msg_rax_len
    call print_string

    ; Print the value (42 — but we only handle single digits so use 7)
    ; Let's use a simpler value:
    mov  rdi, 7             ; we'll print digit 7
    call print_digit        ; prints "7\n"


    ; =========================================================================
    ; SECTION 2: PUSH/POP DEMO
    ; =========================================================================

    mov  rdi, hdr_push
    mov  rsi, hdr_push_len
    call print_string

    ; THEORY: This is exactly WHY callee-saved registers exist — so callers
    ; can stash values they need to survive across calls to other functions.
    ; r12–r15 are callee-saved: any function we call will preserve them.

    call demo_push_pop      ; rax = 9
    mov  r12, rax           ; r12 is callee-saved — safe to hold our value
                            ; print_string won't touch r12

    mov  rdi, msg_rax
    mov  rsi, msg_rax_len
    call print_string       ; this clobbers rax, but r12 is safe

    mov  rdi, r12           ; restore our saved result into rdi for print_digit
    call print_digit        ; prints "9\n"


    ; =========================================================================
    ; SECTION 3: CALL/RET DEMO — add_two and multiply_two
    ; =========================================================================

    mov  rdi, hdr_call
    mov  rsi, hdr_call_len
    call print_string

    ; --- Call add_two(4, 7) ---
    ; Set up args in rdi, rsi per System V convention
    mov  rdi, 4
    mov  rsi, 7
    call add_two            ; rax = 4 + 7 = 11
                            ; (we print single digits, so let's use 4+3=7)

    ; For printable single digit, let's just demo add_two(3, 4) = 7
    mov  rdi, msg_add
    mov  rsi, msg_add_len
    call print_string

    mov  rdi, 3             ; restart with printable args
    mov  rsi, 4
    call add_two            ; rax = 7
    mov  r12, rax           ; save result

    mov  rdi, r12
    call print_digit        ; prints "7\n"

    ; --- Call multiply_two(3, 3) = 9 ---
    mov  rdi, msg_mul
    mov  rsi, msg_mul_len
    call print_string

    mov  rdi, 3
    mov  rsi, 3
    call multiply_two       ; rax = 9
    mov  r12, rax

    mov  rdi, r12
    call print_digit        ; prints "9\n"


    ; =========================================================================
    ; SECTION 4: CALLING CONVENTION — sum_three (3 args)
    ; =========================================================================

    mov  rdi, hdr_conv
    mov  rsi, hdr_conv_len
    call print_string

    ; sum_three(1, 2, 3) = 6
    ; Args go in rdi, rsi, rdx — the first three argument registers
    mov  rdi, msg_sum3
    mov  rsi, msg_sum3_len
    call print_string

    mov  rdi, 1             ; 1st arg
    mov  rsi, 2             ; 2nd arg
    mov  rdx, 3             ; 3rd arg
    call sum_three          ; rax = 1 + 2 + 3 = 6
    mov  r12, rax

    mov  rdi, r12
    call print_digit        ; prints "6\n"

    ; --- nested_calls: (1+2)*3 = 9 ---
    mov  rdi, msg_nested
    mov  rsi, msg_nested_len
    call print_string

    call nested_calls       ; rax = 9
    mov  r12, rax

    mov  rdi, r12
    call print_digit        ; prints "9\n"


    ; =========================================================================
    ; SECTION 5: STACK FRAME — local variables
    ; =========================================================================

    mov  rdi, hdr_frame
    mov  rsi, hdr_frame_len
    call print_string

    mov  rdi, msg_local
    mov  rsi, msg_local_len
    call print_string

    call local_vars_demo    ; rax = 5 + 3 = 8
    mov  r12, rax

    mov  rdi, r12
    call print_digit        ; prints "8\n"


    ; =========================================================================
    ; EXIT
    ; =========================================================================
    ;
    ; _start cannot RET — there's no return address on the stack.
    ; We must call sys_exit explicitly.

    mov  rax, 60            ; syscall number: sys_exit
    mov  rdi, 0             ; exit code: 0 (success)
    syscall                 ; goodbye!



