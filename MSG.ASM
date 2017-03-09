;[]============================================================[] _show_status
;³ ToDo : show_info
;ÀÄÄ>IN :
;<--OUT :
;[]=====.=======|===============================*==============[]
_show_status:
      pushf
      pushad
;BK
;jmp    .exit   ; skip
        mov     si, Rx_OHC_TBL
.loop:
        lodsw
        cmp     ax, 0
        jz      .exit
        LOG^    ax
        lodsw
        movzx   ebx, ax
        get_OHC ebx
        LOG.d@  "= ", eax
        jmp     .loop
.exit:
        LOG^    _BK
      popad
      popf
        ret

Rx_OHC_TBL:
dw      _HcFmNumber              ,  HcFmNumber
;dw      _HcRevision              ,  HcRevision
dw      _HcControl               ,  HcControl
;dw      _HcCommandStatus         ,  HcCommandStatus
;dw      _HcInterruptStatus       ,  HcInterruptStatus
;dw      _HcInterruptEnable       ,  HcInterruptEnable
;dw      _HcInterruptDisable      ,  HcInterruptDisable
;dw      _HcHCCA                  ,  HcHCCA
;dw      _HcPeriodCurrentED       ,  HcPeriodCurrentED
dw      _HcControlHeadED         ,  HcControlHeadED
;dw      _HcControlCurrentED      ,  HcControlCurrentED
dw      _HcBulkHeadED            ,  HcBulkHeadED
;dw      _HcBulkCurrentED         ,  HcBulkCurrentED
dw      _HcDoneHead              ,  HcDoneHead
;dw      _HcFmInterval            ,  HcFmInterval
;dw      _HcFmRemaining           ,  HcFmRemaining
;dw      _HcPeriodicStart         ,  HcPeriodicStart
;dw      _HcLSThreshold           ,  HcLSThreshold
;dw      _HcRhDescriptorA         ,  HcRhDescriptorA
;dw      _HcRhDescriptorB         ,  HcRhDescriptorB
;dw      _HcRhStatus              ,  HcRhStatus
dw      _HcRhPortStatus1         ,  HcRhPortStatus1
dw      _HcRhPortStatus2         ,  HcRhPortStatus2
dw      _HcRhPortStatus3         ,  HcRhPortStatus3
dw      0
dz      _HcRevision                      , "HcRevision "
dz      _HcControl                       , "HcControl "
dz      _HcCommandStatus                 , "HcCommandStatus "
dz      _HcInterruptStatus               , "HcInterruptStatus "
dz      _HcInterruptEnable               , "HcInterruptEnable "
dz      _HcInterruptDisable              , "HcInterruptDisable "
dz      _HcHCCA                          , "HcHCCA "
dz      _HcPeriodCurrentED               , "HcPeriodCurrentED "
dz      _HcControlHeadED                 , "HcControlHeadED "
dz      _HcControlCurrentED              , "HcControlCurrentED "
dz      _HcBulkHeadED                    , "HcBulkHeadED "
dz      _HcBulkCurrentED                 , "HcBulkCurrentED "
dz      _HcDoneHead                      , "HcDoneHead "
dz      _HcFmInterval                    , "HcFmInterval "
dz      _HcFmRemaining                   , "HcFmRemaining "
dz      _HcFmNumber                      , "HcFmNumber "
dz      _HcPeriodicStart                 , "HcPeriodicStart "
dz      _HcLSThreshold                   , "HcLSThreshold "
dz      _HcRhDescriptorA                 , "HcRhDescriptorA "
dz      _HcRhDescriptorB                 , "HcRhDescriptorB "
dz      _HcRhStatus                      , "HcRhStatus "
dz      _HcRhPortStatus1                 , "HcRhPortStatus1 "
dz      _HcRhPortStatus2                 , "HcRhPortStatus2 "
dz      _HcRhPortStatus3                 , "HcRhPortStatus3 "

;[]============================================================[] _show_info
;³ ToDo : show_info
;ÀÄÄ>IN :
;<--OUT :
;[]=====.=======|===============================*==============[]
ED_OHC_Direction_TBL:
dw      ED_OHC_Direction_00
dw      ED_OHC_Direction_01
dw      ED_OHC_Direction_10
dw      ED_OHC_Direction_11

