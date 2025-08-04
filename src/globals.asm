section .data 
    global PROCESS_NAME, STRING_BUFFER, CHILD_TO_FIND, DATAMODEL_POINTER,DATAMODEL, PLAYERS_SERVICE, ModelInstance, LocalPlayer, Players, HumanoidPointer
    global x, y, z

    CHILD_TO_FIND      times 64 db 0

    DATAMODEL_POINTER  dq 0
    DATAMODEL          dq 0 
    STRING_BUFFER      dq 0

    PLAYERS_SERVICE    dq 0
    LocalPlayer        dq 0
    ModelInstance      dq 0
    HumanoidPointer    dq 0 
    
    PROCESS_NAME       db "RobloxPlayerBeta.exe", 0
    Players            db "Players", 0

    x dd 0.0 
    y dd 0.0 
    z dd 0.0 