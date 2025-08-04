; For people that don't know the x86_64 calling convention on windows:
; rcx | ecx     = 1st arg
; rdx | rdx     = 2nd arg
; r8  | r8d     = 3rd arg
; r9  | r9d     = 4th arg
; other args are on the stack ([rsp + ...])

section .data 
    extern CHILD, ModelInstance
    extern y 
    Hrp                db "HumanoidRootPart",0 

    NewWalkSpeed       dd 200.0

section .text 
    global main

    extern get_pid, get_base_address, open_handle
    extern get_datamodel, obj_name, find_first_child
    extern change_pos, copy_string_children
    extern init_rbx, get_humanoid, change_walkspeed

;////////////////////////////////////////////////////////////////////////////////////////

main:
    push rbp 
    mov rbp, rsp 
    sub rsp, 0x20

    call get_pid
    call get_base_address
    call open_handle
    call get_datamodel
    call init_rbx

    call get_humanoid
    
    lea r8, [rel NewWalkSpeed]
    call change_walkspeed

    add rsp, 0x20 
    pop rbp

;////////////////////////////////////////////////////////////////////////////////////////

position_change: 
    sub rsp, 0x40

    lea rsi, [rel Hrp]
    call copy_string_children

    ; find_first_child( ModelInstance, Method: obj_name, "HumanoidRootPart" )
    mov rcx, [rel ModelInstance]
    mov rdx, obj_name
    call find_first_child

    cmp qword [rel CHILD], 0
    je done_position

    mov eax, 200
    cvtsi2ss xmm0, eax          ; convert single integer into single precision float 
    movss [rel y], xmm0
    
    ;/////////////////////
    mov r12, 0 

.position_loop:
    cmp r12, 500
    je done_position
     
    ; x, y, z
    ; CHILD = Part
    call change_pos 
    inc r12 
    jmp .position_loop
;////////////////////////////////////////////////////////////////////////////////////////   

done_position:
    add rsp, 0x40 
    ret 