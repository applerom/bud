include 'other\kbd.inc'
;[]============================================================[] int_09h
;│ ToDo : new kbd-Interrupt
;└──>IN : DS = CS
;<--OUT : --
;[]=====.=======|===============================*==============[]
int_09h:
      pusha
        in      al, 60h                         ; get scancode
      push    ax                                ; store scancode
                ; Enable interrupts
        mov     al, 20h                         ; send EOI-command
        out     20h, al                         ; to first 8259 (master)
      pop     ax                                ; restore scancode
        ;sti
        cmp     al, KB_ACK
        je      .exit                           ; it`s ACK? (skip if ACK)

        mov     bScanCode, al                   ; Store ScanCode

        call    Check_keys.ENTER_BS_F10
        jnc     .exit
        call    Check_keys.SHIFT_CAPS_SCROLL
        jnc     .exit

        cmp     al, ScanCode.SPACE
        ja      .exit                           ; Non-display symbol pressed

        mov     si, Keys_TBL
        movzx   bx, bKBD_Status
        and     bl, KBD_Status.CapsLock + KBD_Status.Shift
        shr     bl, 2                           ; use shifted KBD_Status as index
        mov     si, [si + bx]
        mov     bl, al                          ; use scancode as index
        add     si, bx
                                                ; in SI - offset symbol by scancode
        lodsb
        cmp     al, ' '
        jb      .exit                           ; if ASCII-code symbols (codes >= "space") ...
        mov     bASCII_code, al                 ; ...store,

        or      bFlag, Flag__Press_Symbol       ; and set flag
.exit:
      popa
        iret

;[]=====.=======|===============================*==============[]
Check_keys:
.ENTER_BS_F10:
        cmp     al, ScanCode.ENTER
        je      @F
        cmp     al, ScanCode.BACKSPACE
        je      @F
        cmp     al, ScanCode.F10
        jne     .error
@@:
        or      bFlag, Flag__Press_ENTER_BS_F10 ; set flag
        jmp     .done

.SHIFT_CAPS_SCROLL:                             ; Shift-operations:
        cmp     al, ScanCode.SHIFT_left
        jne     @F                              ; left Shift pressed
        or      bKBD_Status, KBD_Status.Shift_left ; set Shift flag
        exit
@@:
        cmp     al, 80h + ScanCode.SHIFT_left   ; left Shift cancel
        jne     @F
        and     bKBD_Status, not KBD_Status.Shift_left
        exit
@@:
        cmp     al, ScanCode.SHIFT_right        ; right Shift pressed
        jne     @F
        or      bKBD_Status, KBD_Status.Shift_right
        exit
@@:
        cmp     al, 80h + ScanCode.SHIFT_right  ; right Shift cancel
        jne     @F
        and     bKBD_Status, not KBD_Status.Shift_right

        cmp     al, ScanCode.CAPSLOCK           ; Set LEDs for Status-keys
        jne     @F
        xor     bLED_Status, LED_Status.CapsLock ; CapsLock pressed?
        jmp     .Set_LED
@@:
        cmp     al, ScanCode.NUMLOCK            ; NumLock pressed?
        jne     @F
        xor     bLED_Status, LED_Status.NumLock
        jmp     .Set_LED
@@:
        cmp     al, ScanCode.SCROLLOCK          ; ScrollLock prressed?
        jne     .error
        xor     bLED_Status, LED_Status.ScrollLock

.Set_LED:                                       ; Set LEDs
        and     bLED_Status, not LED_Status.reserved ; reset unused bits
        and     bKBD_Status, LED_Status.reserved
        mov     al, bLED_Status
        or      bKBD_Status, al                 ; copy LED_Status to KBD_Status

        call    Wait8042BufferEmpty
        mov     al, LED_CMD                     ; Send Set_LED-command
        out     60h, al
        call    Wait8042BufferEmpty
        mov     al, bLED_Status                 ; Send status-byte to LED
        out     60h, al
.done:
        clc
.exit:
        ret
.error:
        stc
        exit

;[]============================================================[] int_09h.set
;│ ToDo : Set new int_09h vector
;└──>IN : --
;<--OUT : --
;[]=====.=======|===============================*==============[]
Set_new_int_09h:
;_w@ wTBL__IRQ09h_off ; store old int_09h vector
;_w@ wTBL__IRQ09h_seg
;_w@ wOld_int9__off
;_w_ wOld_int9__seg

        assume  wOld_int9__off, wTBL__IRQ09h_off ; store old int_09h vector
        assume  wOld_int9__seg, wTBL__IRQ09h_seg

        cli
        mov     wTBL__IRQ09h_off, int_09h       ; Set new vector
        assume  wTBL__IRQ09h_seg, cs            ; CS = DS
        sti
        ret

;[]============================================================[] int_09h.restore
;│ ToDo : Restore old int_09h vector
;└──>IN : -
;<--OUT : --
;[]=====.=======|===============================*==============[]
Restore_old_int_09h:
;_w@ wTBL__IRQ09h_off ; store old int_09h vector
;_w@ wTBL__IRQ09h_seg
;;_w@ wOld_int9__off
;_w_ wOld_int9__seg
      push ax
        mov     ax, cs
        cmp     wTBL__IRQ09h_seg, ax
      pop  ax
        jne     @F                              ; skip restore if our int9 was not set
        cli
        assume  wTBL__IRQ09h_off, wOld_int9__off ; restore old int_09h vector
        assume  wTBL__IRQ09h_seg, wOld_int9__seg
        sti
@@:
        ret

;[]============================================================[] Wait8042BufferEmpty
;│ ToDo : Wait for 8042 buffer empty
;└──>IN : --
;<--OUT : ZF if time-out
;[]=====.=======|===============================*==============[]
Wait8042BufferEmpty:
      push cx
        mov     cx, 0ffffh                      ; time-out number
@@:
        in      al, 64h                         ; get status
        test    al, IBF_8042                    ; Input buffer full on 8042 (0000 0010b)
        jnz     @B
;        loopnz  @B                              ; if not - loop
      pop  cx                                   ; if ZF on exit - error
        ret

;[]============================================================[] Input_UserName
;│ ToDo : Enter login
;└──>IN :
;<--OUT :
;[]=====.=======|===============================*==============[]
Enter_Login:
      pushad
        call    Set_Default_SH                  ; Set DEF SH there - after enter LOGIN

PRINT   "Login:"
        mov     esi, 0
.wait_key:
        test    bFlag, Flag__Press_Symbol
        jnz     .Press_Symbol
        test    bFlag, Flag__Press_ENTER_BS_F10
        jz      .wait_key

        and     bFlag, not Flag__Press_ENTER_BS_F10

        cmp     bScanCode, ScanCode.ENTER       ; Enter
        je      .exit
        cmp     bScanCode, ScanCode.F10         ; F10
        je      xd.exit

        cmp     esi, 0                          ; BackSpace
        jz      .wait_key

        dec     esi

        mov     bx, 0017h                       ; BH = video page number (0-based), BL = foreground color number (graphics modes only)
                ; decrement Column
        mov     ah, 3                           ; Query Cursor Position and Size
        int     10h
        dec     dl                              ; decrement Column
        mov     ah, 2                           ; Set Cursor Position
        int     10h                             ; DH = current row (0-based), DL = current column (0-based)
                ; clear previos character
        mov     cx, 1                          	; CX = repeat count
        mov     ah, 0ah                         ; Write Character to Cursor Location (Notes: This does NOT update the cursor position.)
        mov     al, ' '                         ; character to write (see ASCII Table)
        int     10h

        mov     byte [es:ebp__SH__Auth + esi], 0 ; Clear cymbol before

        jmp     .wait_key

.Press_Symbol:
        and     bFlag, not Flag__Press_Symbol

        cmp     esi, MAX_KEY_LENGTH
        jae     .wait_key

        mov     al, bASCII_code                 ; character to write (see ASCII Table)
        mov     [es:ebp__SH__Auth + esi], al
        mov     ah, 0eh                         ; Write Character to Cursor Location (Notes: This does NOT update the cursor position.)
        int     10h

        inc     esi
        jmp     .wait_key
.exit:
      popad
        ret

;[]============================================================[] Display_String
;│ ToDo : Display String as TTY
;└──>IN : ESI - String for output to screen
;<--OUT :
;[]=====.=======|===============================*==============[]
Display_String:
      pushad
        mov     ah, 0eh
        mov     bl, 17h                         ; BL = foreground color number (graphics modes only)
@@:
        lodsb
        cmp     al, 0
        je      .exit
        int     10h                             ;0eH писать символ на активную видео страницу (эмуляция телетайпа)
        jmp     @B                              ;    Вход:  AL = записываемый символ (использует существующий атрибут)
.exit:
      popad
        ret

.Login:
      pushad
        mov     esi, off_SH__Auth
        mov     ah, 0eh
        mov     bl, 17h                         ; BL = foreground color number (graphics modes only)
@@:
        mov     al, [es:esi]
        inc     esi
        cmp     al, 0
        je      .exit
        int     10h                             ;0eH писать символ на активную видео страницу (эмуляция телетайпа)
        jmp     @B                              ;    Вход:  AL = записываемый символ (использует существующий атрибут)
