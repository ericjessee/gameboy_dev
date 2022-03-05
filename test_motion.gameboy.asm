INCLUDE "hardware.inc"

SECTION "Tiles", ROM0
Tiles:
    INCBIN "mush_big.tiles"
TilesEnd:

SECTION "Tile Map", ROM0
Tilemap:
    INCBIN "map"
TilemapEnd:

SECTION "Sprites", ROM0
Sprite:
	INCBIN "sprite2.tiles"
endSprite:

DEF buttons EQU $C000
DEF buttons_prev EQU $C001
DEF bit_button_left EQU 5
DEF bit_button_right EQU 4 
DEF bit_button_up EQU 6
DEF bit_button_down EQU 7
DEF bit_button_a EQU 0
DEF bit_button_b EQU 1

DEF bit_timer_clocksel_0 EQU %00000001
DEF bit_timer_clocksel_1 EQU %00000010
DEF bit_timer_start EQU %00000100

DEF obj0_attr_flag EQU $FE03
DEF obj0_chr_code EQU $FE02
DEF obj0_pos_x EQU $FE01
DEF obj0_pos_y EQU $FE00

DEF sprite_pos_x EQU $C002
DEF sprite_pos_y EQU $C003

;speed determines how many pixels per period(timer overflow) the object can move
;can be +126 or -126, with 127 being 0
DEF sprite_speed_x EQU $C004
DEF sprite_speed_y EQU $C005

DEF OAM_start EQU $FE00
DEF OAM_end EQU $FE9F ;last byte, not last object

DEF div_flag EQU $C006

DEF sprite_chr_code EQU $00
DEF sprite_attr_flag EQU $00


SECTION "Timer Overflow Interrupt", ROM0[$050]
	di
	call updateSpritePos
    reti

SECTION "vBlank Interrupt", ROM0[$040]
	di
	call updateObjPos
	reti

SECTION "Entry Point", ROM0[$100]

    jp Setup
    ds $150 - @, 0

Setup:
    ;disable sound
    ld a, 0
    ld [rNR52], a

    ;enable timer overflow interrupt
    ld a, $04
	or $01 ;enable vBlank interrupt
    ld [rIE], a 
	
	;set overflow threshold
	ld a, 0
	ld [rTMA], a

	;set initial speed to 0
	ld a, 127
	ld [sprite_speed_x], a
	ld [sprite_speed_y], a

	;init div flag to 0
	ld a, 0
	ld [div_flag], a

	;configure interrupt frequency and start the clock
	;100 = ~4kHz
	;101 = ~260kHz
	;110 = ~65kHz
	;111 = ~17kHz
	ld a, bit_timer_start; ~4kHz
	ld [rTAC], a

    call LoadGraphics
	ei
    call Loop

;this is mostly from gbdev's hello world example, though the sprite routines and interrupt handling are all mine
LoadGraphics: 
WaitVBlank:
    ;wait for a VBlank
    ld a, [rLY] ;LY tells us which line is being written
    cp 144 
    jp c, WaitVBlank

    ;turn off the LCD
    ld a, 0
    ld [rLCDC], a

	ld de, Tiles
	ld hl, $8800 ;this mushroom is extremely unoptimised, it should only take three tiles but it takes 255
	ld bc, TilesEnd - Tiles
CopyTiles: 
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, CopyTiles

	; Copy the tilemap
	ld de, Tilemap
	ld hl, $9800
	ld bc, TilemapEnd - Tilemap
CopyTilemap:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, CopyTilemap

	;Copy the sprite(s) -- same procedure as copying bg data
	ld de, Sprite ;store the address of the first byte of sprite in register de
	ld hl, $8000 ;store the address of the beginning of vram in register hl
	ld bc, endSprite - Sprite ;store the number of bytes to transfer in register bc
CopySprite:
	ld a, [de] ;load a byte of sprite data into register a
	ld [hli], a ;load the sprite data into the current address pointed to in vram by register hl
	inc de ;move to the next byte of sprite data
	dec bc ;decrement the number of bytes left to transfer 
	ld a, b ;check if the counter has reached 0 via bitwise or between b and c
	or a, c 
	jp nz, CopySprite ;if not, jump to beginning of subroutine and copy the next byte

	;clear OAM
	ld b, 159 ;159 bytes in OAM
	ld hl, OAM_start ;start at $FE00
