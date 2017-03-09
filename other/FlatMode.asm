;[]=====.=======|===============================*==============[]
TmpGDT  dw      8 dup 0
;[]============================================================[] FlatMode
;│ ToDo : Go to Flat-Mode
;└──>IN : --
;<--OUT : --
;[]=====.=======|===============================*==============[] FlatMode.on
FlatMode:
.on:
_%
        smsw    ax
        test    al, 1
        jz      .real_mode

        LOG     "Not running under windows!"
        stop.error
%_

.real_mode:
        mov     [TmpGDT + 00h],     00010h      ; GDT limit
        linear dword [TmpGDT + 02], TmpGDT      ; GDT linear
        mov     [TmpGDT + 08h],     0ffffh      ; segment limit bits 0..15 (actually 12-27)
        mov     [TmpGDT + 0ah],     00000h      ; segment base bits 0-15
        mov     [TmpGDT + 0ch],     09200h      ; segment base bits 16-23, R/W, DT1, DPL0, P=1
        mov     [TmpGDT + 0eh],     0008fh      ; segment limit bits 16-19 (actually 28-31)

      push es
        cli

        lgdt    fword [TmpGDT]                  ; Load GDTR

        or      al, 1                           ; PM on
        lmsw    ax                              ; switch to PM

        mov     bx, 8                           ; flat segment
        mov     es, bx                          ; ES=flat. NOTE:DS=flat->error??!!

        mov     eax, cr0
        and     al, not 1                        ; PM off
        mov     cr0, eax

        sti
      pop  es
        call    A20.Enable
.exit:
        ret

;[]=====.=======|===============================*==============[] FlatMode.off
.off:
        cmp     [TmpGDT], 00010h
        jne     .exit

        mov     byte [TmpGDT + 0eh], 0          ; segment limit bits 16-19 (actually 28-31)
        lgdt    fword [TmpGDT]                  ; [TmpGDT]  ;Load GDTR

        smsw    ax                              ; mov eax, CR0
        or      al, 1                           ; PM off

      push es
        cli                                     ; D=0, G=0(byte), segment base bits 24-31

        lmsw    ax                              ; PM on

        mov     bx, 8                           ; non-flat segment
        mov     es, bx                          ; ES=normal
        
        mov     eax, cr0
        and     al, not 1                       ; PM off
        mov     cr0, eax

        sti
      pop  es
        call    A20.Disable
        exit

;[]============================================================[] A20
;│ ToDo : Enable/Disable/Check A20
;└──>IN : ES = 0
;<--OUT : ZF if time-out
;[]=====.=======|===============================*==============[]
A20:
.Enable:
        call    .check
        jnc     .exit

        cli
        in      al, 92h
        or      al, 10b
        out     92h, al
        sti
.
        call    .check
        jnc     .exit

        call    Wait8042BufferEmpty
        mov     al, 0d1h                        ; команда управления линий A20
        out     64h, al
        call    Wait8042BufferEmpty
        mov     al, 0dfh                        ; разрешить работу линии
        out     60h, al
        call    Wait8042BufferEmpty
        exit

.Disable:
        call    .check
        jc      .exit

        call    Wait8042BufferEmpty
        mov     al, 0d1h                        ; команда управления линий A20
        out     64h, al
        call    Wait8042BufferEmpty
        mov     al, 0ddh                        ; запретить работу линии
        out     60h, al
        call    Wait8042BufferEmpty
        exit

.check:
      push ds es
        assume  ds, 0
        assume  es, 0ffffh

      push word [0] word [es:10h]
        cli

        mov     al, [0]
        xor     al, 55h
        mov     [es:10h], al
        cmp     [0], al

        sti
      pop  word [es:10h] word [0] es ds

        je      .error
.done:
        clc
.exit:
        ret
.error:
        stc
        exit
