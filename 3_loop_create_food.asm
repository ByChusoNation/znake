; /////////////////////////////////////////////////////////////////////////////

; Znake (ZX Spectrum 48K)

; -----------------------------------------------------------------------------
; 3_loop_create_food.asm
; -----------------------------------------------------------------------------

; Copyright (C) 2016, Chris Wyatt

; All rights reserved

; Distributed under the Apache 2 license (see LICENSE)

; /////////////////////////////////////////////////////////////////////////////

next_game_loop:

    ; Create a new snake history table, where the data starts at the beginning
    ; of the table: this means we can free up a register later, as we will not
    ; need a counter

    ld h,(TBL_SNAKE_HISTORY >> 8) & $FF
    ld a,(snake_history_tail_offset)
    ld l,a

    ; Initialise counter
    ld a,(snake_history_head_offset)
    sub l
    inc a
    ld b,a

    ld (snake_history_clean_length),a

    ld de,TBL_SNAKE_HISTORY_CLEAN

transfer_byte:

    ; Transfer from one table to another. LDIR is not used here, as we need to
    ; jump to the beginning at table boundaries.

    ld a,(hl)
    ld (de),a
    inc l
    inc e
    dec b
    jr nz,transfer_byte

    ; Invalidate any free square quadrants that contain the new position for
    ; the head

    ld h,(TBL_SNAKE_HISTORY_CLEAN >> 8) & $FF
    ld a,(snake_history_clean_length)
    dec a
    ld l,a
    ld a,(hl)

    bit 3,a
    jr nz,ivsq_head_in_bottom_half

    ; Head in top half

    bit 7,a
    jr nz,ivsq_head_in_top_right

    ; Head in top left

    ld hl,flags
    set 7,(hl)
    jp find_free_space

ivsq_head_in_top_right:

    ld hl,flags
    set 6,(hl)
    jp find_free_space

ivsq_head_in_bottom_half:

    bit 7,a
    jr nz,ivsq_head_in_bottom_right

    ; Head in bottom left

    ld hl,flags
    set 4,(hl)
    jp find_free_space

ivsq_head_in_bottom_right:

    ld hl,flags
    set 5,(hl)

find_free_space:

; The following routine finds free space that is not occupied by the snake, and
; places new food in this free space. It divides the map into 4 quadrants
; (TR, BR, BL, TL); any quadrant that does not contain snake is added to the
; free squares tables; any quadrant that does contain snake is further divided
; into quadrants until all free space is mapped.

    ld ix,next_quadrant
    ld iy,check_quadrant

    ; Check bottom-left free squares cache invalid

    ld a,(flags)
    bit 4,a
    jr z,check_br_invalid

    ; d: location of top-left quadrant
    ; e: offset to bottom-left quadrant / width / height
    ld de,0x0804

    ld hl,free_squares_bl_length
    ld (hl),0
    ld (free_squares_length_pointer),hl

    ld a,TBL_FREE_SQUARES_BL_TL_TABLE & 0x00ff
    ld (free_squares_low),a

    call check_quadrants

    ld hl,flags
    res 4,(hl)

check_br_invalid:

    ld a,(flags)
    bit 5,a
    jr z,check_tr_invalid

    ; d: location of top-left quadrant
    ; e: offset to bottom-left quadrant / width / height
    ld de,0x8804

    ld hl,free_squares_br_length
    ld (hl),0
    ld (free_squares_length_pointer),hl

    ld a,TBL_FREE_SQUARES_BR_TL_TABLE & 0x00ff
    ld (free_squares_low),a

    call check_quadrants

    ld hl,flags
    res 5,(hl)

check_tr_invalid:

    ld a,(flags)
    bit 6,a
    jr z,check_tl_invalid

    ; d: location of top-left quadrant
    ; e: offset to bottom-left quadrant / width / height
    ld de,0x8004

    ld hl,free_squares_tr_length
    ld (hl),0
    ld (free_squares_length_pointer),hl

    ld a,TBL_FREE_SQUARES_TR_TL_TABLE & 0x00ff
    ld (free_squares_low),a

    call check_quadrants

    ld hl,flags
    res 6,(hl)

