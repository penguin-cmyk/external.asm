section .data 
    global CHILD

    extern DATAMODEL_POINTER
    extern DATAMODEL
    extern BaseAdress

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
    extern read_memory
    extern read_string

    global obj_name
    global obj_class
    global get_datamodel
    global get_children
    global find_first_child
    global copy_string_children

    extern STRING_BUFFER
    extern CHILD_TO_FIND
    extern copy_string

    extern printf
    extern malloc
    extern free 
    extern strcmp 

get_datamodel:
    sub rsp, 0x40

    ; read_memory( BaseAddress + 0x68D7308, &Datamodel_Pointer, sizeof(uintptr_t))
    mov rdx, [rel BaseAdress]
    add rdx, 0x68D7308
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