dz      ED_OHC_Direction_00             , "TD"
dz      ED_OHC_Direction_01             , "OUT"
dz      ED_OHC_Direction_10             , "IN"
dz      ED_OHC_Direction_11             , "TD"

TD_OHC_Direction_TBL:
dw      TD_OHC_Direction_00
dw      TD_OHC_Direction_01
dw      TD_OHC_Direction_10
dw      TD_OHC_Direction_11

dz      TD_OHC_Direction_00             , "SETUP"
dz      TD_OHC_Direction_01             , "OUT"
dz      TD_OHC_Direction_10             , "IN"
dz      TD_OHC_Direction_11             , "reserved"


_BK     db      0dh, 0ah, 0
dz      _tochka                         , ". "
dz      _comma                          , ", "
dz      _space                          , " "
dz      _dvoetochie                     , ": "

_show_info:
      pushf
      pushad

        LOG.w@  "ED OHC: ", ED_OHC__F_K_S_D_EN_FA
        LOG.d@  "", ED_OHC__HeadP
        LOG.d@  "", ED_OHC__TailP
        LOG.d@  "", ED_OHC__NextED

        mov     ax, ED_OHC__F_K_S_D_EN_FA
        and     al, ED_OHC__FA
        LOG.b@  "FA=", al

        mov     ax, ED_OHC__F_K_S_D_EN_FA
        and     ax, ED_OHC__EN
        shr     ax, ED_OHC__BIT_EN
        LOG.b@  "EN=", al

        mov     si, ED_OHC__F_K_S_D_EN_FA
        and     si, ED_OHC__DIR
        shr     si, ED_OHC__BIT_DIR - 1

        add     si, ED_OHC_Direction_TBL
        LOG_^   "", [si]

        mov     ax, ED_OHC__F_K_S_D_EN_FA
        test    ax, ED_OHC__SPEED
        jnz     .low_speed
        LOG@    "FS"
        jmp     @F
.low_speed:
        LOG@    "LowSpeed"
@@:

        LOG.w   "MPS=", ED_OHC__MPS

;        LOG_   "TailP="
;        cmp     ED_OHC__TailP, TD_OHC_dummy
;        jne     @F
;        LOG@    "*dummy*"
;        jmp     .skip_ED_OHC__TailP
;@@:
;        LOG.d@  "", ED_OHC__TailP
;.skip_ED_OHC__TailP:

        mov     eax, ED_OHC__HeadP
        test    al, 1
        jz      @F
        LOG     "                     EP is HALTED !!!"
@@:

;        mov     eax, ED_OHC__HeadP
;        and     al, 2
;        shr     al, 1
;        LOG.b@  "C=", al
;@@:

;        LOG_   "HeadP="
;        mov     eax, ED_OHC__HeadP
;        and     al, 0f0h
;        cmp     eax, TD_OHC_dummy
;        jne     @F
;        LOG     "*dummy*"
;        jmp     .skip_ED_OHC__HeadP
;@@:
;        LOG.d   "", eax
;.skip_ED_OHC__HeadP:

;        LOG.d   "NextED = ", ED_OHC__NextED

;        mov     ebp, TD_OHC_buffer
      push    ebp
        mov     cx, 0
.loop_TD:
        LOG.w@  "TD OHC: ", TD_OHC__CC_EC_T_DI_DP_R
        LOG.d@  "", TD_OHC__CBP
        LOG.d@  "", TD_OHC__BE
        LOG.d@  "", TD_OHC__NextTD

        mov     si, TD_OHC__CC_EC_T_DI_DP_R
        and     si, TD_OHC__DIRECTION_PID
        shr     si, TD_OHC__BIT_DP-1

        add     si, TD_OHC_Direction_TBL
        LOG_^   "", [si]

        mov     ax, TD_OHC__CC_EC_T_DI_DP_R
        and     ax, TD_OHC__DATATOGGLE
        shr     ax, TD_OHC__BIT_DATATOGGLE
        LOG.b@  "T=", al

        mov     eax, TD_OHC__NextTD
        and     al, 0f0h
        cmp     eax, TD_OHC_dummy
        jne     @F
