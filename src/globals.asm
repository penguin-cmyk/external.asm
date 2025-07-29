section .data 
    global PROCESS_NAME
    global STRING_BUFFER

    global CHILD_TO_FIND

    global DATAMODEL_POINTER
    global DATAMODEL 
    global LocalPlayer
    global CHARACTER
    global PLAYERS_SERVICE
    global ModelInstance
    
    DATAMODEL_POINTER  dq 0
    DATAMODEL          dq 0 

    STRING_BUFFER      dq 0
    PROCESS_NAME       db "RobloxPlayerBeta.exe", 0
    CHILD_TO_FIND      times 64 db 0

    PLAYERS_SERVICE    dq 0
    LocalPlayer        dq 0
    ModelInstance      dq 0
    CHARACTER          dq 0