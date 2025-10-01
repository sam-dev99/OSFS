ORG 0x7c00
BITS 16

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

_start:
    jmp short start
    nop

 times 33 db 0
 
start:
    jmp 0:step2

step2:
    cli ; Clear Interrupts
    mov ax, 0x00
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    sti ; Enables Interrupts

.load_protected:
    cli
    lgdt[gdt_descriptor]
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    jmp CODE_SEG:load32

; GDT
gdt_start:
gdt_null:
    dd 0x0
    dd 0x0

; offset 0x8
gdt_code:     ; CS SHOULD POINT TO THIS
    dw 0xffff ; Segment limit first 0-15 bits
    dw 0      ; Base first 0-15 bits
    db 0      ; Base 16-23 bits
    db 0x9a   ; Access byte
    db 11001111b ; High 4 bit flags and the low 4 bit flags
    db 0        ; Base 24-31 bits

; offset 0x10
gdt_data:      ; DS, SS, ES, FS, GS
    dw 0xffff ; Segment limit first 0-15 bits
    dw 0      ; Base first 0-15 bits
    db 0      ; Base 16-23 bits
    db 0x92   ; Access byte
    db 11001111b ; High 4 bit flags and the low 4 bit flags
    db 0        ; Base 24-31 bits

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start-1
    dd gdt_start

[BITS 32]
;the following is a driver 
load32:
    mov eax, 1 ;starting sector to load from
    mov ecx, 100 ; number of sectors we need to load, remember dd in makefile
    mov edi, 0x0100000 ; where in memory we need to load
    call ata_lba_read
    jmp CODE_SEG:0x0100000

; this is a dummy driver to load our 32 bit mode kernel into protected mode 
; later we will use a proper C driver to interact with all of this
ata_lba_read:
    mov ebx, eax ; Backup the LBA
    shr eax, 24 ; shift highest 8 bits of eax to the right (32-24)
    or eax, 0xE0 ; this selects the master drive
    mov dx, 0x1F6 ; port to right the 8 bits of eax to
    out dx, al
    ;Finished sending the highest 8bits of the LBA 

    ; Send total sectors to read
    mov eax, ecx
    mov dx, 0x1F2
    out dx, al
    ;Finished sending all sectors

    mov eax, ebx ; restore the backp LBA above
    mov dx, 0x1F3
    out dx, al ; out command is to communicate with the bus that talks with the controller 
    ;Finished more bits of LBA

    ;Send more bits of LBA
    mov dx, 0x1F4
    mov eax, ebx ; Restore LBA
    shr eax, 8
    out dx, al
    ;Finished more bits of LBA

    ; Send upper 16 bits of the LBA
    mov dx, 0x1F5
    mov eax, ebx
    shr eax, 16
    out dx, al
    ; Finished sending  upper 16 bits of the LBA

    mov dx, 0x1F7
    mov al, 0x20
    out dx, al

;Read all sectors into memory
.next_sector:
    push ecx
;checking if we need to read because the controller might not be ready yet. 
.try_again:
    mov dx, 0x1F7
    in al, dx ; read from above port
    test al, 8 ; check for bit
    jz .try_again ; if check fails

;We need to read 256 words at a time
    mov ecx, 256
    mov dx, 0x1F0
    rep insw; insw reads one word, this case from port 0x1F0 and stores it in ES (edi) in our case
    ; rep repeats this process 256 times (bytes/1 sector)
    pop ecx; restore saved stack that we pushed above
    loop .next_sector
    ; End of reading sectors into memory
    ret



times 510-($ - $$) db 0
dw 0xAA55