;        LOG_    "NextTD=*dummy*"
@@:
        LOG^    _BK
        cmp     eax, 0
        jz      .skip_TD_OHC__NextTD

        cmp     TD_OHC__CBP, 0
        jz      .skip_TD_OHC__NextTD

        mov     ebp, TD_OHC__NextTD
        cmp     ebp, TD_OHC_dummy
        je      .skip_TD_OHC__NextTD

        inc     cx
        cmp     cx, 8
        jbe     .loop_TD
.skip_TD_OHC__NextTD:
      pop     ebp

        LOG.b@  "Req "  , REQ__Request

        test    REQ__Type, FROM_DEV_STD
        jz      .req_out
        LOG@    "IN"
        jmp     @F
.req_out:
        LOG@    "OUT"
@@:
        LOG.w@  "Val "  , REQ__Value
        LOG.w@  "Ind "  , REQ__Index
        LOG.w@  "LEN="  , REQ__Length

;        LOG.b@  "PARA: " , PARA__CtrlByte
;        LOG.b@  "DevAddr "  , PARA__DevAddr
;        LOG.b@  "DevEndp "  , PARA__DevEndp
;        LOG.w@  "MaxSize "  , PARA__MaxSize

        call    GetLastError
        LOG.b@  "Error ", al
        LOG^    si

.exit:
        LOG^    _BK
        LOG^    _BK
popad
popf
        ret

;[]============================================================[] Create_File
;³ ToDo : Create File
;ÀÄÄ>IN : DS:SI = FileName (ZeroEnd)
;<--OUT : CF if error
;         AX    = Handle (if no error)
;[]=====.=======|===============================*==============[]
Create_File:
     push cx dx
        mov     dx, si
        mov     cx, 20h                         ;20H Archive bit
        mov     ah, 3ch
        int     21h
        jc      .error
.exit:
     pop  dx cx
        ret
.error:
        LOG     "Error Create_File!"
        stop.error

;[]============================================================[] Close_File
;³ ToDo : Close File
;ÀÄÄ>IN : AX    = Handle
;<--OUT : CF if error
;[]=====.=======|===============================*==============[]
Close_File:
     push bx
        mov     bx, ax
        mov     ah, 3eh
        int     21h
        jc      .error
.exit:
     pop  bx
        ret
.error:
        LOG     "Error Close_File!"
        exit

;[]============================================================[] Write_File
;³ ToDo : Write String to File
;ÀÄÄ>IN : AX    = Handle
;         DS:SI = String for write (ZeroEnd)
;<--OUT : CF if error
;[]=====.=======|===============================*==============[]
Write_String_to_File:
     push bx cx dx si
        mov     bx, ax                          ;file handle -> bx
        mov     dx, si

        xor     cx, cx
.count_str_len:
        lodsb
        or      al, al
        jz      @F
        inc     cx
        jmp     .count_str_len
@@:
        mov     ah, 40h
        int     21h
        jc      .error
.exit:
     pop  si dx cx bx
        ret
.error:
        LOG     "Error Write_String_to_File!"
        exit

;[]============================================================[] Create_File
;³ ToDo : LOG-File Functions
;ÀÄÄ>IN : DS:SI = String (ZeroEnd)
;<--OUT : CF if error
;[]=====.=======|===============================*==============[]
wLOG_FileID     equ     [LOG_FileID]
zw      LOG_FileID
LOG_file:
.write:
        mov     ax, wLOG_FileID
        call    Write_String_to_File
        call    vyvod
        exit
.create:
;        mov     si, LOG_FileName
        call    Create_File
        mov     wLOG_FileID, ax
        exit
.close:
        mov     ax, wLOG_FileID
        cmp     ax, 0
        jz      .exit
        call    Close_File
.exit:
        ret

