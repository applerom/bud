strcode         db 64 dup (0)           ; хэшируемая строка
strlen          dw 8                    ; длина строки
digest          dd 4 dup (0)            ; буфер для хэша

FF:
      push    bp
        mov     bp, sp
      push    ecx
      push    ebx
        mov     eax, [bp+16h]
        mov     ebx, [bp+12h]
        and     ebx, eax
        not     eax
        and     eax, [bp+0Eh]
        or      eax, ebx
        add     eax, [bp+0Ah]
        add     eax, [bp+04h]
        add     eax, [bp+1Ah]
        mov     cx,  [bp+08h]
        rol     eax, cl
        add     eax, [bp+16h]
      pop     ebx
      pop     ecx
      pop     bp
        ret     26

GG:
      push    bp
        mov     bp, sp
      push    ecx
      push    ebx
        mov     eax, [bp+0Eh]
        mov     ebx, [bp+16h]
        and     ebx, eax
        not     eax
        and     eax, [bp+12h]
        or      eax, ebx
        add     eax, [bp+0Ah]
        add     eax, [bp+04h]
        add     eax, [bp+1Ah]
        mov     cx,  [bp+08h]
        rol     eax, cl
        add     eax, [bp+16h]
      pop     ebx
      pop     ecx
      pop     bp
        ret     26

HH:
      push    bp
        mov     bp, sp
      push    ecx
      push    ebx
        mov     eax, [bp+16h]
        xor     eax, [bp+12h]
        xor     eax, [bp+0Eh]
        add     eax, [bp+0Ah]
        add     eax, [bp+04h]
        add     eax, [bp+1Ah]
        mov     cx,  [bp+08h]
        rol     eax, cl
        add     eax, [bp+16h]
      pop     ebx
      pop     ecx
      pop     bp
        ret     26

II:
      push    bp
        mov     bp, sp
      push    ecx
      push    ebx
        mov     eax, [bp+0Eh]
        not     eax
        or      eax, [bp+16h]
        xor     eax, [bp+12h]
        add     eax, [bp+0Ah]
        add     eax, [bp+04h]
        add     eax, [bp+1Ah]
        mov     cx,  [bp+08h]
        rol     eax, cl
        add     eax, [bp+16h]
      pop     ebx
      pop     ecx
      pop     bp
        ret     26

MD5:                                    ; функция хэширования MD5
      push    bp                        ; стековый кадр
        mov     bp, sp
      push    di                        ; сохранение используемых регистров
      push    edx
      push    ebx
      push    eax
        mov     di, [bp+08h]             ; дополняем строку битом '1'
        mov     dx, [bp+06h]
        add     di, dx
        mov     byte [di], 80h
md5_1:
        inc     dx                      ; дополняем строку до 56 байт
        inc     di                      ; битами '0'
        mov     byte [di], 00h
        cmp     dx, 55
        jl      md5_1

        inc     di                      ; дополняем строку до 64 байт
        xor     edx, edx                ; битовым представлением
        mov     dx, [bp+06h]          ; первоначальной длины строки
        shl     dx, 3                   ; dx * 8
        mov     [di], edx
        mov     dword [di+4], 0

;        mov     byte [di], dl
;        inc     di
;        mov     byte [di], dh
;        inc     di
;        shr     dx, 8
;        mov     byte [di], dl
;        inc     di
;        mov     byte [di], dh
;        inc     di
;        mov     dword [di], 0
;        add     di, 4

        mov     di, [bp+08h]             ; в DI: смещение хэшируемой строки
        mov     [k], 0
