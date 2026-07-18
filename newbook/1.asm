
; The statement "segment . text" is an instruction to the assembler
; itself rather than a machine instruction. This statement indicates that the
; data or instructions following it are to be placed in the .TEXT SEGMENT
; In Linux this is where the instructions of a program are located.
segment .text

; The statement "global _start" is another instruction to the assembler,
; called an assembler directive or a PSEUDO OPCODE (pseudo-op) . This
; pseudo-op informs the assembler that the label _start is to be made
; known to the linker program when the program is linked. The _start
; function is the most basic "entry point" for a Linux program. When the
; system runs a program it transfers control to the _start function. A
; typical C program has a main function which is called indirectly via a
; _start function in the C library.
global _start

; The line beginning with _start is a LABEL. Since no code has been generated up
; to this point, the label refers to location 0 of the program's text segment.
_start:
    mov eax, 1  ; 1 is the EXIT system call number
    mov ebx, 69 ; the EXIT STATUS the program will return
    int 0x80    ; execute the system call



; We use the yasm assembler to produce an object file from an assembly
; source code file:
;       yasm -f elf64 -g dwarf2 -l exit.lst exit.asm

; The -f elf64 option selects a 64 bit output format which is compatible
; with Linux. The -g dwarf2 option selects the dwarf2 debugging
; format, which is essential for use with a debugger. The -l exit.lst asks
; for a listing file which shows the generated code in hexadecimal.

; The yasm command produces an object file named exit.o , which
; contains the generated instructions and data in a form ready to link with
; other code from other object files or libraries. In the case of an assembly
; program with the _start function the linking needs to be done with ld:
;       ld -o exit exit.o

; The -o exit option gives a name to the executable file produced by
; ld. Without that option, ld produces a file named a.out . If the assembly

; program defines MAIN rather than _START, then the linking needs to be
; done using gcc:
;       gcc -o exit exit.o

; In this case gee will incorporate its own version of _start and will
; call main from _start (or indirectly from _start) .
; You can execute the program using:
;       . /exit



