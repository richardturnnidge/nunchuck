;   Richard Turnnidge 2024
;   Nunchuck demo using Nunchuck library

    .assume adl=1       ; ez80 ADL memory mode
    .org $40000         ; load code here
    include "macros.inc"
    jp start_here       ; jump to start of code

    .align 64           ; MOS header
    .db "MOS",0,1     

    include "debug_routines.asm"
    include "math_routines.asm"
    include "delay_routines.asm"
    include "nunchuck.inc"

start_here:
            
    push af             ; store all the registers
    push bc
    push de
    push ix
    push iy

; ------------------

    CLS
    call hidecursor                     ; hide the cursor

    ld hl, string                       ; address of string to use
    ld bc, endString - string             ; length of string, or 0 if a delimiter is used

    rst.lil $18                         ; Call the MOS API to send data to VDP 



    call nunchuck_open                  ; need to setup i2c port

    call hidecursor                     ; hide the cursor

    call getCalib

LOOP_HERE:
    MOSCALL $1E                         ; get IX pointer to keyvals, currently pressed keys
    ld a, (ix + $0E)    
    bit 0, a    
    jp nz, EXIT_HERE                    ; ESC key to exit

    MOSCALL $1E                         ; get IX pointer to keyvals, currently pressed keys
    ld a, (ix + $0c)    
    bit 2, a    
    call nz, getCalib                    ; SPACE key to get calib data

    call nunchuck_update
    call displayNunchuckData

    ld a, 00000010b
    call multiPurposeDelay              ; wait a bit

;     ld a, (nunchuck_angleX)
;     ld b, a 
;     ld a, (oldAngleX)
;     sub b  
;     call get_ABS_a
;     cp 3
;     call nc,unPlotYData


;     ld a, (nunchuck_angleY)
;     ld b, a 
;     ld a, (oldAngleY)
;     sub b  
;     call get_ABS_a
;     cp 3
;     call nc,unPlotXData

    jr LOOP_HERE


getCalib:
    call nunchuck_calibration
    call displayNunchuckCalib


    ret 

plotXData:

                                        ; horizontal axis
                                        ; plot start point
    ld a, 25
    rst.lil $10
    ld a, 69                            ;  plot point
    rst.lil $10

    ld a, xLeft                         ;  plot y
    rst.lil $10
    ld a, 0                             ;  plot x
    rst.lil $10

    ld a, (nunchuck_angleY)
    rst.lil $10
    ld a, 0                             ;  plot y
    rst.lil $10

                                        ; draw a line
    ld a, 25
    rst.lil $10
    ld a, 5                             ;  draw lone to...
    rst.lil $10

    ld a, xRight                        ;  plot y
    rst.lil $10
    ld a, 0                             ;  plot x
    rst.lil $10

    ld a, (nunchuck_angleY)
    rst.lil $10
    ld a, 0                             ;  plot y
    rst.lil $10

    ret  



plotYData:

                                        ; vertical axis
                                        ; plot start point
    ld a, 25
    rst.lil $10
    ld a, 69                            ;  plot point
    rst.lil $10

    ld a, (nunchuck_angleX)             ;  plot y
    rst.lil $10
    ld a, 0                             ;  plot x
    rst.lil $10

    ld a, yTop
    rst.lil $10
    ld a, 0                             ;  plot y
    rst.lil $10


                                        ; draw a line
    ld a, 25
    rst.lil $10
    ld a, 5                             ;  draw lone to...
    rst.lil $10

    ld a, (nunchuck_angleX)             ;  plot y
    rst.lil $10
    ld a, 0                             ;  plot x
    rst.lil $10

    ld a, yBottom
    rst.lil $10
    ld a, 0                             ;  plot y
    rst.lil $10

    ret 


unPlotXData:

                                        ; horizontal axis
                                        ; plot start point
    ld a, 25
    rst.lil $10
    ld a, 71                            ;  plot point
    rst.lil $10

    ld a, xLeft                         ;  plot y
    rst.lil $10
    ld a, 0                             ;  plot x
    rst.lil $10

    ld a, (oldAngleY)
    rst.lil $10
    ld a, 0                             ;  plot y
    rst.lil $10

                                        ; draw a line
    ld a, 25
    rst.lil $10
    ld a, 7                             ;  draw lone to...
    rst.lil $10

    ld a, xRight                        ;  plot y
    rst.lil $10
    ld a, 0                             ; plot x
    rst.lil $10

    ld a, (oldAngleY)
    rst.lil $10
    ld a, 0                             ;  plot y
    rst.lil $10

    ld a, (nunchuck_angleY)
    ld (oldAngleY),a

    call plotXData

    ret

