; /////////////////////////////////////////////////////////////////////////////

; Znake (ZX Spectrum 48K)

; -----------------------------------------------------------------------------
; find_free_space.asm
; -----------------------------------------------------------------------------

; Copyright (C) 2016, Chris Wyatt

; All rights reserved

; Distributed under the Apache 2 license (see LICENSE)

; /////////////////////////////////////////////////////////////////////////////

check_quadrants:

    ld c,0x11

    ld a,e
    rlca
    rlca
    rlca
    rlca
    or e
    sub c
    ld b,a

check_quadrant:

    push de

    ; Set register d to the location of the top-left corner
    ld a,d
    add a,e
    ld d,a

    ; Set register e to the location of the bottom-right corner
    ld a,d
    add a,b
    ld e,a

    ld c,0xf0

    ld h,(TBL_SNAKE_HISTORY_CLEAN >> 8) & $FF

    ld a,(snake_history_clean_length)
    dec a
    ld l,a

    ; Load first turn or head location to register b
    ld b,(hl)

next_snake_section:

    dec l

    ; Load second turn or tail location to register a
    ld a,(hl)

    ; Check which end of the snake section has a higher X or Y value
    cp b
    jr c,check_no_overlap_pos

macro check_no_overlap, lo_reg, hi_reg

    ; Tail/turn 2 (B2) already in register a

    ; Minus top-left of square (A1)
    sub d

    ; If carry, A1x > B2x or A1y > B2y
    ; (A1y > B2y only detected in certain edge cases, which is why we check
    ;  if the Y nibble carries in the next check)
    jr c,no_overlap

    ; Check half carry
    and c ; 0xf0
    add a,d
    xor hi_reg
    and c ; 0xf0
    jr nz,no_overlap

    ; Bottom-right of square (A2)
    ld a,e

    ; Minus tail/turn 1 (B1)
    sub lo_reg

    ; If carry, B1x > A2x or B1y > A2y
    ; (B1y > A2y only detected in certain edge cases, which is why we check
    ;  if the Y nibble carries in the next check)
    jr c,no_overlap

    ; Check half carry
    and c ; 0xf0
    add a,lo_reg
    xor e
    and c ; 0xf0
    jr nz,no_overlap

endm

; Check no overlap (neg)

    check_no_overlap b, (hl) ; lo, hi

    jp overlap

check_no_overlap_pos:

    ; Tail/turn 2 (B2)
    ld a,b

    check_no_overlap (hl), b ; lo, hi

overlap:

    ld c,0x11

    ; Cannot divide square (i.e. 1 pixel)
    ld a,e
    sub d
    jr z,next_quadrant

    ; Load the offset to the bottom-right of the top-left quadrant to register
    ; b
    add a,c ; 0x11
    rrca
    ld e,a
    sub c ; 0x11
    ld b,a

    ; Load the offset to the bottom-left quadrant to register e
    ld a,e
    and 0x0f
    ld e,a

    ; Check quadrants within this quadrant
    call check_quadrant

next_quadrant:

    ; Pop location of top-left quadrant and offset to bottom-left quadrant
    ; from the stack
    pop de

    ld a,e
    or a

    ; If top-left, return
    ret z

    jp pe,bottom_right

    cp 0x09
    jr c,bottom_left

    ; Top-right

    ld a,e
    rrca
    rrca
    rrca
    rrca
    or e
    sub c ; 0x11
    ld b,a

    ld e,0x00

    jp (iy) ; check_quadrant

no_overlap:

    ld b,(hl)

    ; Continue to next snake section if l != 0
    xor a
    xor l
    jp nz,next_snake_section

    ; Otherwise, add this quadrant to the free squares tables

    ld hl,(free_squares_length_pointer)
    ld a,(hl)
    ld l,a

    ld a,(free_squares_low)
    add a,l
    ld l,a

    ; High byte is the same for BL, BR, TR and TL tables
    ld h,(TBL_FREE_SQUARES_BL_TL_TABLE >> 8) & $FF

    ld (hl),d

    inc h
    ; h = TBL_FREE_SQUARES_??_BR_TABLE

    ld (hl),e

    ld hl,(free_squares_length_pointer)
    inc (hl)

    ld c,0x11

    jp (ix) ; next_quadrant

bottom_left:

    rlca
    rlca
    rlca
    rlca
    or e
    ld e,a

    sub c ; 0x11
    ld b,a

    jp (iy) ; check_quadrant

bottom_right:

    sub c ; 0x11
    ld b,a

    ld a,e
    and 0xf0
    ld e,a

    jp (iy) ; check_quadrant