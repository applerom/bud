;[]============================================================[] vyvod
;{}ToDo :
;--->IN :
;<--OUT :
;[]=====.=======|===============================*==============[]
vyvod:
.show:
        call    int_10h_0eh
        ret
.tochka:
        mov     si, _tochka
        jmp     .show
.dvoetochie:
        mov     si, _dvoetochie
        jmp     .show
.space:
        mov     si, _space
        jmp     .show
.BK:
        mov     si, _BK
        jmp     .show
.comma:
        mov     si, _comma
        jmp     .show

.vyv_cifra:
        and     al, 0fh
        cmp     al, 10
        jb      @F
        add     al, 7
@@:
        add     al, 30h
pushad
        call    int_10h_0eh_char
popad
        ret

.al:
push    ax
        shr     ax, 4
        call    .vyv_cifra
pop     ax
        call    .vyv_cifra
        ret

.ax:
push    ax ax ax
        shr     ax, 12
        call    .vyv_cifra
pop     ax
        shr     ax, 8
        call    .vyv_cifra
pop     ax
        shr     ax, 4
        call    .vyv_cifra
pop     ax
        call    .vyv_cifra
        ret

.eax:
push    eax eax eax eax eax eax eax
        shr     eax, 28
        call    .vyv_cifra
pop     eax
        shr     eax, 24
        call    .vyv_cifra
pop     eax
        shr     eax, 20
        call    .vyv_cifra
pop     eax
        shr     eax, 16
        call    .vyv_cifra
pop     eax
        shr     eax, 12
        call    .vyv_cifra
pop     eax
        shr     eax, 8
        call    .vyv_cifra
pop     eax
        shr     eax, 4
        call    .vyv_cifra
pop     eax
        call    .vyv_cifra
        ret

;[]============================================================[] int_10h_0eh
;│ ToDo : Display String as TTY
;└──>IN : DS:SI - String for output to screen
;<--OUT :
;[]=====.=======|===============================*==============[]
int_10h_0eh:
        mov     ah, 0eh
        mov     bl, 17h                         ; BL = foreground color number (graphics modes only)
@@:
        lodsb
        cmp     al, 0
        je      .exit
call    int_21h_02h                             ; skip - use int_21h - for logging
;        int     10h                             ;0eH писать символ на активную видео страницу (эмуляция телетайпа)
        jmp     @B                              ;    Вход:  AL = записываемый символ (использует существующий атрибут)
.exit:                                          ;           BL = цвет переднего плана (для графических режимов)
        ret

;[]============================================================[] int_10h_0eh
;│ ToDo : Write Character as TTY
;└──>IN : AL    - Char for output to screen
;<--OUT :
;[]=====.=======|===============================*==============[]
int_10h_0eh_char:
jmp     int_21h_02h                             ; skip - use int_21h - for logging
        mov     ah, 0eh
        mov     bl, 17h
        int     10h
        ret

;[]============================================================[] int_21h_02h
;│ ToDo : int_21h - equivalent of int_10h_0ah
;└──>IN :
;<--OUT :
;[]=====.=======|===============================*==============[]
int_21h_02h:
        mov     ah, 02h
        mov     dl, al
        int     21h
        ret
