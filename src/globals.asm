%define uintptr_t dq
%define SIZE_T    dq
%define HANDLE_T  dq
%define DWORD     dd
%define str       db

section .data
    global DM_POINTER
    global DATAMODEL
    global NAME_POINTER

    global UINTPTR_T_SIZE

    global FMT_STR
    global FMT_DM
    global RBX_NAME

    global PID
    global HANDLE
    global BASEADRESS
    global BYTES_READ
    global BYTES_WRITTEN

    global EMPTY_STRING

    global STRING_LENGTH
    global STRING_POINTER
    global STRING_BUFFER

    global DBG_STR
    global FMT_UINTPTR

    global CHILDREN_START
    global CHILDREN_END

    global CURRENT_CHILD
    global CHILD
    global CHILDREN_HOLDER
    global CHILDREN_LENGTH
    global CHILDREN_COUNTER
    global CHILD_HANDLER

    global WORKSPACE
    global CHILD_TO_FIND
    global CLASS_POINTER
    global CLASS



    DM_POINTER           uintptr_t 0
    DATAMODEL            uintptr_t 0
    NAME_POINTER         uintptr_t 0
    CLASS_POINTER        uintptr_t 0
    CLASS                uintptr_t 0


    UINTPTR_T_SIZE       uintptr_t 8

    FMT_DM               str "DM = 0x%llX", 10, 0
    FMT_STR              str "Read string: %s", 10, 0
    RBX_NAME             str "RobloxPlayerBeta.exe", 0

    PID                  DWORD 0
    HANDLE               uintptr_t 0    ; void pointer = 8 bytes
    BASEADRESS           uintptr_t 0
    BYTES_READ           SIZE_T 0
    BYTES_WRITTEN        SIZE_T 0

    EMPTY_STRING         str ""

    STRING_LENGTH        uintptr_t 0
    STRING_POINTER       uintptr_t 0
    STRING_BUFFER        uintptr_t 0

    DBG_STR              str "Called", 10, 0
    FMT_UINTPTR          str "Read uintptr_t: %llx", 10, 0

    CHILDREN_START       uintptr_t 0
    CHILDREN_END         uintptr_t 0

    CURRENT_CHILD        uintptr_t 0
    CHILD                uintptr_t 0
    CHILDREN_LENGTH      uintptr_t 0
    CHILD_HANDLER        uintptr_t 0

    global PLAYERS_STR
    global HUMANOID_STR

    PLAYERS_STR          str "Players",  0
    HUMANOID_STR         str "Humanoid", 0
    CHILD_TO_FIND        uintptr_t 0                ; will be the pointer to the string


    global HUMANOID
    global PLAYERS
    global CHARACTER
    global LOCALPLAYER

    HUMANOID             uintptr_t 0
    PLAYERS              uintptr_t 0
    CHARACTER            uintptr_t 0
    LOCALPLAYER          uintptr_t 0
