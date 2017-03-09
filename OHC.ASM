;[]============================================================[] Control_Transfer_OHC
;│ ToDo : Control Transfer OHC
;└──>IN : PARA  = point to CTLPARA (control parameter block)
;                   bCtrlByte contained low speed device information
;                   bParentAddr conatined upstream device address
;                   bParentPort contained upstream device port number
;<--OUT : CF if fail
;[]=====.=======|===============================*==============[]
Control_Transfer_OHC:
        LOG     "new ED_OHC/TD_OHC (DEF_CTRL), MPS = 8"
        mov     ax, TD_OHC__DEF_CTRL
        call    init_ED_TD_OHC
        mov     ED_OHC__MPS, 8                  ; MPS = 8 for SETUP transfer
.                                               ; debug pause
        LOG     "*** SETUP stage ***"
        TrOHC   REQ, 8                          ; send 8 bytes of Request

        cmp     dUser_buffer__Size, 0           ; Прием-передача данных, если поле wLength (wTotalSize) в запросе не ноль
        jz      .Status_Stage

        LOG     "*** DATA stage ***"
        assume  ED_OHC__MPS, PARA__MaxSize      ; Записываем в ED_OHC максимальный размер пакета
                ; Set direction for TD_OHC
        mov     ax, TD_OHC__CC_EC_T_DI_DP_R
        and     ax, not TD_OHC__DIRECTION_PID
        test    PARA__CtrlByte, DIRECTION__IN
        jnz     .IN
.OUT:
        or      ax, TD_OHC__PID_OUT
        jmp     @F
.IN:
        or      ax, TD_OHC__PID_IN
@@:
        mov     TD_OHC__CC_EC_T_DI_DP_R, ax

        TrOHC   edi, dUser_buffer__Size         ; Always use EDI as Destination

.Status_Stage:                                  ; cтадия состояния - устройство подтверждает успешное выполнение
        LOG     "*** STATUS stage ***"          ; пакетом ACK или отвергает его пакетом STALL
        mov     ax, TD_OHC__CC_EC_T_DI_DP_R     ; Change Direction for TD_OHC:
        and     ax, not TD_OHC__DIRECTION_PID
        cmp     REQ__Length, 0              	; Если этапе передачи данных не было совсем  (No-data Control)
        jz      .IN2                            ; - ставим PID_IN
        test    PARA__CtrlByte, DIRECTION__IN   ; Если на этапе передачи данных шла передача (Control Write)
        jz      .IN2                            ; - ставим PID_IN
        or      ax, TD_OHC__PID_OUT             ; Если на этапе передачи данных шел прием    (Control Read)
        jmp     @F                              ; - ставим PID_OUT
.IN2:
        or      ax, TD_OHC__PID_IN
@@:
        or      ax, TD_OHC__DATOGLSB            ; terminated with DATA1 (DATOGLSB = 00100H)
        mov     TD_OHC__CC_EC_T_DI_DP_R, ax     ; Дополнительно переключаем поле T (DataToggle)
                                                ; на фазу Status (T = 11b, было 10b, теперь плюс "or 01b")

;        mov     ED_OHC__MPS, 8                  ; MPS = 8 for SETUP transfer
        TrOHC   0, 0                            ; Send NULL-packet
.done:
        clc
.exit:
        call    End_Transfer
        ret
.error:
        LOG     "Bad Transfer, ERROR!"
  _HC.if errors.SHOW_INFO
  _TD.if errors.SHOW_INFO
        stc
        exit

;[]============================================================[] init_ED_TD_OHC
;│ ToDo : Create and init new ED_OHC, TD_OHC
;└──>IN : AX    - DEF TD
;       : EBP   = TD_OHC_buffer
;       : ED_OHC__MPS = Maximum Packet Size
;<--OUT :
;[]=====.=======|===============================*==============[]
init_ED_TD_OHC:
      push ebp                                  ; off_TD_OHC
.init_TD:                                       ; Clear TD and set Defaults:
        mov     TD_OHC__CC_EC_T_DI_DP_R, ax     ; Set wTdControl by AX: (это именно слово, первое слово от DD используется Авардом для Task)
                ;                               CTRL(0F2E4H)|BULK_OUT (0F0ECH)|BULK_IN (0F0F4H)
                ;Buffer rounding    = 1 ------------------------------------------------------
                ;PID                            00 (SETUP)  |01 (OUT)         |10 (IN)
                ;no delay interrupt = 000 ----------------------------------------------------
                ;use TD's data toggle           10 (SETUP)  |      00 (BULK/INTERRUPT)
                ;Error Count        = 00 -----------------------------------------------------
                ;Condition Code     = 1111/NOTACCESSED (не было обработки) -------------------
        mov     wTD_OHC__Task, 0
        mov     TD_OHC__CBP, 0
        mov     TD_OHC__NextTD, TD_OHC_dummy
        mov     TD_OHC__BE, 0
        add     ebp, TD_OHC.size                ; reg_TD = ebp
        cmp     ebp, TD_OHC_buffer + TD_OHC_buffer.size ; TD_OHC_dummy is end of TD_OHC_buffer !!!
        jb      .init_TD
      pop  ebp
