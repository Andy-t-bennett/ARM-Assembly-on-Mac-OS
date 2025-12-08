.global _start

.data
hello_world: .ascii "Hello, World!\n"

.text
.align 2

_start:
    adrp x1, hello_world@PAGE
    add x1, x1, hello_world@PAGEOFF

    mov x0, #1
    mov x2, #14
    mov x16, #4
    svc #0x80
    
    mov x0, #0
    mov x16, #1
    svc #0x80
