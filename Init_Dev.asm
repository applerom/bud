;include 'OHC_Ctrl.asm'                          ; OHC Control Transfer module
;include 'OHC_Bulk.asm'                          ; OHC Bulk Transfer module
include 'OHC.asm'                               ; OHC Bulk Transfer module
;[]============================================================[] Init_Device
;³ ToDo : Get device descriptor and set address for attached device
;ÀÄÄ>IN : PARA  = point to CTLPARA (control parameter block)
;<--OUT : CF if fail
;[]=====.=======|===============================*==============[]
Init_Device:
...
;        mov     PARA__DevAddr, 1
        mov     bl, 10
        LOG.b   ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Set Device Address ", bl
        cr_REQ  req_Set_Address
        mov     REQ__Value_lo, bl               ; Set device address
        Send_REQ                                ; null data control transfer

        mov     PARA__DevAddr, bl

;        mov     PARA__CTRL_MPS, 64
        LOG     ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Get Device Descriptor (8 bytes)"
        RC__ts  req_Get_DD, 8                   ; only 8 bytes
        mov_wb  PARA__CTRL_MPS, [es:vDD_buffer.DDbMaxPackSize] ; Store default CTRL_MPS
        LOG.b   "Set CTRL_MPS to ", [es:vDD_buffer.DDbMaxPackSize]

        LOG.b   ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Get Device Descriptor, LEN = ", [es:vDD_buffer.DDbLength]
        mov_wb  REQ__Length, [es:vDD_buffer.DDbLength] ; total length of DD
        Send_REQ
.done:
        clc
.exit:
        ret
.error:
        stc
        exit

;[]============================================================[] Init_Config
;³ ToDo : Get configuration descriptor
;³        and set configuration for BIOS supported device
;ÀÄÄ>IN : BX = point to control parameter block
;<--OUT : CF if fail
;[]=====.=======|===============================*==============[]
Init_Config:
        ; First time to get Config Descriptor (8 bytes)
        LOG     ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Get Configuration Descriptor (8 bytes)"
        RC__ts  req_Get_CD, 8                   ; only 8 bytes

        ; Second time to get configuration (CFGDSP + INTDSP + ENDPDSP) descriptor (total bytes)
        LOG.w   ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Get Configuration Descriptor, LEN = ", [es:vCD_buffer.CDwTotalLen]
        assume  REQ__Length, [es:vCD_buffer.CDwTotalLen]     ; total length
        Send_REQ                                ; get CFG+INT+ENDP descriptors
_%
        call    Display_Descriptors
	LOG^	_BK
%_ 
               ;.Init_BIOS_Device_Loop:
                ;        cmp     al, [vID_buffer.IDbClass]
                ;        cmp     al, [vID_buffer.IDbSubClass]
                ;        cmp     al, [vID_buffer.IDbProtocol]
                ;.BIOS_Device_Found:

        ; Set configuration
        LOG.b   ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Set Default configuration ", [es:vCD_buffer.CDbCfgValue]
        cr_REQ  req_Set_Config
        mov_bb  REQ__Value_lo, [es:vCD_buffer.CDbCfgValue] ; set defaul config Value
        Send_REQ

                ; Call corresponding procedure to initialize BIOS devices
                ;.Init_Config_Next:
                ;        inc     cl                              ;next configuration
                ;        cmp     cl, [vDD_buffer.DDbNumConfig]  ;number of config
                ;        jb      .main_loop
.done:
                ; Resume all tasks after Control Transfer
;        and_OHC HcControl, HcControl__PLE
        or_OHC  HcInterruptEnable, HcInterruptEnable__ENAB_WDH ; Write back DoneHead

        clc                  ;BIOS_Device:
.exit:                       ;               Class, SubClass, Protocol
        ret                  ;        db      09, 0FFh, 0FFh                  ;Hub
.error:                      ;        db      03, 01, 01                      ;Keyboard
        stc
        exit