.init_ED:                                       ; Set wEdControl:
        movzx   ax, PARA__DevEndp               ; EN (EndpointAddress) - EP Number
        shl     ax, ED_OHC__BIT_EN              ; bit-offset EN
        or      al, PARA__DevAddr               ; FA (Function Address) - bDevAddr - contained device address

        test    PARA__CtrlByte, LOW_SPEED
        jz      @f
        or      ax, ED_OHC__SPEED               ; S (Speed): 0 - FS(FullSpeed), 1 - LS(LowSpeed)
@@:
        mov     ED_OHC__F_K_S_D_EN_FA, ax       ; Direction = 0 (take from TD_OHC), sKip = 0 (not skip)

        assume  ED_OHC__MPS, PARA__MaxSize      ; Set default MPS (Maximum Packet Size) for current EP
        mov     ED_OHC__NextED, 0               ; Last ED
        mov     ED_OHC__TailP, TD_OHC_dummy
        mov     ED_OHC__HeadP, TD_OHC_dummy     ; Link ED to Empty queue (TailP = HeadP)
        ret

;[]============================================================[] Send_Data_OHC
;│ ToDo : Send Data Loop (if PARA__TotalSize>PARA__MaxSize)
;└──>IN : EAX   = pointer to DATA-buffer
;       : TD_OHC__CBP = pointer to TD Buffer
;       : ECX   = Sending_Size
;<--OUT : CF if fail (transaction error or time-out)
;[]=====.=======|===============================*==============[]
Send_Data_OHC:
      pushad
        mov     esi, 8192;PARA__MaxSize         ; Now = PARA__MaxSize (next try 8192)
        mov     bx, TD_OHC__CC_EC_T_DI_DP_R
        or      bh, 0f0h
;       mov     bh, 0
      push ebp
.next_TD_in_Queue:
        cmp     ecx, esi
        jbe     .last_TD_in_Queue

        mov     TD_OHC__CC_EC_T_DI_DP_R, bx
;       mov     bh, 3

        mov     TD_OHC__CBP, eax                ; Set Begin Buffer

        add     eax, esi
        sub     ecx, esi
        dec     eax                             ; TD_OHC__BE = TD_OHC__CBP + Sending_Size - 1
        mov     TD_OHC__BE, eax                 ; Set End Buffer
        inc     eax

        mov     TD_OHC__NextTD, ebp             ; Set NextTD offset
        add     TD_OHC__NextTD, TD_OHC.size


;_w@ TD_OHC__CC_EC_T_DI_DP_R
;_d@ TD_OHC__CBP
;_d@ TD_OHC__NextTD
;_d_ TD_OHC__BE

        add     ebp, TD_OHC.size                ; reg_TD = ebp

        jmp     .next_TD_in_Queue

.last_TD_in_Queue:
        mov     TD_OHC__CC_EC_T_DI_DP_R, bx
        mov     TD_OHC__CBP, eax                ; Set Begin Buffer

        cmp     ecx, 0
        jz      @F

        add     eax, ecx
        dec     eax
@@:
        mov     TD_OHC__BE, eax                 ; Set End Buffer
.send:
        mov     TD_OHC__NextTD, TD_OHC_dummy
      pop  ebp
        LOG     "Link_ED, Wait_Ack"
        call    Link_ED
        call    Wait_Ack
        jc      .error
.done:
        clc
.exit:
  _TD.if DEBUG
      popad
        ret
.error:
        LOG     "Transaction OHC Error!"
        call    GetLastError
        LOG^    si
        LOG^    _BK

        stc
        exit

;[]============================================================[] Link_ControlED
;│ ToDo : Link ED_OHC to HcControlHeadED or to HcBulkHeadED
;│        and link TD_OHC to ED_OHC
;└──>IN : [Send_Type] = CONTROL_TYPE
;                     = BULK_TYPE
;<--OUT : --
;[]=====.=======|===============================*==============[]
Link_ED:
        call    Send_List.Disable               ; Disable Control/Bulk operations for set parameters

        mov     eax, ED_OHC_buffer
        cmp     bSend_Type, CONTROL_TYPE        ; link ED_OHC to...
        je     .Control
.Bulk:                                          ;...HcBulkHeadED for BULK
        set_OHC HcBulkHeadED, eax               ; Linear of FIRST ED_OHC, (bits [3:0]), set by DRIVER
        set_OHC HcBulkCurrentED, eax            ; Linear of CURRENT ED_OHC, (bits [3:0]), set by CONTROLLER
        jmp     @F
