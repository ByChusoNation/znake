; /////////////////////////////////////////////////////////////////////////////

; Znake (ZX Spectrum 48K)

; -----------------------------------------------------------------------------
; im2_routine.asm
; -----------------------------------------------------------------------------

; Copyright (C) 2016, Chris Wyatt

; All rights reserved

; Distributed under the Apache 2 license (see LICENSE)

; /////////////////////////////////////////////////////////////////////////////

; Interrupt routine.

    ex af,af'
    exx

    ; Increment frame counter
    ld hl,23672
    inc (hl)

    call check_input

    exx
    ex af,af'

    ei
    reti