;[]============================================================[] Find_PCI
;³ ToDo : Find PCI_address of Device by dword PCI-Data
;ÀÄÄ>IN : EAX = Device info-dword
;       : BL  = 0 - by DeviceID/VendorID in EAX
;             = 9 - by Class Code in 0-23 bits of EAX
;         BH  = Number of Founded Device (0 - first, 1- second, etc)
;<--OUT : AX  = PCI address founded Device
;         CF    if not found any USB Controllers
;[]=====.=======|===============================*==============[]
Find_PCI:
      push cx edx
        mov     edx, eax                        ; Store DWord for compare
        xor     cx, cx                          ; Begin from Device 0 (bits 15:11), Func 0 (bits 10:8)
.next:
        mov     al, bl
        call    Get_PCI.dword

        cmp     bl, 9
        jne     @F
        and     eax, 00FFFFFFh                 ; For Class Code - use 0-23 bits for compare
@@:
        cmp     eax, edx
        je      .check_number_of_founded

        cmp     cx, 0ff00h
        jae      .error                         ; check for last Dev/Func
.inc_PCI:
        and     cx, 0ff00h
        add     cx, 100h                        ; increment Func/Dev
        jmp     .next

.error:                                         ; not found Device
        stc
        jmp     .exit

.check_number_of_founded:                       ; check number of founded
        cmp     bh, 0
        je      .found

        dec     bh                              ; search next device with this parameters
        jmp     .inc_PCI
.found:
        mov     ax, cx                          ; store PCI address for founded device in AX
        clc
.exit:
      pop  edx cx
        retn

Find_PCI.by_VID_DID:                            ; PCI: 00-01 - Vendor ID   <===\___
        mov     bl, 0                           ;      02-03 - Device ID   <===/
        jmp     Find_PCI                        ;      04-05 - Code
Find_PCI.by_Class:                              ;      06-07 - Status
        mov     bl, 9                           ;      08    - Revision ID
        jmp     Find_PCI                        ; ---> 09-0B - Class Code

;[]============================================================[] Get_PCI
;³ ToDo : Get PCI
;ÀÄÄ>IN :  AL = Rx
;          BL = 0 - Get Byte
;               1 - Get Word
;               2 - Get Dword
;          CX = Device Address + Function Number
;<--OUT : AL/AX/EAX = Value of Rx
;[]=====.=======|===============================*==============[]
Get_PCI:
      push cx dx
        mov     cl, al                          ; in CX - PCI Dev/Func/Rx
        mov     eax, 80000000h
        mov     ax, cx
        and     al, 0fch
        mov     dx, 0cf8h
        out     dx, eax

        add     dl, 4
        mov     al, cl
        and     al, 3
        add     dl, al

        cmp     bl, 0
        je      .db

        cmp     bl, 1
        je      .dw
.dd:
        in      eax, dx
        jmp     .exit
.dw:
        in      ax, dx
        jmp     .exit
.db:
        in      al, dx
.exit:
      pop  dx cx
        retn

.byte:  ; Get Byte
      push bx
        mov     bl, 0
        call    Get_PCI
      pop  bx
        ret

.word:  ; Get Word
      push bx
        mov     bl, 1
        call    Get_PCI
      pop  bx
        ret

.dword: ; Get DWord
      push bx
        mov     bl, 2
        call    Get_PCI
      pop  bx
        ret

;[]============================================================[] out_UHCI
;³ ToDo : In/Out Byte/Word/Dword to UHCI
;ÀÄÄ>IN : AL/AX/EAX = Value or Mask
;         DX        = Rx
;<--OUT : -- / AL/AX/EAX
;CHANGE : AL/AX/EAX, DX
;[]=====.=======|===============================*==============[]
macro   BASE    { add     dx, wUSB_Base_Address }
macro   in_dx   Rx
{ BASE
        in      Rx, dx
        ret }
macro   out_dx  Rx
{ BASE
        out     dx, Rx
        ret }
UHC:
.get:
.get_word:  in_dx ax                            ; word by default
.get_byte:  in_dx al
.get_dword: in_dx eax

.set:
.set_word:  out_dx ax                           ; word by default
.set_byte:  out_dx al
.set_dword: out_dx eax

.or:
.or_word:                                       ; word by default
      push bx
        mov     bx, ax
        call    .get
        or      ax, bx
        out     dx, al
      pop  bx
        ret
.or_byte:
      push bx
        mov     bl, al
        call    .get_byte
        or      al, bl
        out     dx, al
      pop  bx
        ret
