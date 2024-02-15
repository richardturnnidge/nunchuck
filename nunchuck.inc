; Nunchuck i2c library
; Richard Turnnidge 2024. v 0.01
; 
; call 'nunchuck_open'   to init i2c port with nunchuck
; call 'nunchuck_update' to retrieve fresh data
; call 'nunchuck_close'  to close the i2c connection
;
; Available byte info:
; 
; nunchuck_btnC:       0 off, 1 pressed
; nunchuck_btnZ:       0 off, 1 pressed

; nunchuck_joyX:       0 - 255. 128 is centre
; nunchuck_joyY:       0 - 255. 128 is centre
; nunchuck_joyD:       Digital binary of joystick directions, as per Console8 xxxx0000b

; nunchuck_angleX:     0 - 255. 128 is centre
; nunchuck_angleY:     0 - 255. 128 is centre
; nunchuck_angleZ:     0 - 255. 128 is centre. NOTE above may not get full range of 0 - 255
;

; ---------------------------------------------------------------------------
;
; 	OPEN NUNCHUCK I2C CONNECTION
;
; ---------------------------------------------------------------------------

nunchuck_open:

    ld c, 3                     	; making assumption based on Jeroen's code
    MOSCALL $1F		              	; open i2c

    ld c, nunchuck_addr  		; i2c address
    ld b, 2                     	; number of bytes to send
    ld hl, nunchuck_write_buffer

    ld (hl), $F0
    inc hl 
    ld (hl), $55
    ld hl, nunchuck_write_buffer
    MOSCALL $21

;    ld a, 00000010b
;    call multiPurposeDelay

    ld c, nunchuck_addr                 ; i2c address
    ld b, 2                     	; number of bytes to send
    ld hl, nunchuck_write_buffer

    ld (hl), $FB
    inc hl 
    ld (hl), $00
    ld hl, nunchuck_write_buffer
    MOSCALL $21

;    ld a, 00000010b
;    call multiPurposeDelay      	; wait a bit

    ld c, nunchuck_addr                 ; i2c address
    ld b, 1                     	; number of bytes to send
    ld hl, nunchuck_write_buffer     	; send a $00 to restet i2c data position

    ld (hl), $00			

    MOSCALL $21				; reset memory read address to $00

    ret 

; ---------------------------------------------------------------------------
;
; 	UPDATE NUNCHUCK POSITION / BUTTON DATA
;
; ---------------------------------------------------------------------------

nunchuck_update:

    ld c, nunchuck_addr                         ; i2c address
    ld b, 1                     	           ; number of bytes to send
    ld hl, nunchuck_write_buffer     	      ; send a $00 to restet i2c data position
    ld (hl), $00
    MOSCALL $21				                 ; reset memory read address to $00

;   ld a, 00000010b
;   call multiPurposeDelay      	           ; wait a bit

    ld c, nunchuck_addr
    ld b,6                    		        ; number of bytes to read
    ld hl, nunchuck_read_buffer
    MOSCALL $22

;   ld a, 000000010b
;   call multiPurposeDelay      	       ; wait a bit

    ld iy, nunchuck_read_buffer		       ; contains 6 bytes of data

    ld a, (iy + 0)
    ld (nunchuck_joyX), a

    ld a, (iy + 1)
    ld (nunchuck_joyY), a

    ld a, (iy + 2)
    sub 64
    sla a
    ld (nunchuck_angleX), a

    ld a, (iy + 3)
    sub 64
    sla a
    ld (nunchuck_angleY), a

    ld a, (iy + 4)
    ld (nunchuck_angleZ), a

    ld a, (iy + 5)
;    xor 11111111b

    ld (nunchuck_angle_extra),a
    and 00000001b
    ld (nunchuck_btnC), a

    ld a, (iy + 5)

    sra a
;    xor 11111111b
    and 00000001b
    ld (nunchuck_btnZ), a



    ; update Digital version of joystick
    ; bits for Console8 compatability

    ld d, 255                    ; reset before we start. Tied high, so a direction will set to 0
    
    ld a, (nunchuck_joyX)
    cp 110
    jr nc, j1                    ; if less than 110 then assume LEFT
    res 5,d 
