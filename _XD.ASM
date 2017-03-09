MODE =  0;debug_log.ON + run_in.DOS + file.INCLUDE + SHOW_INFO + SHOW_STATUS
include 'equ.equ'                               ; include _all_ equ-files + errors.SHOW_INFO
org     100h
;[]============================================================[] xd
;ToDo:  XD Programming
;       : ECX   = Size of Transfer
;       : EDX   = Use as Rx of HostController
;       : ESI   = Pointer to User Buffer (PARA__DataBuffer)
;       : EDI   = Pointer to Current Work Buffer
;       : EBP   = Pointer to TD_Array Buffer
;[]=====.=======|===============================*==============[]
xd:
      push.all
        assume  ds, cs                          ; DS = CS
        assume  es, 0                           ; ES = 0, don`t removing from start position!!!

        Store_Video_mode
        cls

        LOG.create "_xd.log"
        LOG     "Start the programm."

        LOG     "Go to linear-mode."
        call    FlatMode.on

        call    Set_new_int_09h

        mov     byte ptr edi, DATA_buffer                ; main base-offset in extended memory (DATA_buffer)
        mov     ebp, TD_OHC_buffer              ; TD

        LOG     "Start BUD."
        call    bud                             ; USB-controller init, search&init device
        jc      .System_Halted;.error

        LOG     "################## Set EP6.size = 64 bytes."
        USB_Req rxd_Set_BufSize64
        LOG     "################## Clear buffer in XD."
        USB_Req rxd_Clear_Buffer

        mov     bLogon_Error_Counter, MAX_LOGON_ERRORS

.READ_PIN1:
        call    Set_Default_SH
        LOG     "****************************************************"
        LOG     "***************** READ PIN 1 ***********************"
        LOG     "****************************************************"
        USB_xd  READ_PIN1, .error               ; send command 89h to XD
        cls

PRINT   "Enter Login and input key then press Enter."

        call    Enter_Login                     ; Enter login
        LOG     "****************************************************"
        LOG     "************** COMPLEATE READ PIN 1 ****************"
        LOG     "****************************************************"
        USB_xd  COMPLEATE_READ_PIN1, .AccessEr  ; send command 8ah to XD

        LOG     "****************************************************"
        LOG     "***************** READ PIN 2 ***********************"
        LOG     "****************************************************"
        USB_xd  READ_PIN2, .AccessEr            ; send command 8bh to XD

        LOG     "----------------- MD5_cheking ----------------------"
        call    MD5_cheking
        jnc    .AccessOk

.AccessEr:
        dec     bLogon_Error_Counter
        jz     .System_Halted
        cls
        LOG.b   "once trying = ", bLogon_Error_Counter

PRINT   "Access denied!"

...
        LOG     "*************************"
        LOG     "*** CANCEL READ PIN 1 ***"
        LOG     "*************************"
        USB_xd  CANCEL_READ_PIN1, .error
        jmp     .READ_PIN1

.System_Halted:
        ;cls

PRINT   "System halted. Press RESET button..."

@@:
        test    bFlag, Flag__Press_ENTER_BS_F10
        jz      @B

        cmp     bScanCode, ScanCode.F10
        jne     @B
        exit

.AccessOk:
        LOG     "Restore BufSize to 512bytes for correct running USB 2.0"
        USB_Req rxd_Set_BufSize512

PRINT   "Successful!"

        ;Clear   PROGRAMM_buffer
        ;call    Stop_Host
.exit:
;        Restore_Video_mode
        LOG     "back to real-mode"
        call    FlatMode.off
        call    Restore_old_int_09h

PRINT   "EXIT!"

        LOG.close
      pop.all
        retf    ;ret <---- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

;int 20h
.quit:
        mov     ax, 4c00h
        int     21h

;[]=====.=======|===============================*==============[]
.stop:
 BK
        LOG     "Exit by Stop."
        exit
.error:
        LOG     "Exit by ERROR!"
        exit

;[]=====.=======|===============================*==============[]
include 'bud.asm'
include 'kbd.asm'
;[]=====.=======|===============================*==============[]
