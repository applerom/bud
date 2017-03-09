;[]============================================================[] Detect
;³ ToDo : Find USB Controller and store main vars for detected type
;ÀÄÄ>IN : --
;<--OUT : CF    if not found
;[]=====.=======|===============================*==============[]
Detect:
.UHC:                                           ; Check Controller type by HCI_ID an Set it values
        mov     eax, UHCI.ID
        call    Find_PCI.by_Class               ; Found first UHCI USB-controller by class-code
        jc      .error

        mov     bUSB_type, UHCI

        mov     cx, ax                          ; PCI address to cx
        mov     wUSB_PCI_Address, ax            ; store PCI address
        mov     al, UHCI.USB_base               ; Get USBBASE
        call    Get_PCI.word

        and     ax, UHCI.Mask__USB_base         ; Calculate USB_BaseAddr = USBBASE & Mask__USBBASE
        mov     wUSB_Base_Address, ax

        mov     bNumber_Ports, 2
        jmp     .found

.OHC:
        mov     eax, OHCI.ID
        call    Find_PCI.by_Class               ; Found first UHCI USB-controller by class-code
        jc      .error

        mov     bUSB_type, OHCI

        mov     cx, ax                          ; PCI address to cx
        mov     wUSB_PCI_Address, ax            ; store PCI address
        mov     al, OHCI.USB_base               ; Get USBBASE
        call    Get_PCI.dword

        and     eax, OHCI.Mask__USB_base        ; Calculate USB_BaseAddr = USBBASE & Mask__USBBASE
        mov     dUSB_Base_Address, eax

        get_OHC HcRhDescriptorA                 ; Store Number of Ports on Host
        and     al, 0Fh
        mov     bNumber_Ports, al

        jmp     .found

.EHC:
        mov     eax, EHCI.ID
        call    Find_PCI.by_Class               ; Found first UHCI USB-controller by class-code
        jc      .error

        mov     bUSB_type, EHCI

        mov     cx, ax                          ; PCI address to cx
        mov     wUSB_PCI_Address, ax            ; store PCI address
        mov     al, EHCI.USB_base               ; Get USBBASE
        call    Get_PCI.dword

        and     eax, EHCI.Mask__USB_base        ; Calculate USB_BaseAddr = USBBASE & Mask__USBBASE
        mov     dUSB_Base_Address, eax

        get_EHC HCSPARAMS                       ; Store Number of Ports on Host
        and     al, HCSPARAMS__N_PORTS          ; ç¨á«® ­¨áå®¤ïé¨å ¯®àâ®¢
        mov     bNumber_Ports, al

        jmp     .found

.found:                                         ; in CX - PCI_address of founded USB-controller
        clc
.exit:
        ret
.error:                                         ; 0C03020h/0C03010h/0C0300h ClassCode not found
        stc
        jmp     .exit

;[]============================================================[] Run_Host
;³ ToDo : Start host controller working
;ÀÄÄ>IN : --
;<--OUT : --
;[]=====.=======|===============================*==============[]
Run_Host:
        cmp_____USB_type__UHCI_OHCI_EHCI
.UHCI:
        or_UHC  USBCMD, USBCMD__RS
        exit
.OHCI:
        exit
.EHCI:
.exit:
        ret

;[]============================================================[] Stop_Host
;³ ToDo :Stop Host
;ÀÄÄ>IN : --
;<--OUT : --
;[]=====.=======|===============================*==============[]
Stop_Host:
        cmp_____USB_type__UHCI_OHCI_EHCI
.UHCI:
        and_UHC USBCMD, not USBCMD__RS
        exit
.OHCI:
        exit
.EHCI:
.exit:
        ret

;[]============================================================[] GetLastError
;³ ToDo : GetLastError
;ÀÄÄ>IN : --
;<--OUT : AX    = Last Error Index
;[]=====.=======|===============================*==============[]
GetLastError:
        cmp_____USB_type__UHCI_OHCI_EHCI
.UHCI:
        exit
.OHCI:
        mov     ax, TD_OHC__CC_EC_T_DI_DP_R
        shr     ax, 12                          ; CC-field = bits [31:28] of first TD dword
_%
        mov     si, ax
        shl     si, 1
        add     si, Condition_Code_TBL
        mov     si, [si]
%_
        exit
.EHCI:
.exit:
        ret