;[]============================================================[] convert
;³ ToDo : Convert Byte/Word/Dword to DS:SI-string
;ÀÄÄ>IN : AL/AX/EAX = Byte/Word/Dword for convert
;<--OUT : DS:SI = pointer to string (with converted data for output)
;[]=====.=======|===============================*==============[]
convert:
        and     al, 0fh
        cmp     al, 10
        jb      @F
        add     al, 7
@@:
        add     al, 30h
        mov     [si], al
        exit

.byte   dw      0                               ; for log byte-var
        db      0
.word   dw      0, 0                            ; for log word-var
        db      0
.dword  dw      0, 0, 0, 0                      ; for log dword-var
        db      0

.al:
        mov     si, .byte
.do_byte:
      pusha
      push ax
        shr     al, 4
        call    convert
      pop  ax
        inc     si
        call    convert
      popa
        exit
.ax:
        mov     si, .word
.do_word:
      pusha
      push ax
        shr     ax, 8
        call    .do_byte
      pop  ax
        add     si, 2
        call    .do_byte
      popa
        exit
.eax:
        mov     si, .dword
      pushad
      push eax
        shr     eax, 16
        call    .do_word
      pop  eax
        add     si, 4
        call    .do_word
      popad
.exit:
        ret

;[]============================================================[] convert
;³ ToDo : Convert Byte/Word/Dword to DS:SI-string
;ÀÄÄ>IN : AL/AX/EAX = Byte/Word/Dword for convert
;<--OUT : DS:SI = pointer to string (with converted data for output)
;[]=====.=======|===============================*==============[]
Display_Descriptors:
      pushad
.next_DSP:
        mov     si, .DSP_TBL
        mov     al, [es:edi]
        cmp     al, 0
        jz      .exit

        mov     al, [es:edi+1]

.search_DSP_type:
        cmp     [si], al
        je      @F
        add     si, 4
        cmp     byte [si], 0
        jnz     .search_DSP_type
@@:
        call    word [si + 2]
        jmp     .next_DSP

.UNKNOWN:
        LOG.b@  "Unknown Descriptor ", [es:edi + 1]
        LOG.b   "LEN ", [es:edi]
.exit_DSP:
;        LOG^    _BK
        movzx   eax, byte [es:edi]
        add     edi, eax
        ret

.DD:
        LOG.w@  "Device DSP ",   [es:vDD_buffer.DDbcdDevice]
        LOG.w@  "VID ",                 [es:vDD_buffer.DDidVendor]
        LOG.w@  "PID ",                 [es:vDD_buffer.DDidProduct]
        LOG.w@  "USB ver.",             [es:vDD_buffer.DDbcdUSB]
        LOG.b@  "Cl.",               [es:vDD_buffer.DDbDevClass]
        LOG.b@  "SubCl.",            [es:vDD_buffer.DDbDevSubClass]
        LOG.b@  "Protocol ",            [es:vDD_buffer.DDbDevProtocol]
        LOG.b@  "Manuf.",               [es:vDD_buffer.DDiManuf]
        LOG.b@  "Product ",             [es:vDD_buffer.DDiProduct]
        LOG.b@  "SerialNum.",           [es:vDD_buffer.DDiSerialNum]
        LOG.b@  "NumConfig ",           [es:vDD_buffer.DDbNumConfig]
        LOG.b@  "MPS ",                 [es:vDD_buffer.DDbMaxPackSize]
        LOG.b   "LEN ",                 [es:vDD_buffer.DDbLength]
        jmp     .exit_DSP

.CD:
        LOG.b@  "Config.DSP ",[es:vCD_buffer.CDbCfgValue]
        LOG.w@  "TotalLEN ",            [es:vCD_buffer.CDwTotalLen]
        LOG.b@  "NumInterfaces ",       [es:vCD_buffer.CDbNumInt]
        LOG.b@  "iStrDSP ",        [es:vCD_buffer.CDiConfig]

        test    [es:vCD_buffer.CDbmAttr], 40h
        jz      @F
        LOG@    "Self-Powered"
@@:
        test    [es:vCD_buffer.CDbmAttr], 20h
        jz      @F
        LOG@    "Remote WakeUp"
