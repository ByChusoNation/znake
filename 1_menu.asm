; /////////////////////////////////////////////////////////////////////////////

; Znake (ZX Spectrum 48K)

; -----------------------------------------------------------------------------
; 1_menu.asm
; -----------------------------------------------------------------------------

; Copyright (C) 2016, Chris Wyatt

; All rights reserved

; Distributed under the Apache 2 license (see LICENSE)

; /////////////////////////////////////////////////////////////////////////////

select_difficulty_draw:

    ld b,6

select_difficulty_draw_next:

    push hl
    push de
    push bc
    call draw_char
    pop bc
    pop de
    pop hl
    inc d
    djnz select_difficulty_draw_next
    ret

select_difficulty:

    ld hl,difficulties
    ld de,DIFFICULTIES_ROW_LENGTH
    or a ; Reset carry flag
    sbc hl,de

select_difficulty_move_pointer:

    add hl,de
    djnz select_difficulty_move_pointer

    push hl
    pop ix

    ld d,(ix + 3)
    ld e,(ix + 2)

    ld hl,0x81c0

    call select_difficulty_draw
    ret

control_select:

    ; Set border color to black
    xor a ; a = 0
    call $229B

    ; Clear screen
    ld hl,0x4000
    ld de,0x4001
    ld bc,0x17ff
    ld (hl),0
    ldir

    ld iy,draw_line

    ld de,0x0b08
    ld hl,str_title
    call print

    ld de,0x0a0a
    ld hl,str_keyboard
    call print

    ld de,0x0a0b
    ld hl,str_kempston
    call print

control_select_check_key:

    ld a,0xbf
    in a,(0xfe)

    bit 2,a
    jr z,menu_start

    bit 3,a
    jr nz,control_select_check_key

enable_kempston:

    ld hl,flags
    set 1,(hl)

menu_start:

    ld a,(23672)
    ld (menu_last_direction_frame_count),a

    ; Clear screen
    ld hl,0x4000
    ld de,0x4001
    ld bc,0x17ff
    ld (hl),0
    ldir

    ld ix,difficulties
    ld iy,draw_line_xor

    ; Push col/row and memory locations of graphics to stack, ready to draw
    ; later

; Push top border

    ld b,12

    ; Location of border top
    ld hl,0x8180

    ; Column/row
    ld de,0x0a05

menu_push_top_border_next:

    push hl
    push de

    inc d
    djnz menu_push_top_border_next

; Push right border

    ld b,11

    ; Location of border right
    ld hl,0x8188

    ; Column/row
    ld de,0x1606

menu_push_right_border_next:

    push hl
    push de

    inc e
    djnz menu_push_right_border_next

; Push bottom border

    ld b,12

    ; Location of border bottom
    ld hl,0x8190

    ; Column/row
    ld de,0x0a11

menu_push_bottom_border_next:

    push hl
    push de

    inc d
    djnz menu_push_bottom_border_next

; Push left border

    ld b,11

    ; Location of border left
    ld hl,0x8198

    ; Column/row
    ld de,0x0906

menu_push_left_border_next:

    push hl
    push de

    inc e
    djnz menu_push_left_border_next

; Push border corners

    ; Location of border top-right
    ld hl,0x81a0

    ; Column/row
    ld de,0x1605

    push hl
    push de

    ; Location of border bottom-right
    ld hl,0x81a8

    ; Column/row
    ld de,0x1611

    push hl
    push de

    ; Location of border bottom-left
    ld hl,0x81b0

    ; Column/row
    ld de,0x0911

    push hl
    push de

    ; Location of border top-left
    ld hl,0x81b8

    ; Column/row
    ld de,0x0905

    push hl
    push de

    ld c,12 + 11 + 12 + 11 + 4

    halt