_%
Condition_Code_TBL:
.0000           dw      _NoError
.0001           dw      _CRC
.0010           dw      _BitStuffing
.0011           dw      _DataToggleMismatch
.0100           dw      _Stall
.0101           dw      _DeviceNotResponding
.0110           dw      _PIDCheckFailure
.0111           dw      _UnexpectedPID
.1000           dw      _DataOverrun
.1001           dw      _DataUnderrun
.1010           dw      _ReservedErrorType
.1011           dw      _ReservedErrorType
.1100           dw      _BufferOverrun
.1101           dw      _BufferUnderrun
.1110           dw      _NotAccessed
.1111           dw      _NotAccessed
dz      _Condition_Code                 , "Condition code:"
dz      _NoError                        , "NoError"
dz      _CRC                            , "CRC"
dz      _BitStuffing                    , "BitStuffing"
dz      _DataToggleMismatch             , "DataToggleMismatch"
dz      _Stall                          , "Stall"
dz      _DeviceNotResponding            , "DeviceNotResponding"
dz      _PIDCheckFailure                , "PIDCheckFailure"
dz      _UnexpectedPID                  , "UnexpectedPID"
dz      _DataOverrun                    , "DataOverrun"
dz      _DataUnderrun                   , "DataUnderrun"
dz      _ReservedErrorType              , "ReservedErrorType"
dz      _BufferOverrun                  , "BufferOverrun"
dz      _BufferUnderrun                 , "BufferUnderrun"
dz      _NotAccessed                    , "NotAccessed"
%_

;[]============================================================[] bud_Ctrl
;³ ToDo : Control Transfer
;ÀÄÄ>IN : SI    = REQuest (Descriptor) = User buffer    (Request)
;         EDI   = DATA buffer                           (Response)
;         CX    = LENgth of requested datas (in DATA stage) - no more then REQ__Length
;<--OUT : CF    = 0 successful
;[]=====.=======|===============================*==============[]
bud_Ctrl:
        call    copy_Request                    ; copy User Request to REQ-area
.Send_REQ:
        mov     bSend_Type, CONTROL_TYPE        ; <--- !!! CHANGE for each type !!! ***

        mov_dw  dUser_buffer__Size, REQ__Length

        and     PARA__CtrlByte, not DIRECTION__IN ; OUT direction by def
        test    REQ__Type, FROM_DEV_STD         ; bit7 (80h) - read from device
        jz      @F
        or      PARA__CtrlByte, DIRECTION__IN   ; Set IN direction
@@:
        mov     PARA__DevEndp, 0                ; Endpoint  0 for CTRL-transfer
        assume  PARA__MaxSize, PARA__CTRL_MPS   ; default MPS for CTRL-operations

        cmp_____USB_type__UHCI_OHCI_EHCI
.UHCI:
        exit
.OHCI:
        LOG     "Control Transfer OHC"
        call    Control_Transfer_OHC
        exit
.EHCI:
.exit:
        ret

;[]============================================================[] copy_Request
;³ ToDo : Copy Request to REQ-area (32-bit operation)
;ÀÄÄ>IN : ESI = Pointer to Request for copy
;<--OUT :
;[]=====.=======|===============================*==============[]
copy_Request:
      pushad
        mov     cx, REQ.size
@@:
        lodsb
        mov     bREQ, al
        inc     ebp
        loop    @B
      popad
        ret

;[]============================================================[] bud_R
;³ ToDo : Read Block
;ÀÄÄ>IN : ESI    = Buffer for transfer
;         ECX    = Size of transfer (in bytes)
;<--OUT : CF if error
;[]=====.=======|===============================*==============[]
bud_R:
        mov     PARA__DevEndp, EP_BULK_IN_DEF   ; For massives IN = 2
        cmp_____USB_type__UHCI_OHCI_EHCI        ; for XD = 6
.UHCI:
        exit
.OHCI:
        or      PARA__CtrlByte, DIRECTION__IN   ; Set READ direction
        call    bud_Bulk
        exit
.EHCI:
.exit:
        ret

;[]============================================================[] bud_W
;³ ToDo : Write Block
;ÀÄÄ>IN : ESI   = Buffer for transfer
;         ECX   = Size of transfer (in bytes)
;<--OUT : CF if error
;[]=====.=======|===============================*==============[]
bud_W:
        mov     PARA__DevEndp, EP_BULK_OUT_DEF  ; For massives OUT = 1
        cmp_____USB_type__UHCI_OHCI_EHCI        ; for XD = 2
.UHCI:
        exit
.OHCI:
        and     PARA__CtrlByte, not DIRECTION__IN ; Set Write direction
        call    bud_Bulk
        exit
.EHCI:
.exit:
        ret


