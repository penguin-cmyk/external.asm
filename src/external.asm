%include "utils.asm"

section .text align=16
    global dm

    extern RBX_NAME
    extern read_memory
    extern write_memory

    extern NAME_POINTER
    extern FMT_STR
    extern DM_POINTER
    extern DATAMODEL
    extern BASEADRESS

; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


dm_init:
    mov rdx, [rel BASEADRESS]
    add rdx, DMPOINTER_OFFSET

    lea r8,  [rel DM_POINTER]
    mov r9,  8                                                    ; uintptr_t

    call read_memory

    mov rdx, [rel DM_POINTER]
    add rdx, DMPARENT_OFFSET

    lea r8,  [rel DATAMODEL]
    mov r9, 8                                                    ; uintptr_t

    call read_memory
    ret

dm:
    push rbp
    mov rbp, rsp
    sub rsp, 0x40

    ; ////////////////////////////////////////////////////////////////
    ; Init datamodel
    call dm_init
    ; ////////////////////////////////////////////////////////////////
    mov rdx, [rel DATAMODEL]
    call get_children_init      ; currently only prints

    ; ////////////////////////////////////////////////////////////////
    ; Get datamodel name
    mov rdx, [rel DATAMODEL]
    call obj_name

    mov rdx, rax
    mov rcx, FMT_STR
    call printf
    ; ////////////////////////////////////////////////////////////////

    add rsp, 0x40
    pop rbp
    ret
    
