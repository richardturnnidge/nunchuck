;   Monday am, try to work out issue with lost connection
;   sorted.




    .assume adl=1       ; ez80 ADL memory mode
    .org $40000         ; load code here
    include "macros.inc"
    jp start_here       ; jump to start of code

    .align 64           ; MOS header
    .db "MOS",0,1     

    include "debug_routines.asm"
    include "delay_routines.asm"

start_here:
            
    push af             ; store all the registers
    push bc
    push de
    push ix
    push iy

; ------------------
; This is our actual code
    CLS
    call hidecursor                 ; hide the cursor

    ld hl, string       ; address of string to use
    ld bc, endString - string             ; length of string, or 0 if a delimiter is used

    rst.lil $18         ; Call the MOS API to send data to VDP 

; need to setup i2c port

    call open_i2c


LOOP_HERE:
    MOSCALL $1E                         ; get IX pointer to keyvals, currently pressed keys
    ld a, (ix + $0E)    
    bit 0, a    
    jp nz, EXIT_HERE                    ; ESC key to exit

    ld a, 0000100b
    call multiPurposeDelay      ; wait a bit

    call read_i2c

    jr LOOP_HERE


; ------------------

EXIT_HERE:

; need to close i2c port
   call close_i2c
   call showcursor
    CLS 

    pop iy              ; Pop all registers back from the stack
    pop ix
    pop de
    pop bc
    pop af
    ld hl,0             ; Load the MOS API return code (0) for no errors.   

    ret                 ; Return to MOS


; ------------------

open_i2c:

    ld c, 3                     ; making assumption based on Jeroen's code
    MOSCALL $1F                 ; open i2c

    ld c, $52                   ; i2c address
    ld b, 2                     ; number of bytes to send
    ld hl, i2c_write_buffer

    ld (hl), $F0
    inc hl 
    ld (hl), $55
    ld hl, i2c_write_buffer
    MOSCALL $21

    ld a, 00000010b
    call multiPurposeDelay

    ld c, $52                   ; i2c address
    ld b, 2                     ; number of bytes to send
    ld hl, i2c_write_buffer

    ld (hl), $FB
    inc hl 
    ld (hl), $00
    ld hl, i2c_write_buffer
    MOSCALL $21

    ld a, 00000010b
    call multiPurposeDelay      ; wait a bit

    ; ask for data

    ld c, $52                   ; i2c address
    ld b, 1                     ; number of bytes to send
    ld hl, i2c_write_buffer     ; send a $00 to restet i2c data position

    ld (hl), $00

    MOSCALL $21

    ret 

read_i2c:

    ; ask for data

    ld c, $52                   ; i2c address
    ld b, 1                     ; number of bytes to send
    ld hl, i2c_write_buffer     ; send a $00 to restet i2c data position

    ld (hl), $00

    MOSCALL $21

    ld a, 00000100b
    call multiPurposeDelay      ; wait a bit

    ld c, $52
    ld b,6
    ld hl, i2c_read_buffer
    MOSCALL $22
    ld a, 000000010b
    call multiPurposeDelay      ; wait a bit
    ; display the data

    ld hl, i2c_read_buffer


    ld a, (hl)
    ld (joyX), a
    inc hl

    ld a, (hl)
    ld (joyY), a
    inc hl

    ld a, (hl)
    ld (angleX), a
    inc hl

    ld a, (hl)
    ld (angleY), a
    inc hl

    ld a, (hl)
    ld (angleZ), a
    inc hl

    ld a, (hl)
    xor 11111111b
    and 00000001b
    ld (btnC), a

    ld a, (hl)

    sra a
    xor 11111111b
    and 00000001b
    ld (btnZ), a
    inc hl



    ld b, 0
    ld c, 1
    ld a,(joyX)
    call debugA

    ld b, 0
    ld c, 2
    ld a,(joyY)
    call debugA

    ld b, 0
    ld c, 3
    ld a,(angleX)
    call debugA

    ld b, 0
    ld c, 4
    ld a,(angleY)
    call debugA

    ld b, 0
    ld c, 5
    ld a,(angleZ)
    call debugA

    ld b, 0
    ld c, 6
    ld a,(btnC)
    call debugA

    ld b, 0
    ld c, 7
    ld a,(btnZ)
    call debugA

    ret 



close_i2c:

     MOSCALL $20

    ret 

 ; ------------------

hidecursor:
    push af
    ld a, 23
    rst.lil $10
    ld a, 1
    rst.lil $10
    ld a,0
    rst.lil $10                 ; VDU 23,1,0
    pop af
    ret


showcursor:
    push af
    ld a, 23
    rst.lil $10
    ld a, 1
    rst.lil $10
    ld a,1
    rst.lil $10                 ; VDU 23,1,1
    pop af
    ret

 ; ------------------


string:
    .db 31, 0,0,"testing i2c v0.05"
    .db 31, 4,1,"joyX"
    .db 31, 4,2,"joyY"
    .db 31, 4,3,"angleX"
    .db 31, 4,4,"angleY"
    .db 31, 4,5,"angleZ"
    .db 31, 4,6,"btnC"
    .db 31, 4,7,"btnZ"

endString:

i2c_read_buffer:
    .ds 32,0

i2c_write_buffer:
    .ds 32,0

btnC:       .db     0
btnZ:       .db     0

joyX:       .db     0
joyY:       .db     0

angleX:     .db     0
angleY:     .db     0
angleZ:     .db     0
