md5_loop:
        push    [A];  dword
        push    [B];  dword
        push    [C];  dword
        push    [D];  dword
        mov     bx, X
        add     bx, [k]
        xor     ax, ax
        mov     al, byte [bx]
        shl     al, 2
        add     ax, di
        mov     bx, ax
        push    dword [bx]
        mov     bx, S
        add     bx, [k]
        xor     ax, ax
        mov     al, [bx]
        push    ax
        mov     bx, T
        mov     ax, [k]
        shl     ax, 2
        add     bx, ax
        push    dword [bx]
        mov     bx, F
        mov     ax, [k]
        shr     ax, 4
        shl     ax, 1
        add     bx, ax
        call    near [bx]
        mov     [A], eax
        inc     [k]                        ; ???

        push    [D]; dword
        push    [A]; dword
        push    [B]; dword
        push    [C]; dword
        mov     bx, X
        add     bx, [k]
        xor     ax, ax
        mov     al, [bx]
        shl     al, 2
        add     ax, di
        mov     bx, ax
        push    dword [bx]
        mov     bx, S
        add     bx, [k]
        xor     ax, ax
        mov     al, [bx]
        push    ax
        mov     bx, T
        mov     ax, [k]
        shl     ax, 2
        add     bx, ax
        push    dword [bx]
        mov     bx, F
        mov     ax, [k]
        shr     ax, 4
        shl     ax, 1
        add     bx, ax
        call    near [bx]
        mov     [D], eax
        inc     [k]                          ; ???

        push    [C]; dword
        push    [D]; dword
        push    [A]; dword
        push    [B]; dword
        mov     bx, X
        add     bx, [k]
        xor     ax, ax
        mov     al, [bx]
        shl     al, 2
        add     ax, di
        mov     bx, ax
        push    dword [bx]
        mov     bx, S
        add     bx, [k]
        xor     ax, ax
        mov     al, [bx]
        push    ax
        mov     bx, T
        mov     ax, [k]
        shl     ax, 2
        add     bx, ax
        push    dword [bx]
        mov     bx, F
        mov     ax, [k]
        shr     ax, 4
        shl     ax, 1
        add     bx, ax
        call    near [bx]
        mov     [C], eax
        inc     [k]                           ; ???

        push    [B]; dword
        push    [C]; dword
        push    [D]; dword
        push    [A]; dword
        mov     bx, X
        add     bx, [k]
        xor     ax, ax
        mov     al, [bx]
        shl     al, 2
        add     ax, di
        mov     bx, ax
        push    dword [bx]
        mov     bx, S
        add     bx, [k]
        xor     ax, ax
        mov     al, [bx]
        push    ax
        mov     bx, T
        mov     ax, [k]
        shl     ax, 2
        add     bx, ax
        push    dword [bx]
        mov     bx, F
        mov     ax, [k]
        shr     ax, 4
        shl     ax, 1
        add     bx, ax
        call    near [bx]
        mov     [B], eax
        inc     [k]                      ; ???

        cmp     [k], 64
        jl      md5_loop

        add     [A], 067452301h           ; A, B, C, D  с сохраненными ранее
        add     [B], 0EFCDAB89h
        add     [C], 098BADCFEh
        add     [D], 010325476h

        mov     di, [bp+04h]          ; возврат результирующих A, B, C, D
        mov     eax, [A]                  ; в буфер для хэша
        mov     [di+00h], eax
        mov     eax, [B]
        mov     [di+04h], eax
        mov     eax, [C]
        mov     [di+08h], eax
        mov     eax, [D]
        mov     [di+0Ch], eax

md5_end:
      pop     eax                     ; восстановление используемых регистров
      pop     ebx
      pop     edx
      pop     di
      pop     bp
        ret     6                       ; возврат из функции с очисткой стека


A       dd      067452301h
B       dd      0efcdab89h
C       dd      098badcfeh
D       dd      010325476h

F       dw      FF
        dw      GG
        dw      HH
        dw      II

X       db      00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15
        db      01, 06, 11, 00, 05, 10, 15, 04, 09, 14, 03, 08, 13, 02, 07, 12
        db      05, 08, 11, 14, 01, 04, 07, 10, 13, 00, 03, 06, 09, 12, 15, 02
        db      00, 07, 14, 05, 12, 03, 10, 01, 08, 15, 06, 13, 04, 11, 02, 09

S       db      07, 12, 17, 22, 07, 12, 17, 22, 07, 12, 17, 22, 07, 12, 17, 22
        db      05, 09, 14, 20, 05, 09, 14, 20, 05, 09, 14, 20, 05, 09, 14, 20
        db      04, 11, 16, 23, 04, 11, 16, 23, 04, 11, 16, 23, 04, 11, 16, 23
        db      06, 10, 15, 21, 06, 10, 15, 21, 06, 10, 15, 21, 06, 10, 15, 21

T       dd      0D76AA478h, 0E8C7B756h, 0242070DBh, 0C1BDCEEEh, 0F57C0FAFh, 04787C62Ah, 0A8304613h, 0FD469501h, 0698098D8h, 08B44F7AFh, 0FFFF5BB1h, 0895CD7BEh, 06B901122h, 0FD987193h, 0A679438Eh, 049B40821h
        dd      0F61E2562h, 0C040B340h, 0265E5A51h, 0E9B6C7AAh, 0D62F105Dh, 002441453h, 0D8A1E681h, 0E7D3FBC8h, 021E1CDE6h, 0C33707D6h, 0F4D50D87h, 0455A14EDh, 0A9E3E905h, 0FCEFA3F8h, 0676F02D9h, 08D2A4C8Ah
        dd      0FFFA3942h, 08771F681h, 06D9D6122h, 0FDE5380Ch, 0A4BEEA44h, 04BDECFA9h, 0F6BB4B60h, 0BEBFBC70h, 0289B7EC6h, 0EAA127FAh, 0D4EF3085h, 004881D05h, 0D9D4D039h, 0E6DB99E5h, 01FA27CF8h, 0C4AC5665h
        dd      0F4292244h, 0432AFF97h, 0AB9423A7h, 0FC93A039h, 0655B59C3h, 08F0CCC92h, 0FFEFF47Dh, 085845DD1h, 06FA87E4Fh, 0FE2CE6E0h, 0A3014314h, 04E0811A1h, 0F7537E82h, 0BD3AF235h, 02AD7D2BBh, 0EB86D391h

k       dw      0
