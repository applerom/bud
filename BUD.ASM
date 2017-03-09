;[]============================================================[] bud
;ToDo:  BUD (BIOS USB Driver) - Драйвер USB под BIOS
;Subs:  see "bud.cmt"
;[]=====.=======|===============================*==============[]
include 'bud_subs.asm'                          ; CTRL/BULK/"context"-subs
include 'other\PCI.asm'                         ; "PCI"-subs
include 'Init_Dev.asm'                          ; OHC interfce subs
;[]============================================================[] bud
;│ ToDo : Detect type and Init USB Controller
;└──>IN : PARA__DeviceID = Device ID for search/init
;<--OUT : CF if USB Controllers not found
;[]     | EDI   = Pointer to work Buffer (if error = 0)
;[]=====.=======|===============================*==============[]
bud:
        mov     bHost_N, 0                      ; Begin from host 0
.NextHost:
        LOG     "Search USB-controllers... "
        call    Find_USB                        ; Detect USB-controller (increment [Host_number] if found)
        jc      .error

        LOG     "Host initialization (Init FL, Reset, Set Operational State)."
        call    Host_Init

        LOG     "Start Host"
        call    Run_Host

        mov     bPort_N, 1                      ; Begin from Port 1
.check_port:
        call    Check_Port                      ; Check connection on port
        jnc     .some_device_at_port

        mov     bl, bPort_N
        cmp     bl, bNumber_Ports               ; check all ports at current host?
        jbe     .check_port

        call    Stop_Host                       ; Stop host if not found device on all ports of this host
        jmp     .NextHost

.some_device_at_port:                           ; Set Number for Device

        LOG.b   "Init Device ", PARA__DevAddr
        call    Init_Device                     ; Enumeration
        jc      .error

        LOG.d   "DeviceID for search       = ", PARA__DeviceID
_%
        call    Display_Descriptors
%_
        mov     eax, PARA__DeviceID
        cmp     eax, dword [es:vDD_buffer.DDidVendor] ; Check connected Device ID...
        jne      .check_port

        LOG     "Set Default Config for connected device."
        call    Init_Config
        jc      .error
.done:
        ;mov     si, DATA_buffer  -  in EDI - DATA_buffer
        clc
.exit:
        ret
.error:
        mov     edi, 0
        stc
        exit

;[]============================================================[] Find_USB
;│ ToDo : Find USB Controller and store main vars for detected type
;└──>IN : --
;<--OUT : CF    if not found any USB Controllers
;         if found - increment bHost_N
;[]=====.=======|===============================*==============[]
Find_USB:
        LOG.b   "Host ", bHost_N
        mov     bh, bHost_N                     ; current Host

        call    Detect.UHC                      ; Check Controller type by HCI_ID an Set it values
        jc      @F
        LOG     "Detect UHC "
        jmp     .found
@@:
        call    Detect.OHC                      ; Check Controller type by HCI_ID an Set it values
        jc      @F
        LOG     "Detect OHC "
        jmp     .found
@@:
;        call    Detect.EHC                      ; Check Controller type by HCI_ID an Set it values
        jc      .error
;        LOG     "Detect EHC "
.found:                                         ; in CX - PCI_address of founded USB-controller
        LOG.w   "Found at PCI address ", wUSB_PCI_Address
        LOG.d   "USB Base address = ", dUSB_Base_Address
  _HC
        inc     bHost_N                         ; inc number of founded hosts (for future search)
        clc
.exit:
        ret
.error:                                         ; 0C03020h/0C03010h/0C0300h ClassCode not found
        LOG     "Not found any USB-controllers!"
        stc
        exit

;[]============================================================[] Host_Init
;│ ToDo : Clear buffer and Init Frame List
;└──>IN : --
;<--OUT : --
;[]=====.=======|===============================*==============[]
Host_Init:
        call    Init_FL                         ; Init all data for Buffer/Descriptors
        call    Host_Reset                      ; Global Reset Host
        call    Set_USB_State                   ; Power On all Ports and Load Default Host Configuration
        ret

;[]============================================================[] Init_FL
;│ ToDo : Clear buffer and Init Frame List
;└──>IN : EDI = BASE_IN_EXTENDED_MEMORY
;<--OUT : --
;[]=====.=======|===============================*==============[]
Init_FL:
        xor     eax, eax                        ; EDI = BASE_IN_EXTENDED_MEMORY
        mov     ecx, SIZE_ALL_DATAS_IN_MEMORY/4 ; 8192/4 Clear 8kB of memory (4kB - for UHCI)
        db      67h
        rep     stosd

        mov     edi, FL_ADDRESS
        cmp_____USB_type__UHCI_OHCI_EHCI
