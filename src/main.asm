; For people that don't know the x86_64 calling convention on windows:
; rcx | ecx     = 1st arg
; rdx | rdx     = 2nd arg
; r8  | r8d     = 3rd arg
; r9  | r9d     = 4th arg
; other args are on the stack ([rsp + ...])


section .data 
    extern ProccesId
    extern BaseAdress
    extern Handle

    extern DATAMODEL
    extern NAME_FUNC
    extern ModelInstance

    extern CHILD_TO_FIND
    extern CHILD
    extern LocalPlayer
    extern PLAYERS_SERVICE

    HumanoidPtr        dq 0
    NewWalkSpeed       dd 200.0

    uintptr_t_fmt      db "%llx", 10, 0
    Players            db "Players", 0
    Humanoid           db "Humanoid", 0
    Found              db "Players found", 10, 0

section .text 
    global main 

    extern get_pid
    extern get_base_address
    extern open_handle

    extern get_datamodel
    extern obj_name
    extern obj_class

    extern printf
    extern read_memory
    extern find_first_child

    extern write_memory

    extern copy_string_children
    
main:
    push rbp 
    mov rbp, rsp 
    sub rsp, 0x100

    call get_pid
    call get_base_address
    call open_handle
    call get_datamodel

.init_everything:
    ; ChildToFind = Players
    lea rsi, [rel Players]
    call copy_string_children

    ; find_first_child( DataModel, Method: obj_class, Child_to_find )
    mov rcx, [rel DATAMODEL]
    mov rdx, obj_class
    call find_first_child

    cmp qword [rel CHILD], 0
    je .done

    mov rsi, [rel CHILD]
    mov qword [rel PLAYERS_SERVICE], rsi 

    ; read_memory( rsi + 0x128, &LocalPlayer, sizeof(uintptr_t) )
    mov rdx, rsi 
    add rdx, 0x128
    lea r8,  [rel LocalPlayer]
    mov r9,  8
    call read_memory

    cmp qword [rel LocalPlayer], 0 
    je .done 

    ; read_memory( LocalPlayer + 0x340, &ModelInstance, sizeof(uintptr_t) )
    mov rdx, [rel LocalPlayer]
    add rdx, 0x340
    lea r8,  [rel ModelInstance]
    mov r9,  8 
    call read_memory

    cmp qword [rel ModelInstance], 0 
    je .done 

    lea rsi, [rel Humanoid]
    call copy_string_children

    mov rcx, [rel ModelInstance]
    mov rdx, obj_class
    call find_first_child

    cmp qword [rel CHILD], 0
    je .done

    mov rsi, [rel CHILD]
    mov qword [rel HumanoidPtr], rsi 


.walkspeed_modifier:
    ; write_memory( Humanoid + WalkSpeed, &WalkSpeed, 200.0 )
    mov rdx, rsi  
    add rdx, 0x1DC
    lea r8,  [rel NewWalkSpeed]
    mov r9,  4
    call write_memory

    ; write_memory( Humanoid + WalkSpeedCheck, &WalkSpeed, 200.0 )
    mov rdx, rsi
    add rdx, 0x3B8
    lea r8,  [rel NewWalkSpeed]
    mov r9,  4
    call write_memory    


.done:
    add rsp, 0x100 
    pop rbp
    ret   
