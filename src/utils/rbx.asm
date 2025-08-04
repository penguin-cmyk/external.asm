section .data 
    global CHILD

    extern DATAMODEL_POINTER, DATAMODEL, BaseAdress, PLAYERS_SERVICE
    extern Players, ModelInstance, LocalPlayer
    
    NAME_POINTER     dq 0
    CLASS_DESCRIPTOR dq 0
    CLASS_POINTER    dq 0

    CHILDREN_START   dq 0
    CHILDREN_END     dq 0
    CURRENT_CHILD    dq 0 
    CHILDREN_BUFFER  dq 0 
    CHILDREN_LENGTH  dq 0
    CHILD            dq 0

    NAME_FUNC        dq 0

    STR_FORMAT      db "%s", 10, 0
    
section .text 
    extern read_memory, read_string

    global obj_name, obj_class, get_datamodel, get_children, find_first_child, copy_string_children, init_rbx
    extern STRING_BUFFER, CHILD_TO_FIND, copy_string
    extern malloc, free, strcmp 

get_datamodel:
    sub rsp, 0x40

    ; read_memory( BaseAddress + 0x6ED6E38, &Datamodel_Pointer, sizeof(uintptr_t))
    mov rdx, [rel BaseAdress]
    add rdx, 0x6ED6E38
    lea r8,  [rel DATAMODEL_POINTER]
    mov r9,  8
    call read_memory

    ; read_memory( DatamodelPointer + 0x1C0, &Datamodel, sizeof(uintptr_t))
    mov rdx, [rel DATAMODEL_POINTER]
    add rdx, 0x1C0
    lea r8,  [rel DATAMODEL]
    mov r9,  8 
    call read_memory  

    add rsp, 0x40
    ret 

obj_name:
    sub rsp, 0x20 
    mov rdx, rcx 
    
    ; read_memory( address + NameOffsets, &NamePointer, sizeof(uintptr_t) )
    add rdx, 0x78 
    lea r8, [rel NAME_POINTER]
    mov r9, 8

    call read_memory

    mov rcx, [rel NAME_POINTER]
    call read_string
    add rsp, 0x20 

    ret 

obj_class:
    sub rsp, 0x20 
    mov rdx, rcx 
    
    ; read_memory( address + ClassOffset, &NamePointer, sizeof(uintptr_t) )
    add rdx, 0x18
    lea r8, [rel CLASS_DESCRIPTOR]
    mov r9, 8

    call read_memory

    ; read_memory(class_descriptor + 0x8, &CLassPointer, sizeof(uintptr_t) )
    mov rdx, [rel CLASS_DESCRIPTOR]
    add rdx, 0x8 
    lea r8,  [rel CLASS_POINTER]
    mov r9,  8 
    call read_memory

    mov rcx, [rel CLASS_POINTER]
    call read_string
    add rsp, 0x20 

    ret 


get_children:
    push rbp 
    push r12
    mov rbp, rsp 

    sub rsp, 0x100

    mov rdx, rcx 
    mov rbx, rcx

    ; read_memory(address + Children, &children_start, sizeof(uintptr_t))
    add rdx, 0x80
    lea r8,  [rel CHILDREN_START]
    mov r9,  8
    call read_memory

    ; read_memory(start + ChildrenEnd, &end, sizeof(uintptr_t))
    mov rdx, [rel CHILDREN_START]
    add rdx, 0x8 
    lea r8,  [rel CHILDREN_END]
    mov r9,  8
    call read_memory

    cmp qword [rel CHILDREN_END], 0
    je .get_children_exit

    ; read_memory(start, &current_child, sizeof(uintptr_t))
    mov rdx, [rel CHILDREN_START]
    lea r8,  [rel CURRENT_CHILD]
    mov r9,  8 
    call read_memory

    ; uintptr_t length = (end - current) / 0x10
    mov rax, [rel CHILDREN_END]
    sub rax, [rel CURRENT_CHILD]
    xor rdx, rdx 

    mov rcx, 0x10               ; Divisor = 0x10
    div rcx                     ; RAX = quotient, RDX = remainder 

    mov qword [rel CHILDREN_LENGTH], rax 

    ; uintptr_t* childrenArray = malloc(length * sizeof(uintptr_t));
    mov rcx, [rel CHILDREN_LENGTH]
    shl rcx, 3                      ; length * 8                             
    call malloc 

    test rax, rax 
    jz .get_children_exit
    
    mov [rel CHILDREN_BUFFER], rax

    mov r12, 0
    jmp .get_children_loop