menu_draw_border_char:

    pop de
    pop hl
    call draw_char

    dec c
    jr nz,menu_draw_border_char

    ld hl,str_title
    ld de,0x0b02
    call print

    ld hl,str_credits
    ld de,0x0415
    call print

    ld h,(ix + 1)
    ld l,(ix)
    ld d,(ix + 3)
    ld e,(ix + 2)
    call print

    ld h,(ix + DIFFICULTIES_ROW_LENGTH + 1)
    ld l,(ix + DIFFICULTIES_ROW_LENGTH)
    ld d,(ix + DIFFICULTIES_ROW_LENGTH + 3)
    ld e,(ix + DIFFICULTIES_ROW_LENGTH + 2)
    call print

    ld h,(ix + DIFFICULTIES_ROW_LENGTH * 2 + 1)
    ld l,(ix + DIFFICULTIES_ROW_LENGTH * 2)
    ld d,(ix + DIFFICULTIES_ROW_LENGTH * 2 + 3)
    ld e,(ix + DIFFICULTIES_ROW_LENGTH * 2 + 2)
    call print

    ld h,(ix + DIFFICULTIES_ROW_LENGTH * 3 + 1)
    ld l,(ix + DIFFICULTIES_ROW_LENGTH * 3)
    ld d,(ix + DIFFICULTIES_ROW_LENGTH * 3 + 3)
    ld e,(ix + DIFFICULTIES_ROW_LENGTH * 3 + 2)
    call print

    ld h,(ix + DIFFICULTIES_ROW_LENGTH * 4 + 1)
    ld l,(ix + DIFFICULTIES_ROW_LENGTH * 4)
    ld d,(ix + DIFFICULTIES_ROW_LENGTH * 4 + 3)
    ld e,(ix + DIFFICULTIES_ROW_LENGTH * 4 + 2)
    call print

    ld a,(difficulty)
    inc a
    ld b,a

    ld de,DIFFICULTIES_ROW_LENGTH
    ld ix,difficulties - 5

select_difficulty_offset_increment:

    add ix,de

    djnz select_difficulty_offset_increment

    ld hl,0x81c0
    ld d,(ix + 1)
    ld e,(ix)
    call select_difficulty_draw

input_loop:

    ; Map Q, A, [ENTER] to Kempston bits: 000FUDLR

    ld c,0x01

    ld a,0xfb ; 7 R E W Q
    in a,(0xfe)
    cpl
    and c
    rlca
    rlca
    rlca
    ld b,a

    ld a,0xfd ; G F D S A
    in a,(0xfe)
    cpl
    and c
    rlca
    rlca
    or b
    ld b,a

    ld a,0xbf ; H J K L [ENTER]
    in a,(0xfe)
    cpl
    and c
    rrca
    rrca
    rrca
    rrca
    or b
    ld b,a

    ld hl,flags
    bit 1,(hl)
    jr z,input_loop_skip_kempston

    in a,(0x1f)
    and 0x1c
    or b
    ld b,a

input_loop_skip_kempston:

    ; Only capture up/down
    and 0x0f
    ld hl,menu_last_direction
    cp (hl)

    jr nz,menu_change_direction

    ; Same direction

    bit 4,b
    jr nz,init

    ld a,(23672)
    ld hl,menu_last_direction_frame_count
    sub (hl)
    sub 20
    jr c,input_loop

menu_change_direction:

    ld a,b
    ld (menu_last_direction),a
    ld a,(23672)
    ld (menu_last_direction_frame_count),a

    ld hl,difficulty

    ld a,b

    bit 3,a
    jr nz,menu_kempston_joy_up

    bit 2,a
    jr nz,menu_kempston_joy_down

    jr input_loop

menu_kempston_joy_up:

    ld a,(hl)
    dec a
    jp p,unselect_current_difficulty

    ld a,4

    jp unselect_current_difficulty

menu_kempston_joy_down:

    ld a,(hl)
    inc a
    cp 5
    jr nz,unselect_current_difficulty

    xor a

unselect_current_difficulty:

    ld d,a

    push de

    ld b,(hl)
    inc b

    call select_difficulty

; Select new difficulty

    pop af

    ; Store new difficulty
    ld hl,difficulty
    ld (hl),a

    ld b,a
    inc b

    call select_difficulty

    jp input_loop
