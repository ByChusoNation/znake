; /////////////////////////////////////////////////////////////////////////////

; Znake (ZX Spectrum 48K)

; -----------------------------------------------------------------------------
; 7_loop_collision_detection.asm
; -----------------------------------------------------------------------------

; Copyright (C) 2016, Chris Wyatt

; All rights reserved

; Distributed under the Apache 2 license (see LICENSE)

; /////////////////////////////////////////////////////////////////////////////

collision_detection:

    ld h,(TBL_SNAKE_HISTORY >> 8) & $FF

    ld a,(snake_history_tail_offset)
    ld b,a

    ld a,(snake_history_head_offset)
    ld l,a

    ; Initialise counter
    sub b
    ld b,a

    ; Load current snake direction to register e
    ld a,(snake_direction_current)
    ld e,a

    ; Load head location to register c (A)
    ld a,(hl)
    ld c,a

    ; Load neck location to register d (B1)

    bit 0,e
    jr nz,head_right_of_neck
    bit 1,e
    jr nz,head_left_of_neck
    bit 2,e
    jr nz,head_below_neck

; Head above neck

    inc a

    jp check_border_collision_vertical

head_below_neck:

    dec a

    jp check_border_collision_vertical

head_left_of_neck:

    add a,0x10

    jp check_border_collision_horizontal

head_right_of_neck:

    sub 0x10

check_border_collision_horizontal:

    ld d,a

    jp c,collision
    jp collision_detection_next_snake_section

check_border_collision_vertical:

    ld d,a

    xor c
    and 0xf0
    jp nz,collision

collision_detection_next_snake_section:

    dec l

    ; Load second turn or tail location to register e (B2)
    ld a,(hl)
    ld e,a

    cp d
    jr nc,second_turn_higher

    ld e,d
    ld d,a

second_turn_higher:

    ld a,c
    cp d

    ; If carry, B1x > Ax or B1y > Ay
    ; (B1y > Ay only detected in certain edge cases, which is why we
    ;  isolate the Y nibble in the next check)
    jr c,no_collision

    ld a,d
    and 0x0f
    ld d,a
    ld a,c
    and 0x0f
    sub d

    ; If carry, B1y > Ay
    jr c,no_collision

    ld a,e
    cp c

    ; If carry, Ax > B2x or Ay > B2y
    ; (Ax > B2y only detected in certain edge cases, which is why we
    ;  isolate the Y nibble in the next check)
    jr c,no_collision

    ; Isolate Y nibble
    ld a,c
    and 0x0f
    ld d,a
    ld a,e
    and 0x0f
    sub d

    ; If carry, Ay > B2y
    jr c,no_collision

collision:

    ; Check if high score needs to be updated

    ; Set ix to address of high score column in difficulties table

    ld de,DIFFICULTIES_ROW_LENGTH
    ld ix,difficulties - DIFFICULTIES_ROW_LENGTH + 5
    ld a,(difficulty)
    inc a
    ld b,a

inc_difficulty_2:

    add ix,de

    djnz inc_difficulty_2

    ld hl,(score)

    ; Set de to high score value
    ld d,(ix + 1)
    ld e,(ix)

    ; Reset carry flag
    or a

    sbc hl,de

    ; If high score is greater than current score, do not replace high score
    jp c,menu_start

    ; Otherwise, replace high score column in difficulties table
    ld hl,(score)
    ld (ix + 1),h
    ld (ix),l

    ; Set hl to address of high score column in difficulties table
    push ix
    pop hl

    ld de,str_hi_score
    call gen_score_str

    jp menu_start

no_collision:

    ld d,(hl)

    djnz collision_detection_next_snake_section