ClearOAM:
	ld a, 0
	ld [hli], a ;load 0 into the current byte, increment by 1
	dec b ;decrement counter
	jp nz, ClearOAM ;repeat until counter reaches 0

	;load sprite into OAM obj0
	ld a, sprite_chr_code
	ld [obj0_chr_code], a
	ld a, sprite_attr_flag
	ld [obj0_attr_flag], a

	;set sprite initial position
	ld a, 75
	ld [obj0_pos_y], a
	ld [sprite_pos_y], a
	ld a, 75
	ld [sprite_pos_x], a
	ld [obj0_pos_x], a

	; During the first (blank) frame, initialize display registers
	ld a, %11100100
	ld [rBGP], a

    ;turn on the LCD
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
	ld [rLCDC], a
    ret

Loop:
	di ;interrupts during the key and handle routines cause erroneous key data
    call Keys
    call Handle
	ei
    jp Loop

Keys:
	;check dpad
	ld a, P1F_5
	ld [rP1], a
	ld a, [rP1]
	ld a, [rP1]
	ld a, [rP1]
	ld a, [rP1]
	ld a, [rP1]
	ld a, [rP1]
	;shift 4 bits to the right
	sla a
	sla a
	sla a
	sla a
	ld b, a
	ld a, $30
	ld [rP1], a
	;check face buttons
	ld a, P1F_4
	ld [rP1], a
	ld a, [rP1]
	ld a, [rP1]
	ld a, [rP1]
	ld a, [rP1]	
	ld a, [rP1]
	ld a, [rP1]
	;store all the buttons in one byte
	and a, $0F
	or a, b
	xor a, $FF ;flip the bits so set=pressed
	ld [buttons], a
	;reset the port register
	ld a, $30
	ld [rP1], a
	ret

Handle:
	
	ld a, [buttons]
    bit bit_button_right, a
	call nz, goRight
	call z, stopMovingX

	ld a, [buttons]
    bit bit_button_left, a
	call nz, goLeft

	ld a, [buttons]
    bit bit_button_up, a
	call nz, goUp
	call z, stopMovingY

	ld a, [buttons]
    bit bit_button_down, a
	call nz, goDown

	ld a, [buttons]
    bit bit_button_a, a
	;call nz, speedUp

	ld a, [buttons]
    bit bit_button_b, a
	;call nz, slowDown

	ld a, [buttons]
	ld [buttons_prev], a
	ret

goRight: ;set speed to 1
	ld a, 128
	ld [sprite_speed_x], a
	ret
goLeft: ;set speed to -1
	ld a, 126
	ld [sprite_speed_x], a
	ret
stopMovingX:
	ld a, 127
	ld [sprite_speed_x], a
	ret

goUp: ;set speed to 1
	ld a, 126
	ld [sprite_speed_y], a
	ret
goDown: ;set speed to -1
	ld a, 128
	ld [sprite_speed_y], a
	ret
stopMovingY:
	ld a, 127
	ld [sprite_speed_y], a
	ret

updateObjPos:
	ld a, [sprite_pos_x]
	ld [obj0_pos_x], a
	ld a, [sprite_pos_y]
	ld [obj0_pos_y], a
	ret

updateSpritePos:
	ld a, [div_flag] ;only move every second call. This halves the minimum speed
	jp z, updatePos ;doesn't work rightn now
	ld a, 1
	ld [div_flag], a
	ret
updatePos: 
	ld a, [sprite_speed_x] ;can be +126 or -126, with 127 being 0
	cp 127
	call z, dontMove
	call nc, moveRight
	call c, moveLeft
	ld a, [sprite_speed_y]
	cp 127
	call z, dontMove
	call nc, moveDown
	call c, moveUp
dontMove:
	ld a, 0
	ld [div_flag], a
	ret
moveRight:
	sub 127
	ld b, a
	ld a, [sprite_pos_x]
	add b
	ld [sprite_pos_x], a
	ld a, 0
	ld [div_flag], a
	ret
moveLeft:
	add 128
	cpl ;bit flip so that 254 = 1 etc 
	ld b, a
	ld a, [sprite_pos_x]
	sub b
	ld [sprite_pos_x], a
	ld a, 0
	ld [div_flag], a
	ret
moveDown:
	sub 127
	ld b, a
	ld a, [sprite_pos_y]
	add b
	ld [sprite_pos_y], a
	ld a, 0
	ld [div_flag], a
	ret
moveUp:
	add 128
	cpl ;bit flip so that 254 = 1 etc 
	ld b, a
	ld a, [sprite_pos_y]
	sub b
	ld [sprite_pos_y], a
	ld a, 0
	ld [div_flag], a
	ret