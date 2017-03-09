;[]=====.=======|===============================*==============[]
include 'other\USB.inc'
;[]=====.=======|===============================*==============[]
zb      USB_type
zd      USB_Base_Address                        ;DW for UHCI
zw      USB_PCI_Address
zb      Port_N
zb      Host_N
zb      Number_Ports
zb      Logon_Error_Counter
zb      Send_Type

zw      Save_SS
zw      Save_SP

;[]=====.=======|===============================*==============[]
Error           DB      0
Pos             DB      0
Direction       DB      0
;**************************
Addr_QH           DD    ?
Addr_TD_Array     DD    ?
Addr_CommandDescr DD    ?
Addr_DataDescr    DD    ?
;[]=====.=======|===============================*==============[]
zb      VideoMode
zw      DevAddrMap
;[]=====.=======|===============================*==============[]
zd      User_buffer__Size
PARA    struc_PARA
;                        virtual at      bx
;                                vPARA   struc_PARA
;                        end virtual
;[]=====.=======|===============================*==============[]
