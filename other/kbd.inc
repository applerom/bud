;[]=====.=======|===============================*==============[]
Old_int9        struc.off_seg                   ; Offset/Segment Old int9-pointer
zb      Flag.Input_Char
zb      Flag                                    ; Flag for different (keys_operations
zb      KBD_Status                              ; KBD Status byte
zb      LED_Status                              ; LED Status byte
zb      ASCII_code                              ; ASCII-code of input symbol
zb      ScanCode                                ; Scan-code of input symbol

Keys_TBL:                                       ; SSC
dw      .Norm                                   ; 000xx
dw      .Caps                                   ; 001xx
dw      .Shift                                  ; 010xx
dw      .Caps_Shift                             ; 011xx
dw      .Shift                                  ; 100xx
dw      .Caps_Shift                             ; 101xx
dw      .Shift                                  ; 110xx
dw      .Caps_Shift                             ; 111xx
.Norm:
  db  0 , 27,'1','2','3','4','5','6','7','8','9','0','-','=', 8 , 9
  db 'q','w','e','r','t','y','u','i','o','p','[',']', 13, 0
  db 'a','s','d','f','g','h','j','k','l',';','"','`', 0 ,'\'
  db 'z','x','c','v','b','n','m',',','.','/', 0 ,'*', 0 ,' '
.Shift:
  db  0 , 27,'!','@','#','$','%','^','&','*','(',')','_','+', 8 , 9
  db 'Q','W','E','R','T','Y','U','I','O','P','{','}', 13, 0
  db 'A','S','D','F','G','H','J','K','L',':','"','~', 0 ,'|'
  db 'Z','X','C','V','B','N','M','<','>','?', 0 ,'*', 0 ,' '
.Caps:
  db  0 , 27,'1','2','3','4','5','6','7','8','9','0','-','=', 8 , 9
  db 'Q','W','E','R','T','Y','U','I','O','P','{','}', 13, 0
  db 'A','S','D','F','G','H','J','K','L',':','"','~', 0 ,'|'
  db 'Z','X','C','V','B','N','M','<','>','?', 0 ,'*', 0 ,' '
.Caps_Shift:
  db  0 , 27,'!','@','#','$','%','^','&','*','(',')','_','+', 8 , 9
  db 'q','w','e','r','t','y','u','i','o','p','[',']', 13, 0
  db 'a','s','d','f','g','h','j','k','l',';','"','`', 0 ,'\'
  db 'z','x','c','v','b','n','m',',','.','/', 0 ,'*', 0 ,' '