.UHCI:
        ;linear_eax QH_buffer                    ; to QH_buffer with flags:
        mov     eax, QH_UHC__T                  ; Clear frame list -> Q=0, T=1
        mov     ecx, 1024                       ; All 1024 elements of FL
        db      67h
        rep     stosd
        exit
.OHCI:                                          ; Initialize Queue Head data block
        mov     dED_OHC_dummy__TailP, TD_OHC_dummy ; TD Queue Tail Pointer - указатель на конец очереди TD, если совпадает с HeadP - очередь пуста.
        mov     dED_OHC_dummy__HeadP, TD_OHC_dummy ; TD Queue Head Pointer - указатель на очередной TD, который должен быть исполнен для данной точки.
        or      wED_OHC_dummy__F_K_S_D_EN_FA, ED_OHC__SKIP ; K (sKip) - пропустить, не начинать транзакций с данной точкой.
        mov     eax, ED_OHC_dummy               ; Link each FL-element to QH_buffer
        mov     ecx, 32                         ; 32 interrupt lists
        db      67h
        rep     stosd

        exit
.EHCI:
.exit:
        mov     edi, DATA_buffer
        ret

;[]============================================================[] Host_Reset
;│ ToDo : Host Reset
;└──>IN : --
;<--OUT : --
;[]=====.=======|===============================*==============[]
Host_Reset:
        cmp_____USB_type__UHCI_OHCI_EHCI
.UHCI:
        cmd_UHC USBCMD__GRESET + USBCMD__MAX_PACKET ; Issue global reset and set maximum packet size to 64
..                                              ; Minimum delay time 10ms
        cmd_UHC USBCMD__MAX_PACKET              ; cancel Reset / max packet=64
        exit
.OHCI:
        cmd_or_OHC HcCommandStatus__HCR         ; HostControllerReset
@@:
        test    dHC, HcCommandStatus__HCR       ; in dHC (ES:EDI) - current RX - HcCommandStatus
        jnz     @B                              ; Wait for cancel Reset
        cmd_and_OHC not HcControl__HCFS         ; HostControllerFunctionalStatus
...                                             ; Minimum delay time 10ms
        exit
.EHCI:
        cmd_or_EHC HCRESET                      ; HostControllerReset
@@:
        test    dHC, HCRESET                    ; in dHC (ES:EDI) - current RX - USBCMD_EHCI
        jnz     @B                              ; Wait for cancel Reset
..                                              ; Minimum delay time 10ms
.exit:
        ret

;[]============================================================[] Set_USB_State
;│ ToDo : Set USB Operational State
;└──>IN : --
;<--OUT : --
;[]=====.=======|===============================*==============[]
Set_USB_State:
        cmp_____USB_type__UHCI_OHCI_EHCI
.UHCI:
        set_UHC USBSTS,  0FFFFh                 ; Clear USB Status Register - write clear
        set_UHC USBINTR, USBINTR__IOC           ; USB Interrupt Enable Register = interrupt on complete
        set_UHC FRNUM,   0                      ; Frame Number Register = Starting from frame 0
        set_UHC_dword    FRBASEADD, FL_ADDRESS  ; set FRBASEADD (Frame list base address)
        exit
.OHCI:
;        get_OHC HcControl                       ; Set host controller function state to USBOPERATIONAL
;        and     eax, not HcControl__HCFS        ; HostControllerFunctionalStatus
;        or      eax, USBOPERATIONAL + USBSMI
;        set_OHC HcControl, eax
;stop

        or_OHC  HcRhDescriptorA, HcPeriodicStart__PSM ; Turn on global power
        set_OHC HcRhDescriptorB, 0
        or_OHC  HcRhStatus, HcRhStatus__LPSC    ; LocalPowerStatusChange
...                                             ; Delay after global power on
        set_OHC HcHCCA, FL_ADDRESS              ; Set HCCA to FrameList
                                                ; Set HcFmInterval - frame parameters:
        set_OHC HcFmInterval, 27782EDFh         ; bits 30:16 - FSMPS (FSLargestDataPacket): 2778h = 10104
                                                ; значение максимального размера данных, загружаемое в счетчик Data Packet Counter в начале каждого кадра
                                                ; (счетчик отражает длину пакета данных, допустимую в текущий момент времени без переполнения планирования)
                                                ; bits 13:0 - FI (FrameInterval): 2EDFh = 11999 длительность кадра (в bt) (by def = 11999)
                                                ; Set HcPeriodicStart - момент начала обхода списка периодических транзакций PS (by def = FI*0.9):
        set_OHC HcPeriodicStart, 00002A27h      ; bits 13:0 HcPeriodicStart: 2A27h = 10791
                                                ; Контроллер приступает к периодическим транзакциям, когда FR достигает значения PS

        set_OHC HcInterruptEnable,  0C000007fh  ; Disable all USB int.
        set_OHC HcInterruptDisable, 0C000007fh  ; Disable all USB int.
