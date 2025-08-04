section .data 
    extern CHILD
    extern x, y, z 

    PRIMITIVE      dq 0
    Humanoid       db "Humanoid",0 
section .text 
    global change_pos, primitive, change_walkspeed, get_humanoid

    extern read_memory, write_memory, copy_string_children, obj_class, find_first_child
    extern ModelInstance, HumanoidPointer


get_humanoid:
    sub rsp, 0x32
    lea rsi, [rel Humanoid]
    call copy_string_children

    mov rcx, [rel ModelInstance]
    mov rdx, obj_class
    call find_first_child

    cmp qword [rel CHILD], 0 
    je .get_humanoid_done

    mov rsi, [rel CHILD]
    mov qword [rel HumanoidPointer], rsi 
    
.get_humanoid_done:
    add rsp, 0x32 
    ret 

; we'll only need to load our new walkspeed into r8 once
change_walkspeed:
    sub rsp, 0x20

    ; Walkspeed
    mov rdx, [rel Humanoid]
    add rdx, 0x1DC
    mov r9,  8 
    call write_memory

    ; Walkspeed Check
    mov rdx, [rel Humanoid]
    add rdx, 0x3B8
    mov r9,  8 
    call write_memory

    add rsp, 0x20 
    ret 


primitive: 
    sub rsp, 0x20 
    ; read_memory( Child + Primitive, &Child, sizeof(uintptr_t)  )
    mov rdx, [rel CHILD]
    add rdx, 0x178
    lea r8,  [rel PRIMITIVE]
    mov r9,  8 
    call read_memory

    add rsp, 0x20 
    ret 

change_pos:   
    sub rsp, 0x100 

    call primitive

    ; 0x14C = Position
    ; write_memory( PRIMITIVE + Position, &x, sizeof(float) )
    ; write_memory( PRIMITIVE + Position + 4, &y, sizeof(float) )
    ; write_memory( PRIMITIVE + Position + 8, &z, sizeof(float) )
    mov rdx, [rel PRIMITIVE]
    add rdx, 0x14C
    lea r8,  [rel x]
    mov r9,  4
    call write_memory

    mov rdx, [rel PRIMITIVE]
    add rdx, 0x14C + 0x4
    lea r8,  [rel y]
    mov r9,  4
    call write_memory

    mov rdx, [rel PRIMITIVE]
    add rdx, 0x14C + 0x8
    lea r8,  [rel z]
    mov r9,  4
    call write_memory

    add rsp, 0x100 
    ret 


change_velocity:   
    sub rsp, 0x100 

    call primitive

    ; 0x158 = Position
    ; write_memory( PRIMITIVE + Velocity, &x, sizeof(float) )
    ; write_memory( PRIMITIVE + Velocity + 4, &y, sizeof(float) )
    ; write_memory( PRIMITIVE + Velocity + 8, &z, sizeof(float) )
    mov rdx, [rel PRIMITIVE]
    add rdx, 0x158
    lea r8,  [rel x]
    mov r9,  4
    call write_memory

    mov rdx, [rel PRIMITIVE]
    add rdx, 0x158 + 0x4
    lea r8,  [rel y]
    mov r9,  4
    call write_memory

    mov rdx, [rel PRIMITIVE]
    add rdx, 0x158 + 0x8
    lea r8,  [rel z]
    mov r9,  4
    call write_memory

    add rsp, 0x100 
    ret    