.get_children_loop:
    cmp r12, [rel CHILDREN_LENGTH]
    jge .get_children_exit

    mov rdx, [rel CURRENT_CHILD]
    lea r8,  [rel CHILD]
    mov r9,  8 
    call read_memory

    ; CHILDREN_BUFFER[ index ] = child  

    mov rax, [rel CHILDREN_BUFFER]
    mov rdi, [rel CHILD]
    mov qword [rax + r12 * 8], rdi
    
    add qword [rel CURRENT_CHILD], 0x10
    inc r12

    jmp .get_children_loop

.get_children_exit:
    add rsp, 0x100
    pop rbp 
    pop r12
    ret 

; find_first_child(address, method, child_name)

find_first_child:
    push rbp 
    push r12 
    mov rbp, rsp 
    sub rsp, 0x40

    mov [rel NAME_FUNC], rdx 
    mov rbx, rcx                ; save original value 
    call get_children           ; we already have our address in rcx

    mov qword [rel CHILD], 0 


    mov rdx, [rel CHILDREN_BUFFER]
    test rdx, rdx
    jz .find_first_child_done

    mov r12, 0
    jmp .find_first_child_loop



.find_first_child_loop:
    cmp r12, [rel CHILDREN_LENGTH]
    jge .child_not_found

    mov rdx, [rel CHILDREN_BUFFER]
    mov rdi, qword [ rdx + r12 * 8 ]
    mov [rel CHILD], rdi

    mov rcx, [rel CHILD] 
    call qword [rel NAME_FUNC]
    
    mov rdx, [rel STRING_BUFFER]
    lea rcx, [rel CHILD_TO_FIND]
    call strcmp 

    cmp rax, 0
    je .find_first_child_done

    inc r12 
    jmp .find_first_child_loop

.child_not_found:
    mov qword [rel CHILD], 0 
    jmp .find_first_child_done

.find_first_child_done:
    mov rcx, [rel CHILDREN_BUFFER]
    call free

    add rsp, 0x40 
    pop rbp     
    pop r12 
    ret 


copy_string_children:
    sub rsp, 0x20
    lea rdi, [rel CHILD_TO_FIND]
    call copy_string
    add rsp, 0x20 
    ret 


init_rbx:
    sub rsp, 0x100
    ; ChildToFind = Players
    lea rsi, [rel Players]
    call copy_string_children

    ; find_first_child( DataModel, Method: obj_class, "Players" )
    mov rcx, [rel DATAMODEL]
    mov rdx, obj_class
    call find_first_child

    cmp qword [rel CHILD], 0
    je done_main

    mov rsi, [rel CHILD]
    mov qword [rel PLAYERS_SERVICE], rsi 

    ; read_memory( rsi + 0x128, &LocalPlayer, sizeof(uintptr_t) )
    mov rdx, rsi 
    add rdx, 0x128
    lea r8,  [rel LocalPlayer]
    mov r9,  8
    call read_memory

    cmp qword [rel LocalPlayer], 0 
    je done_main 

    ; read_memory( LocalPlayer + 0x340, &ModelInstance, sizeof(uintptr_t) )
    mov rdx, [rel LocalPlayer]
    add rdx, 0x328
    lea r8,  [rel ModelInstance]
    mov r9,  8 
    call read_memory

    cmp qword [rel ModelInstance], 0 
    je done_main
    add rsp, 0x100
    ret 

done_main:
    add rsp, 0x100 
    ret    