unPlotYData:
                                        ; vertical axis
                                        ; plot start point
    ld a, 25
    rst.lil $10
    ld a, 71                            ;  plot point
    rst.lil $10

    ld a, (oldAngleX)                   ;  plot y
    rst.lil $10
    ld a, 0                             ;  plot x
    rst.lil $10

    ld a, yTop
    rst.lil $10
    ld a, 0                             ;  plot y
    rst.lil $10


                                        ; draw a line
    ld a, 25
    rst.lil $10
    ld a, 7                             ;  draw lone to...
    rst.lil $10

    ld a, (oldAngleX)                   ;  plot y
    rst.lil $10
    ld a, 0                             ;  plot x
    rst.lil $10

    ld a, yBottom
    rst.lil $10
    ld a, 0                             ;  plot y
    rst.lil $10


    ld a, (nunchuck_angleX)
    ld (oldAngleX),a

    call plotYData

    ret 

xLeft:          equ     0
xRight:         equ     255
yTop:           equ     0
yBottom:        equ     220

xOffset:        equ     150
yOffset:        equ     120

; ------------------

EXIT_HERE:

; need to close i2c port
    call nunchuck_close
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

displayNunchuckData:

    ld b, 0
    ld c, 1
    ld a,(nunchuck_joyX)
    call debugA

    ld b, 0
    ld c, 2
    ld a,(nunchuck_joyY)
    call debugA

    ld b, 0
    ld c, 3
    ld a,(nunchuck_angleX)
    call debugA

    ld b, 0
    ld c, 4
    ld a,(nunchuck_angleY)
    call debugA

    ld b, 0
    ld c, 5
    ld a,(nunchuck_angleZ)
    call debugA

    ld b, 0
    ld c, 6
    ld a,(nunchuck_btnC)
    call debugA

    ld b, 0
    ld c, 7
    ld a,(nunchuck_btnZ)
    call debugA

    ld b, 0
    ld c, 8
    ld a,(nunchuck_joyD)
    ld d, 8
    call printBin

;     ld b, 0
;     ld c, 9
;     ld a,(nunchuck_angle_extra)
;     ld d, 8
;     call printBin

    ret 



displayNunchuckCalib:

    ld b, 0
    ld c, 10
    ld a,(nunchuck_calib_joyX_max)
    call debugA

    ld b, 0
    ld c, 11
    ld a,(nunchuck_calib_joyX_min)
    call debugA

    ld b, 0
    ld c, 12
    ld a,(nunchuck_calib_joyX_mid)
    call debugA

    ld b, 0
    ld c, 13
    ld a,(nunchuck_calib_joyY_max)
    call debugA

    ld b, 0
    ld c, 14
    ld a,(nunchuck_calib_joyY_min)
    call debugA

    ld b, 0
    ld c, 15
    ld a,(nunchuck_calib_joyY_mid)
    call debugA

    ld b, 0
    ld c, 16
    ld a,(nunchuck_calib0_angleX)
    call debugA

    ld b, 0
    ld c, 17
    ld a,(nunchuck_calib0_angleY)
    call debugA

    ld b, 0
    ld c, 18
    ld a,(nunchuck_calib0_angleZ)
    call debugA

    ld b, 0
    ld c, 19
    ld a,(nunchuck_calib1_angleX)
    call debugA

    ld b, 0
    ld c, 20
    ld a,(nunchuck_calib1_angleY)
    call debugA

    ld b, 0
    ld c, 21
    ld a,(nunchuck_calib1_angleZ)
    call debugA



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
    .db 22, 8                       ; set mode 8
    .db 23, 0, 192, 0               ; set to non-scaled graphics
    .db 31, 0,29,"Nunchuck demo v0.03"
    .db 31, 4,1,"nunchuck_joyX"
    .db 31, 4,2,"nunchuck_joyY"
    .db 31, 4,3,"nunchuck_angleX"
    .db 31, 4,4,"nunchuck_angleY"
    .db 31, 4,5,"nunchuck_angleZ"
    .db 31, 4,6,"nunchuck_btnC"
    .db 31, 4,7,"nunchuck_btnZ"
    .db 31, 9,8,"nunchuck_joyD"
;    .db 31, 9,9,"byte 5 data"


    .db 31, 4,10,"nunchuck_calib_joyX_max"
    .db 31, 4,11,"nunchuck_calib_joyX_min"
    .db 31, 4,12,"nunchuck_calib_joyX_mid"

    .db 31, 4,13,"nunchuck_calib_joyY_max"
    .db 31, 4,14,"nunchuck_calib_joyY_min"
    .db 31, 4,15,"nunchuck_calib_joyY_mid"

    .db 31, 4,16,"nunchuck_calib0_angleX"
    .db 31, 4,17,"nunchuck_calib0_angleY"
    .db 31, 4,18,"nunchuck_calib0_angleZ"

    .db 31, 4,19,"nunchuck_calib1_angleX"
    .db 31, 4,20,"nunchuck_calib1_angleY"
    .db 31, 4,21,"nunchuck_calib1_angleZ"

endString:


 ; -----------------

oldAngleX:     .db     0
oldAngleY:     .db     0
oldAngleZ:     .db     0





