j1:
    ld a, (nunchuck_joyX)
    cp 140
    jr c, j2                     ; if bigger than 140 then assume RIGHT
    res 7,d 
j2:
    ld a, (nunchuck_joyY)
    cp 110
    jr nc, j3                    ; if less than 110 then assume DOWN
    res 3,d 
j3:
    ld a, (nunchuck_joyY)
    cp 140
    jr c, j4                    ; if bigger than 140 then assume UP
    res 1,d 
j4:

    ld a, d 
    ld (nunchuck_joyD), a

    ret 

; ---------------------------------------------------------------------------
;
;   GRAB NUNCHUCK CALIBRATION DATA
;
; ---------------------------------------------------------------------------

nunchuck_calibration:

    ld c, nunchuck_addr                         ; i2c address
    ld b, 1                                    ; number of bytes to send
    ld hl, nunchuck_write_buffer              ; send a $20 to set i2c data position to calib data
    ld (hl), $20
    MOSCALL $21                              ; reset memory read address to $00

;   ld a, 00000010b
;   call multiPurposeDelay                     ; wait a bit

    ld c, nunchuck_addr
    ld b,16                                  ; number of bytes to read
    ld hl, nunchuck_read_buffer
    MOSCALL $22

;   ld a, 000000010b
;   call multiPurposeDelay                 ; wait a bit

    ld iy, nunchuck_read_buffer            ; contains 6 bytes of data

    ld a, (iy + 0)
    ld (nunchuck_calib0_angleX), a

    ld a, (iy + 1)
    ld (nunchuck_calib0_angleY), a

    ld a, (iy + 2)
    ld (nunchuck_calib0_angleZ), a

    ld a, (iy + 4)
    ld (nunchuck_calib1_angleX), a

    ld a, (iy + 5)
    ld (nunchuck_calib1_angleY), a

    ld a, (iy + 6)
    ld (nunchuck_calib1_angleZ), a

    ld a, (iy + 8)
    ld (nunchuck_calib_joyX_max), a

    ld a, (iy + 9)
    ld (nunchuck_calib_joyX_min), a

    ld a, (iy + 10)
    ld (nunchuck_calib_joyX_mid), a

    ld a, (iy + 11)
    ld (nunchuck_calib_joyY_max), a

    ld a, (iy + 12)
    ld (nunchuck_calib_joyY_min), a

    ld a, (iy + 13)
    ld (nunchuck_calib_joyY_mid), a

    ret 


; ---------------------------------------------------------------------------
;
; 	CLOSE NUNCHUCK I2C CONNECTION
;
; ---------------------------------------------------------------------------

nunchuck_close:

     MOSCALL $20

    ret 

; ---------------------------------------------------------------------------
;
; 	NUNCHUCK DATA
;
; ---------------------------------------------------------------------------

nunchuck_addr: 	equ $52

nunchuck_read_buffer:
	.ds 20,0

nunchuck_write_buffer:
	.ds 6,0

nunchuck_btnC:       .db     0
nunchuck_btnZ:       .db     0

nunchuck_joyX:       .db     0
nunchuck_joyY:       .db     0

nunchuck_joyD:       .db     0

nunchuck_angleX:     .db     0
nunchuck_angleY:     .db     0
nunchuck_angleZ:     .db     0

nunchuck_angle_extra: .db   0

; calibartiond data
nunchuck_calib_joyX_max:       .db     0
nunchuck_calib_joyX_min:       .db     0
nunchuck_calib_joyX_mid:       .db     0
    
nunchuck_calib_joyY_max:       .db     0
nunchuck_calib_joyY_min:       .db     0
nunchuck_calib_joyY_mid:       .db     0
    
nunchuck_calib0_angleX:        .db     0
nunchuck_calib0_angleY:        .db     0
nunchuck_calib0_angleZ:        .db     0

nunchuck_calib1_angleX:        .db     0
nunchuck_calib1_angleY:        .db     0
nunchuck_calib1_angleZ:        .db     0