;[]============================================================[] bud_Bulk
;³ ToDo : Bulk Transfer
;ÀÄÄ>IN : ESI    = Buffer for transfer
;         ECX    = Size of transfer (in bytes)
;         PARA__DevEndp = 1 - for massives IN (6 for XD)
;                       = 2 - for massives OUT
;<--OUT : CF if error
;[]=====.=======|===============================*==============[]
bud_Bulk:
        mov     bSend_Type, BULK_TYPE           ; <--- !!! CHANGE for each type !!! ***
        mov     dUser_buffer__Size, ecx

        cmp_____USB_type__UHCI_OHCI_EHCI
.UHCI:
        exit
.OHCI:
;        mov     PARA__DataBuffer, si            ; Buffer
;        mov     PARA__TotalSize, cx             ; Size
        assume  PARA__MaxSize, PARA__BULK_MPS   ; by default MPS_BULK = 64 (40h) bytes
        LOG     "Bulk Transfer OHC"
        call    Bulk_Transfer_OHC
        exit
.EHCI:
.exit:
         ret

;[]============================================================[] cmd_to_xd
;³ ToDo : Send Comand to Xor-Device (Bulk Transfer)
;ÀÄÄ>IN : DL    = Command for send to Our Device
;<--OUT : CF    if error
;[]=====.=======|===============================*==============[]
cmd_to_xd:
      pushad
        mov     bSH__Command, dl
        mov     wSH__Length, SHwLength

        LOG.b   "Send to XD: ", dl
        LOG.d   "Signature = ", dSH__Signature
        LOG.b   "CRC       = ", bSH__CRC
        LOG.b   "Command   = ", bSH__Command
        LOG.d   "ID        = ", dSH__ID

        cmp     dl, COMPLEATE_READ_PIN1
        jne     .CRP1_cmd

        mov     ax, 12;[CharCounter]
        add     wSH__Length, ax
_%
	mov	si, .login
	mov	ebx, 0
        LOG_  	"Login     = "
	mov	al, [es:vSH.SHbAuth]
.log:
	cmp	al, 0
	jz	@F

	mov	[si], al
	inc	si
	inc	ebx
	mov	al, [es:vSH.SHbAuth + ebx]
	jmp	.log

.login	db	16 dup 0	

@@:
	LOG^	.login
	LOG^	_BK
%_


.CRP1_cmd:
        LOG.w   "Length    = ", wSH__Length

        USB.write  SH, 64
.exit:
      popad
        ret
.error:
        exit

;[]============================================================[] Set_Default_SH
;³ ToDo : Set Default StapHeader
;ÀÄÄ>IN :
;<--OUT :
;[]=====.=======|===============================*==============[]
Set_Default_SH:
        Clear   SH

        mov     dSH__Signature, STAP_SIGNATURE
        mov     wSH__Length,    SHwLength
        mov     bSH__CRC,       SHbCRC

        ret

;[]============================================================[] Clear_32bit
;³ ToDo : Clear miscellaneous data buffer
;ÀÄÄ>IN : ES:ESI= pointer to data buffer
;         ECX   = length
;<--OUT : --
;[]=====.=======|===============================*==============[]
Clear_32bit:
        xor     al, al
        db      67h
        rep     stosb
        ret

;[]============================================================[] MD5_cheking
;³ ToDo : MD5-checking
;ÀÄÄ>IN :
;<--OUT : CF    = 0 - successful
;               = 1 - fail
;[]=====.=======|===============================*==============[]
CodeDB  dd      4791D161h
        dd      5BD1D004h
        dd      1DBB1C2Ah
        dd      97EB3636h
MD5_cheking:
      pushad
      push es
        mov     si, strcode
	mov	eax, dword [es:vSH.SHbAuth + 00]
	mov	[si + 00], eax
	mov	eax, dword [es:vSH.SHbAuth + 04]
	mov	[si + 04], eax
	mov	eax, dword [es:vSH.SHbAuth + 08]
	mov	[si + 08], eax
	mov	eax, dword [es:vSH.SHbAuth + 12]
	mov	[si + 12], eax

        LOG.d   "", dword [strcode + 00]
        LOG.d   "", dword [strcode + 04]
        LOG.d   "", dword [strcode + 08]
        LOG.d   "", dword [strcode + 12]

      push    strcode
      push    [strlen]
      push    digest
        call    MD5

        assume  es, ds                          ; ES = DS
        mov     si, CodeDB                      ; compare codes
        mov     di, digest
        mov     cx, 4
@@:                                             ; TestCode
        repe    cmpsd
        jcxz     .done
        jmp     .error
.done:
        clc
.exit:
      pop  es
      popad
        ret
.error:
        stc
        exit
