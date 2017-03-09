;REQ_name       struc_REQ       bmRequestType,bRequest, wValue,  wIndex, wLength
align 16
rxd_Set_Interface  struc_REQ    TO_DEV_STD,    0b0h, 0, 0, 64;1
align 16
rxd_Set_BufSize1   struc_REQ    FROM_DEV_SPEC, 0b0h, 0, 0, 64;1
align 16
rxd_Set_BufSize64  struc_REQ    FROM_DEV_SPEC, 0b1h, 0, 0, 64;1
align 16
rxd_Clear_Buffer   struc_REQ    FROM_DEV_SPEC, 0b2h, 0, 0, 64;1
align 16
rxd_Get_Status_USB struc_REQ    FROM_DEV_SPEC, 0b3h, 0, 0, 64;2
align 16
rxd_Set_BufSize512 struc_REQ    FROM_DEV_SPEC, 0b4h, 0, 0, 64;2

align 16
rxd_Set_Config2    struc_REQ    TO_DEV_STD,   SET_CONFIGURATION, 2, 0, 0

align 16
req_Get_DD         struc_REQ    FROM_DEV_STD, GET_DESCRIPTOR, DEVICE_DESCRIPTOR*100h, 0, 18      ; =12h
align 16
req_Get_CD         struc_REQ    FROM_DEV_STD, GET_DESCRIPTOR, CONFIG_DESCRIPTOR*100h, 0, 9       ; 200h
align 16
req_Set_Config     struc_REQ    TO_DEV_STD,   SET_CONFIGURATION, ?, 0, 0
align 16
req_Set_Address    struc_REQ    TO_DEV_STD,   SET_ADDRESS,       ?, 0, 0