.or_dword:
      push ebx
        mov     ebx, eax
        call    .get_dword
        or      eax, ebx
        out     dx, eax
      pop  ebx
        ret
.and:
.and_word:                                       ; word by default
      push bx
        mov     bx, ax
        call    .get
        and      ax, bx
        out     dx, al
      pop  bx
        ret
.and_byte:
      push bx
        mov     bl, al
        call    .get_byte
        and     al, bl
        out     dx, al
      pop  bx
        ret
.and_dword:
      push ebx
        mov     ebx, eax
        call    .get_dword
        and     eax, ebx
        out     dx, eax
      pop  ebx
        ret

;[]============================================================[] OHC
;³ ToDo : In/Out Byte/Word/Dword to OHC
;ÀÄÄ>IN :  AL/AX/EAX = Value
;          EDX  = Rx
;<--OUT : --
;[]=====.=======|===============================*==============[]
macro   BASE    { add edx, dUSB_Base_Address }
OHC:
.get:   BASE
        mov     eax, dHC
        ret
.set:   BASE
        mov     dHC, eax
        ret
.or:    BASE
        or      dHC, eax
        ret
.and:   BASE
        and     dHC, eax
        ret

;[]============================================================[] EHC
;³ ToDo : Out Byte/Word/Dword to EHCI
;ÀÄÄ>IN :  AL/AX/EAX = Value
;          EDX  = Rx
;<--OUT : --
;[]=====.=======|===============================*==============[]
macro   BASE    { add edx, dUSB_Base_Address }
EHC:
.get:   BASE
        mov     eax, dHC
        ret
.set:   BASE
        mov     dHC, eax
        ret
.or:    BASE
        or      dHC, eax
        ret
.and:   BASE
        and     dHC, eax
        ret

;[]============================================================[] Physical_Linear
;³ ToDo : ‚ëç¨á«¥­¨¥ ä¨§¨ç¥áª®£®  ¤à¥á 
;ÀÄÄ>IN : AX    = value in USB_RAM
;<--OUT : EAX   = physical 32-bit linear address value
;[]=====.=======|===============================*==============[]
Physical_Linear:
      push    edx
        xor     edx, edx
        mov     dx, ds
        shl     edx, 4
        and     eax, 0000ffffh
        add     eax, edx
      pop     edx
        ret

;[]============================================================[] Wait_Stable
;³ ToDo : Delay for device to be stable.
;ÀÄÄ>IN : --    Delay timer refer to Cherry USB keyboard
;<--OUT : --    stable time after attached.
;[]=====.=======|===============================*==============[]
Wait_Stable:
      push bx cx
        xor     bx, bx
        mov     cx, 6000                        ; 180 ms
        call    Usb_Wait_Refresh
      pop  cx bx
        ret

;[]========================================================================[]
;Procedure:     Delay_12ms
;Function:      Delay for 12 ms
;[]========================================================================[]
Delay_12ms:
      push bx cx
        xor     bx, bx
        mov     cx, 400                         ; bx:cx=wait period (400 -> 12 msec)
        call    Usb_Wait_Refresh
      pop  cx bx
        ret

;[]========================================================================[]
;Procedure:     Delay_1ms
;Function:      Delay for 1 ms
;[]========================================================================[]
Delay_1ms:
      push bx cx
        xor     bx, bx
;debug  mov     cx, 40                          ; bx:cx=wait period
        mov     cx, 100                         ; debug
                                                ; (40 -> 1.2 msec)
        call    Usb_Wait_Refresh
      pop  cx bx
        ret

;[]========================================================================[]
;Procedure:     Usb_Wait_Refresh
;Function:      Delay time with system DRAM refresh period
;Input:         BX:CX = delay counter (*30us)
;[]========================================================================[]
    align   4
Usb_Wait_Refresh:
      pusha
    align   4
.Loop:
@@:
        in      al, 61h
        test    al, 10h
        jz      @b
    align   4
@@:
        in      al, 61h
        test    al, 10h
        jnz     @b

        loop    .Loop

        or      bx, bx
        jz      @f
        dec     bx
        jnz     .Loop

@@:
      popa
        ret




;[]============================================================[] Wait05s
;³ ToDo : Wait for 55 ms
;ÀÄÄ>IN : EAX tics for waiting
;<--OUT : --
;[]=====.=======|===============================*==============[]
Delay:
        add     eax, [es:046ch]
@@:
        cmp     eax, [es:046ch]
        ja      @B
        ret
.55ms:
        mov     eax, 1
        jmp     Delay
.110ms:
        mov     eax, 2
        jmp     Delay
.220ms:
        mov     eax, 4
        jmp     Delay
