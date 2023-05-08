.code16
/* Opcional limpia la pantalla en caso de ejecutar sobre algunas bios (recordar mover cursor -mov $0, %eax y -mov $1, %ebx)*/
/*int $0x10
push %ax
push %bx
push %cx
push %dx
mov $0x0600, %ax
mov $0x7, %bh
mov $0x0, %cx
mov $0x184f, %dx
push %ax
push %bx
push %cx
push %dx
mov $0x02, %ah
mov $0x00, %bh
mov $0, %dh
mov $0, %dl
pop %dx
pop %cx
pop %bx
pop %ax*/
cli
ljmp $0, $1f   /*Setear el registro CS en 0*/
1:
xor %ax, %ax   /*Setear registros de segmento en 0*/
mov %ax, %ds
mov %ax, %es
mov %ax, %fs
mov %ax, %gs
mov %ax, %bp
mov %ax, %ss
mov %bp, %sp

.equ CODE_SEG, 8
.equ DATA_SEG, gdt_data - gdt_start
lgdt gdt_descriptor                    /*Carga el registro GDTR con la direccion base y el limite de la tabla*/

mov %cr0, %eax  /*Setear el campo PE en 1 del registro CR0*/
orl $0x1, %eax
mov %eax, %cr0

ljmp $CODE_SEG, $protected_mode

gdt_start:
gdt_null:
    .long 0x0
    .long 0x0
gdt_code:
    .word 0xffff     /*limite:ffff (0:15)*/
    .word 0x0        /*base:0 (0:15)*/
    .byte 0x0        /*base:0 (16:23)*/
    .byte 0b10011010 /*P = 1, DPL(2 bits) = 0, S = 1 (segmento normal), TIPO(3 bits) = 3 (es ejecutable, no es ajustable, leible), A = 0 (no fue accedido)*/
    .byte 0b11001111 /*limite(16:19) = 0xC (tamaño del segmento: 0x000CFFFF), G = 1 (limite expresado en paginas de 4kB), D = 1 (direccionamiento de 32 bits), ultimos 2 bits en desuso*/
    .byte 0x0        /*base:0 (24:31)*/
gdt_data:
    .word 0xffff     /*limite:ffff (0:15)*/
    .word 0x0        /*base:0 (0:15)*/
    .byte 0x0        /*base:0 (16:23)*/
    .byte 0b10010010 /*P = 1, DPL(2 bits) = 0, S = 1 (segmento normal), TIPO(3 bits) = 1 (no es ejecutable, crece normal, escribible), A = 0 (no fue accedido)*/
    .byte 0b11001111 /*limite(16:19) = 0xC (tamaño del segmento: 0x000CFFFF), G = 1 (limite expresado en paginas de 4kB), D = 1 (direccionamiento de 32 bits), ultimos 2 bits en desuso*/
    .byte 0x0        /*base:0 (24:31)*/
gdt_end:
gdt_descriptor:
    .word gdt_end - gdt_start /*limit*/
    .long gdt_start           /*base*/

.code32
protected_mode:
mov $DATA_SEG, %ax  /*Setear registros de segmento para actualizar cache*/
mov %ax, %ds
mov %ax, %ss

mov $0X7000, %ebp  /*Stack segment comienza en 0x7000*/
mov %ebp, %esp

sgdt 0x7000  /*Guardo en el stack la direccion de comienzo de la GDT*/

vga_print:
    mov $message, %ecx
    mov $16, %eax
    mov $0, %edx
    /* Numero de lineas horizontales */
    mov $17, %ebx
    div %ebx
    mov %edx, %eax
    /*ancho de linea* bytes por caracter en la pantalla -> 160 = 80 * 2*/
    mov $80, %edx
    mul %edx
    /* 0xb8000 =direccion de video que se muestra en la pantalla */
    lea 0xb8000(%eax), %edx
    /* Color blanco de letras sobre negro */
    mov $0x0F, %ah
loop:
    mov (%ecx), %al
    cmp $0, %al
    jz end
    mov %ax, (%edx)
    add $1, %ecx
    
    /*mov $DATA_SEG, %ax*/
    add $2, %edx
    jmp loop
end:
    jmp .
message:
    .asciz "hello world" 