;        set_OHC HcInterruptEnable, 0C000005bh   ; Disable all USB int.
;        set_OHC HcInterruptDisable, 0C000005bh  ; Disable all USB int.

        set_OHC HcControl, USBOPERATIONAL + USBSMI ; Set host controller function state to USBOPERATIONAL
        exit
.EHCI:
.exit:
        ret

;[]============================================================[] Check_Port
;│ ToDo : Check controller Port
;└──>IN : bPort_N - Port Number
;<--OUT : CF    if no connection on AL port
;[]=====.=======|===============================*==============[]
Check_Port:
        xor     ebx, ebx
        mov     bl, bPort_N                     ; Check Status Port bx/ebx
        inc     bPort_N
        dec     bl                              ; decrement for counting offset
        cmp_____USB_type__UHCI_OHCI_EHCI

.UHCI:
        shl     bl, 1                           ; 2 bytes for one port
        add     bx, PORTSC1                     ; PORTSC1 - first port RegStat
        get_UHC bx
        test    ax, PORTSCN__CURR_CONN          ; Current Connect Status   ;000Fh
        jz      .not_connection

        test    ax, PORTSCN__LOW_SPEED_DEV      ; check Low Speed Device (FS/HS-device by default)
        jz      @F
        or      PARA__CtrlByte, LOW_SPEED       ; Set LS-bit (чтобы использовать преамбулу перед подачей)
@@:
        jmp     .have_connection

.OHCI:
        shl     bl, 2                           ; 4 bytes for one port
        add     ebx, HcRhPortStatusN
        get_OHC ebx
        test    eax, HcRhPortStatusN__CCS       ; Current Connect Status (read)
        jz      .not_connection

        test    ax, HcRhPortStatusN__LSDA       ; check Low Speed Device (FS/HS-device by default)
        jz      @F
        or      PARA__CtrlByte, LOW_SPEED       ; Set LS-bit (чтобы использовать преамбулу перед подачей)
@@:
        jmp     .have_connection

.EHCI:
        shl     bl, 2                           ; 4 bytes for one port
        add     ebx, PORTSC0_EHCI
        get_EHC ebx
        test    eax, HcRhPortStatusN__CCS       ; Current Connect Status (read) <= CCS OHC=EHC
        jz      .not_connection

        test    eax, Port_Owner                 ; check Low Speed Device     ; признак владельца порта:
                                                ; 1 - порт подключен к контроллеру-компаньону
                                                ; (определено опдключение не HS или EHC не сконфигурирован)
        jz      .exit
        or      PARA__CtrlByte, LOW_SPEED       ; Set LS-bit (чтобы использовать преамбулу перед подачей)

.have_connection:
_%
      push    ax
        mov     al,  bPort_N
        dec     al
        LOG.b   "Have connection at Port ", al
      pop     ax
        LOG.w   "Controller Status = ", ax
_HC
%_
        LOG     "Set power to root port"
        or_OHC  ebx, HcRhPortStatusN__PPS       ; Set Port Power (write)
;        or_OHC  ebx, HcRhPortStatusN__ALLSC     ; all status change bits
        LOG     "Enable root port"
        or_OHC  ebx, HcRhPortStatusN__PES       ; Set Port Enable (write)
;        or_OHC  ebx, HcRhPortStatusN__ALLSC    ; all status change bits

        LOG     "Reset Port"                    ; Reset root port
        or_OHC  ebx, HcRhPortStatusN__PRS       ; Set Port Reset (write)
@@:
        test    dHC, HcRhPortStatusN__PRS       ; in dHC (ES:EDI) - current RX = Port Reset Status (read)
        jnz     @B                              ; Wait for cancel Reset
;        or_OHC  ebx, HcRhPortStatusN__ALLSC     ; all status change bits
        LOG     "Suspend all tasks for Control Transfer"
        and_OHC HcControl, not HcControl__PLE
        or_OHC  HcInterruptDisable, HcInterruptDisable__DIS_WDH ; Write back DoneHead
_HC
        clc
.exit:
        ret

.not_connection:                                ; error
        stc
        exit

;[]=====.=======|===============================*==============[]
include 'other\FlatMode.asm'
include 'vars.inc'                              ; all vars
include 'other\MD5.asm'

include.if_DEBUG 'other\vyvod.asm'
include.if_DEBUG 'msg.asm'                      ; all msg-subs (_HC, _TD etc) w/o macroses - all macroses define on top - in "equ.equ"
;[]=====.=======|===============================*==============[]
