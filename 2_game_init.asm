; /////////////////////////////////////////////////////////////////////////////

; Znake (ZX Spectrum 48K)

; -----------------------------------------------------------------------------
; 2_game_init.asm
; -----------------------------------------------------------------------------

; Copyright (C) 2016, Chris Wyatt

; All rights reserved

; Distributed under the Apache 2 license (see LICENSE)

; /////////////////////////////////////////////////////////////////////////////

init:

    ; Clear screen
    ld hl,0x4000
    ld de,0x4001
    ld bc,0x17ff
    ld (hl),0
    ldir

    ld iy,draw_line

    ; Push col/row and memory locations of graphics to stack, ready to draw
    ; later

; Push top border

    ld b,16

    ; Column/row
    ld de,0x0803

    ; Location of border top
    ld hl,0x8180

push_top_border_next:

    push hl
    push de

    inc d
    djnz push_top_border_next

; Push right border

    ld b,16

    ; Location of border right
    ld hl,0x8188

    ; Column/row
    ld de,0x1804

push_right_border_next:

    push hl
    push de

    inc e
    djnz push_right_border_next

; Push bottom border

    ld b,16

    ; Location of border top
    ld hl,0x8190

    ; Column/row
    ld de,0x0814

push_bottom_border_next:

    push hl
    push de

    inc d
    djnz push_bottom_border_next

; Push left border

    ld b,16

    ; Location of border right
    ld hl,0x8198

    ; Column/row
    ld de,0x0704

push_left_border_next:

    push hl
    push de

    inc e
    djnz push_left_border_next

; Push border corners

    ; Location of border top-right
    ld hl,0x81a0

    ; Column/row
    ld de,0x1803

    push hl
    push de

    ; Location of border bottom-right
    ld hl,0x81a8

    ; Column/row
    ld de,0x1814

    push hl
    push de

    ; Location of border bottom-left
    ld hl,0x81b0

    ; Column/row
    ld de,0x0714

    push hl
    push de

    ; Location of border top-left
    ld hl,0x81b8

    ; Column/row
    ld de,0x0703

    push hl
    push de

    ld c,16 + 16 + 16 + 16 + 4

    halt

draw_border_char:

    pop de
    pop hl
    call draw_char

    dec c
    jr nz,draw_border_char

    ; Initialise snake

    xor a ; a = 0x00
    ld (last_input),a
    ld (snake_direction_queue),a
    ld (snake_history_tail_offset),a

    inc a ; a = 0x01
    ld (snake_history_head_offset),a

    inc a ; a = 0x02
    ld (snake_direction_current),a

    ld a,0x87
    ld (TBL_SNAKE_HISTORY),a

    ld a,0x67
    ld (TBL_SNAKE_HISTORY + 1),a

    ld de,DIFFICULTIES_ROW_LENGTH
    ld ix,difficulties - DIFFICULTIES_ROW_LENGTH
    ld a,(difficulty)
    inc a
    ld b,a

inc_difficulty:

    add ix,de

    djnz inc_difficulty

    ; Set snake speed
    ld a,(ix + 4)
    ld (no_of_frames_per_update),a

    ; Set high score string from value in difficulties table
    push ix
    pop hl
    ld de,5
    add hl,de
    ld de,str_hi_score
    call gen_score_str

    ld a,3
    ld (snake_length),a

    ; Reset score
    ld hl,0x0000
    ld (score),hl

    ; Reset score string
    ld hl,0x3030 ; '00'
    ld (str_score),hl
    ld (str_score + 2),hl

    ; Score label
    ld de,0x0802
    ld hl,str_score_lbl
    call print

    ; High score label
    ld de,0x1102
    ld hl,str_hi_score_lbl
    call print

    ; High score
    ld de,0x1402
    ld hl,str_hi_score
    call print

    ld a,(flags)

    ; Set food eaten flag
    set 0,a

    ; Invalidate all free squares tables
    or 0xf0

    ld (flags),a

    ; Initialise previous frame count
    ld a,(23672)
    ld (previous_frame_count),a

    ; Draw initial snake graphics

    ; Location of snake head left
    ld hl,0x8120

    ; Column/row
    ld de,0x0e0b ; 6 + 8, 7 + 4

    call draw_char

    ; Location of snake body left/right
    ld hl,0x8130

    ; Column/row
    ld de,0x0f0b ; 7 + 8, 7 + 4

    call draw_char

    ; Location of snake tail right
    ld hl,0x8160

    ; Column/row
    ld de,0x100b ; 8 + 8, 7 + 4

    call draw_char