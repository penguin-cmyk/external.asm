; OFFFSETS
%define NAME_OFFSET             0x78
%define DMPOINTER_OFFSET        0x6833728
%define DMPARENT_OFFSET         0x1C0
%define CLASS_DESCRIPTOR_OFFSET 0x18
%define CHILDREN_OFFSSET        0x80
%define CHILDREN_END_OFFSET     0x8

; Not in globals because it's easier to just do it here

section .text
    extern printf
    extern malloc

    extern read_memory
    extern write_memory
    extern read_string

    extern NAME_POINTER
    extern STRING_BUFFER
    extern DBG_STR
    extern FMT_UINTPTR
    extern FMT_STR

    extern CHILDREN_START
    extern CHILDREN_END
    extern CURRENT_CHILD
    extern CHILDREN_LENGTH
    extern CHILD
    extern CHILD_HANDLER

    extern CHILD_TO_FIND
    extern FOUND_CHILD

    extern CLASS_POINTER
    extern CLASS
    extern PLAYERS_STR

    extern strcmp

dbg_call:
    sub rsp, 0x40
    mov rcx, DBG_STR

    call printf
    add rsp, 0x40
    ret


; rdx = child to find
dbg_call2:
    sub rsp, 0x40
    mov rcx, FMT_UINTPTR

    call printf
    add rsp, 0x40
    ret

; rdx = child to find
get_children_init:
    push rbp
    push rsi
    push rbx
    push r8
    push r10
    push r11
    push rcx

    mov rbp, rsp
    sub rsp, 0x100

    add rdx, CHILDREN_OFFSSET
    mov rbx, rdx

    ; read everything to the specific pointers
    ;////////////////////////////
    ; 2306959352536
    mov rdx, rbx
    lea r8, [rel CHILDREN_START]
    mov r9, 8

    call read_memory

    mov rdx, [rel CHILDREN_START]
    call dbg_call2

    ;////////////////////////////
    mov rdx, [rel CHILDREN_START]
    add rdx, CHILDREN_END_OFFSET

    lea r8, [rel CHILDREN_END]
    mov r9, 8                                                    ; uintptr_t

    call read_memory
    mov rdx, [rel CHILDREN_END]

    call dbg_call2
    ;////////////////////////////
    mov rdx, [rel CHILDREN_START]
    lea r8, [rel CURRENT_CHILD]
    mov r9, 8                                                    ; uintptr_t

    call read_memory
    ;////////////////////////////

    cmp qword [rel CHILDREN_END], 0

    jmp get_children_main
    ret

get_children_main:
    mov rdi, [rel CHILDREN_END]
    cmp qword [rel CURRENT_CHILD], rdi

    jge get_children_done

    mov rax, [rel CHILDREN_END]         ; RAX = end
    sub rax, [rel CURRENT_CHILD]        ; RAX = end - current
    xor rdx, rdx
    ; Clears RDX, bc RDX holds the high 64 bits and RAX the low 64 bits of the 128 bit dividend
    ; If RDX isn't zero, the CPU treats the dividend as a 128-bit number, which changes the number and since our number fits in 64 bits
    ; rdx should be zero to make sure the diviend is just the value in rax

    mov rcx, 0x10                       ; Divisor = 0x10
    div rcx                             ; RAX = quotient, RDX = remainder

    mov qword [rel CHILDREN_LENGTH], rax
    mov r11, [rel CHILDREN_LENGTH]

    mov rdx, r11
    call dbg_call2 ; debug length

    mov r12, 0


    jmp get_children_loop

get_children_loop:
   cmp r12, [rel CHILDREN_LENGTH]                ; i < length
   je get_children_done

   mov rdx, [rel CURRENT_CHILD]
   lea r8,  [rel CHILD]
   mov r9, 8

   call read_memory

   mov rdx, [rel CHILD]
   call dbg_call2

   add qword [rel CURRENT_CHILD], 0x10
   inc r12                             ; i++

   jmp get_children_loop

get_children_done:
    add rsp, 0x100

    pop rbp
    pop rsi
    pop rbx
    pop r8
    pop r10
    pop r11
    pop rcx

    ret

obj_name:
    add rdx, NAME_OFFSET

    lea r8, [rel NAME_POINTER]
    mov r9, 8
    call read_memory

    mov rdx, [rel NAME_POINTER]
    call read_string

    ret

obj_class:
    add rdx, CLASS_DESCRIPTOR_OFFSET

    lea r8, [rel CLASS_POINTER]
    mov r9, 8
    call read_memory

    mov rdx, [rel CLASS_POINTER]
    add rdx, 0x8
    lea r8,  [rel CLASS]
    mov r9,  8
    call read_memory

    mov rdx, [rel CLASS]
    call read_string

    ret