check_tl_invalid:

    ld a,(flags)
    bit 7,a
    jr z,check_create_food

    ; d: location of top-left quadrant
    ; e: offset to bottom-left quadrant / width / height
    ld de,0x0004

    ld hl,free_squares_tl_length
    ld (hl),0
    ld (free_squares_length_pointer),hl

    ld a,TBL_FREE_SQUARES_TL_TL_TABLE & 0x00ff
    ld (free_squares_low),a

    call check_quadrants

    ld hl,flags
    res 7,(hl)

check_create_food:

    ld iy,draw_line

    ; If food eaten flag is not set, jump
    ld a,(flags)
    bit 0,a
    jp z,invalidate_free_square_quadrants_tail

    ; Create food

    ; If a quadrant does not contain free squares, it is skipped. The counter
    ; will be decremented for each quadrant checked.
    ld b,5

    ; Pick a random quadrant

    call random
    and 0xc0
    jp pe,create_food_left

    ; Otherwise, random quadrant is on the right

    bit 7,a
    jr nz,create_food_tr

create_food_br:

    djnz create_food_br_continue
    jp collision

create_food_br_continue:

    ld a,(free_squares_br_length)
    or a
    jr z,create_food_tr
    ld e,TBL_FREE_SQUARES_BR_TL_TABLE & 0x00ff
    jp create_food

create_food_left:

    jr nz,create_food_tl

create_food_bl:

    djnz create_food_bl_continue
    jp collision

create_food_bl_continue:

    ld a,(free_squares_bl_length)
    or a
    jr z,create_food_br
    ld e,TBL_FREE_SQUARES_BL_TL_TABLE & 0x00ff
    jp create_food

create_food_tr:

    djnz create_food_tr_continue
    jp collision

create_food_tr_continue:

    ld a,(free_squares_tr_length)
    or a
    jr z,create_food_tl
    ld e,TBL_FREE_SQUARES_TR_TL_TABLE & 0x00ff
    jp create_food

create_food_tl:

    djnz create_food_tl_continue
    jp collision

create_food_tl_continue:

    ld a,(free_squares_tl_length)
    or a
    jr z,create_food_bl
    ld e,TBL_FREE_SQUARES_TL_TL_TABLE & 0x00ff

create_food:

    ; Pick a random free square

    ; Random number limit
    ld c,a

    call random

    ld b,a
    call modulo

    add a,e
    ld l,a

    ; High byte is the same for BL, BR, TR and TL tables
    ld h,(TBL_FREE_SQUARES_BL_TL_TABLE >> 8) & $FF
    ld d,(hl)

    inc h ; TBL_FREE_SQUARES_??_BR_TABLE
    ld e,(hl)

    ; Pick a random position within the free square

    ; Load square width/height to register h
    ld a,e
    sub d
    ld h,a

    ; Random number limit
    and 0x0f
    ld c,a

    ; X-coordinate

    push hl
    call random
    pop hl

    ld b,a
    call modulo

    rlca
    rlca
    rlca
    rlca
    and 0xf0
    ld b,a

    ; Y-coordinate

    push hl
    call random
    pop hl

    push bc
    call modulo
    pop bc

    or b

    ; Add location of top-left of square, to get the actual food location
    add a,d

    ld (current_food_location),a
    ld e,a

    ; Location of food
    ld hl,0x8178

    ; Column/row
    rrca
    rrca
    rrca
    rrca
    and 0x0f
    add a,8
    ld d,a

    ld a,e
    and 0x0f
    add a,4
    ld e,a

    ld iy,draw_line
    halt
    call draw_char

    ; Reset food eaten flag
    ld hl,flags
    res 0,(hl)

invalidate_free_square_quadrants_tail:

    ; Invalidate any free square quadrants that contain the current position
    ; for the tail. This tail will have moved by the time we do the next
    ; free square finding calculations, which is why we do the check now.

    ld hl,TBL_SNAKE_HISTORY_CLEAN
    ld a,(hl)

    bit 3,a
    jr nz,ivsq_tail_in_bottom_half

    ; Tail in top half

    bit 7,a
    jr nz,ivsq_tail_in_top_right

    ; Tail in top left

    ld hl,flags
    set 7,(hl)
    jp next_input_loop

ivsq_tail_in_top_right:

    ld hl,flags
    set 6,(hl)
    jp next_input_loop

ivsq_tail_in_bottom_half:

    bit 7,a
    jr nz,ivsq_tail_in_bottom_right

    ; Tail in bottom left

    ld hl,flags
    set 4,(hl)
    jp next_input_loop

ivsq_tail_in_bottom_right:

    ld hl,flags
    set 5,(hl)