@@:
        LOG.b@  "MaxPower ",            [es:vCD_buffer.CDMaxPower]
        LOG.b   "LEN ",                 [es:vCD_buffer.CDbLength]
        jmp     .exit_DSP

.ID:
        LOG.b@  "Interface DSP ",[es:vID_buffer.IDbIntNum]
        LOG.b@  "AltSet ",             [es:vID_buffer.IDbAltSet]
        LOG.b@  "NumEPs ",             [es:vID_buffer.IDbNumEndp]
        LOG.b@  "Cl.",               [es:vID_buffer.IDbClass]
        LOG.b@  "SubCl.",            [es:vID_buffer.IDbSubClass]
        LOG.b@  "Protocol ",            [es:vID_buffer.IDbProtocol]
        LOG.b@  "iStrDSP ",        [es:vID_buffer.IDbIndex]
        LOG.b   "LEN ",                 [es:vID_buffer.IDbLength]
        jmp     .exit_DSP

.ED:
        LOG_    "DSP "
        mov     al,                     [es:vED_buffer.EDbEndpAddr]
        and     al, 0fh
        LOG.b@  "for EP", al
        test    [es:vED_buffer.EDbEndpAddr], 80h
        jz      .OUT
        LOG@    "IN"
        jmp     @F
.OUT:   LOG@    "OUT"
@@:     movzx   si,                     [es:vED_buffer.EDbmAttr]
        and     si, 3
        shl     si, 1
        add     si, .ED_Attr_TBL
        LOG_^   "", [si]
        LOG.w@  "MPS ",                 [es:vED_buffer.EDwMaxPackSize]
        LOG.b@  "Interval ",            [es:vED_buffer.EDbInterval]
        LOG.b   "LEN ",                 [es:vED_buffer.EDbLength]
        jmp     .exit_DSP

.HID:
        LOG.w@  "HID DSP ",      [es:vHID_buffer.HIDbcdHID]
        LOG.b@  "Country ",             [es:vHID_buffer.HIDbCountry]
        LOG.b@  "Class ",               [es:vHID_buffer.HIDbClassType]
        LOG.b@  "Num Class DSPs ",      [es:vHID_buffer.HIDbAvailable]
        LOG.w@  "Report LEN ",          [es:vHID_buffer.HIDwRptLength]
        LOG.b   "LEN ",                 [es:vHID_buffer.HIDbLength]
        jmp     .exit_DSP
.HUD:
        LOG_    "HUD DSP: "
        LOG.b@  "NumPort ",             [es:vHUD_buffer.HUDbNumPort]
        LOG.w@  "Delay ",               [es:vHUD_buffer.HUDbDelay]
        LOG.w@  "MaxCurrent ",          [es:vHUD_buffer.HUDbMaxCurrent]
        LOG.b@  "Removable ",           [es:vHUD_buffer.HUDbRemovable]
        LOG.b@  "PwrCtrl ",             [es:vHUD_buffer.HUDbPwrCtrl]
        LOG.b   "LEN ",                 [es:vHUD_buffer.HUDbLength]
        jmp     .exit_DSP

.exit:
      popad
        ret
.DSP_TBL:
dw      DEVICE_DESCRIPTOR,      .DD             ; 1
dw      CONFIG_DESCRIPTOR,      .CD             ; 2
;dw      STRING_DESCRIPTOR,      .SD             ; 3
dw      INTERFACE_DESCRIPTOR,   .ID             ; 4
dw      ENDPOINT_DESCRIPTOR,    .ED             ; 5
dw      HID_DESCRIPTOR,         .HID            ; 21h
dw      HUB_DESCRIPTOR,         .HUD            ; 29h
dw      0             ,         .UNKNOWN
.ED_Attr_TBL:
dw      .ED_Attr_TBL_00
dw      .ED_Attr_TBL_01
dw      .ED_Attr_TBL_10
dw      .ED_Attr_TBL_11

dz      .ED_Attr_TBL_00         , "CONTROL"
dz      .ED_Attr_TBL_01         , "ISOCHRONOUS"
dz      .ED_Attr_TBL_10         , "BULK"
dz      .ED_Attr_TBL_11         , "INTERRUPT"