.Control:                                       ;...HcControlHeadED for CONTROL
        set_OHC HcControlHeadED, eax            ; Linear of FIRST ED_OHC, (bits [3:0]), set by DRIVER
        set_OHC HcControlCurrentED,  eax        ; Linear of CURRENT ED_OHC, (bits [3:0]), set by CONTROLLER

@@:
        mov     ED_OHC__HeadP,  TD_OHC_buffer   ; link TD_OHC to ED_OHC
        mov     ED_OHC__TailP,  TD_OHC_dummy
;        mov     TD_OHC__NextTD, TD_OHC_dummy

  ;_HC.if DEBUG
  _TD.if DEBUG
        call    Send_List.Enable                ; Enable Control/Bulk operations
  ;_TD.if DEBUG
  ;_HC.if DEBUG
        ret

;[]============================================================[] Send_List
;│ ToDo : Control/Bulk List Disable/Enable
;└──>IN : [Send_Type] = CONTROL_TYPE
;                     = BULK_TYPE
;<--OUT : --
;[]=====.=======|===============================*==============[]
Send_List:
.Disable:
        cmp     bSend_Type, CONTROL_TYPE
        je      @F
        and_OHC HcControl, not HcControl__BLE   ; Bulk List Enabled=0
        cmd_and_OHC  not HcCommandStatus__BLF   ; Bulk List Filled=0
        ret
@@:
        and_OHC HcControl, not HcControl__CLE   ; Control List Enabled=0
        cmd_and_OHC  not HcCommandStatus__CLF   ; Control List Filled=0
        ret
.Enable:
        cmp     bSend_Type, CONTROL_TYPE
        je      @F
        cmd_or_OHC   HcCommandStatus__BLF       ; Bulk List Enabled
        or_OHC  HcControl, HcControl__BLE       ; Bulk List Filled
        ret
@@:
        cmd_or_OHC   HcCommandStatus__CLF       ; Control List Enabled
        or_OHC  HcControl, HcControl__CLE       ; Control List Filled
        ret

;[]============================================================[] End_Transfer
;│ ToDo : Ending Operations (Store Flags)
;└──>IN : [Send_Type] = CONTROL_TYPE
;                     = BULK_TYPE
;<--OUT : --
;[]=====.=======|===============================*==============[]
End_Transfer:
      pushf                                     ; store flags for exit with correct error-code
        set_OHC HcDoneHead, 0                   ; Reset DoneHead
        call    Send_List.Disable               ; Disable Control/Bulk List
      popf
        ret

;[]============================================================[] Wait_Ack
;│ ToDo : Wait transaction acknowledge
;└──>IN : SI = point to TD
;<--OUT : CF if fail (transaction error or time-out)
;[]=====.=======|===============================*==============[]
Wait_Ack:
        mov     cx, WAIT_ACK_COUNT
.Loop:
        mov     eax, ED_OHC__HeadP
        and     al, 0f0h
        cmp     eax, ED_OHC__TailP
        jne     @f

        test    TD_OHC__CC_EC_T_DI_DP_R, TD_OHC__CC ; check ConditionCode-field
        jz      .done                           ; if error - exit only by WAIT_ACK_COUNT time-out
@@:
.                                               ; 1ms delay
        loop    .Loop
.error:
        stc
        exit
.done:
        clc
.exit:
        ret

;[]============================================================[] Bulk_Transfer_OHC
;│ ToDo : Bulk_Transfer_OHC
;└──>IN : --
;       :
;<--OUT : CF if fail
;[]=====.=======|===============================*==============[]
Bulk_Transfer_OHC:
        LOG     "Create new_ED_OHC, TD_OHC (DEF_BULK)"
        mov     ax, TD_OHC__DEF_BULK_IN         ; DEF_BULK_IN by def
        test    PARA__CtrlByte, DIRECTION__IN
        jnz     @f
        mov     ax, TD_OHC__DEF_BULK_OUT        ; DEF_BULK_OUT if bud_w
@@:
        call    init_ED_TD_OHC

        LOG     "*** DATA stage ***"
        test    PARA__CtrlByte, DIRECTION__IN
        jnz     .IN
.OUT:
        TrOHC   esi, dUser_buffer__Size         ; Read/Write ECX bytes to/from ESI-buffer
        LOG     "*** NullPacket stage ***"      ; For DIRECTION__OUT send null-packet after last packet
        TrOHC   0, 0                            ; Send NULL-packet
        jmp     .done
.IN:
        TrOHC   esi, dUser_buffer__Size         ; Read/Write ECX bytes to/from ESI-buffer

                                                ; !!!! only for test version !!!!
.done:                                          ; check ".last_TD_in_Queue" for future
        clc
.exit:
        call    End_Transfer
        ret
.error:
        LOG     "Bad Bulk Transfer!"
;  _HC
;  _TD
        stc
        exit
