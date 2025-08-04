section .data 
    extern STRING_BUFFER

    STRING_LENGTH  dq 0 
    STRING_POINTER dq 0 

    EMPTY_STRING   db "", 0

section .text 
    extern read_memory, write_memory
    extern malloc, free, prinf 
    global copy_string, read_string

; read / write memory 
; rdx = address
; r8  = in buffer
; r9  = size 

read_string:
    push rbp 
    push rbx 
    
    mov rbp, rsp 
    sub rsp, 0x100

    mov rbx, rcx                            ; save original address 

    mov rdx, rcx 
    add rdx, 0x10
    lea r8, [rel STRING_LENGTH]
    mov r9, 8
    call read_memory

    test eax, eax     
    jz .failed_read_string                ; see if the general reading failed 

    cmp qword [rel STRING_LENGTH], 0
    je .failed_read_string               ; look if the string length is equal to 0 

    mov rcx, [rel STRING_LENGTH]
    add rcx, 1                           ; null terminator 
    call malloc 

    test rax, rax 
    jz .failed_read_string
    
    mov [rel STRING_BUFFER], rax 

    cmp qword [rel STRING_LENGTH], 15
    jge .std_string_read
    
    jmp .normal_read_string

.normal_read_string:
    ; read_memory(address, buffer, length)
    mov rdx, rbx                       ; our saved address
    mov r8, [rel STRING_BUFFER]        ; STRING_BUFFER is already a pointer since we allocated it 
    mov r9, [rel STRING_LENGTH]
    call read_memory

    test eax, eax 
    jz .failed_read_string

    jmp .read_string_exit


.std_string_read:
    ; this is where the string contains the pointer to the string not the actual string 

    ; read_memory(address, &string_ptr, sizeof(uintptr_t))
    mov rdx, rbx                   ; our original address 
    lea r8, [rel STRING_POINTER]
    mov r9, 8 
    call read_memory

    test eax, eax 
    jz .failed_read_string

    ; read_memory(string_ptr, buffer, string_length)
    mov rdx, [rel STRING_POINTER]
    mov r8,  [rel STRING_BUFFER]
    mov r9,  [rel STRING_LENGTH]
    call read_memory

    test eax, eax 
    jz .failed_read_string

    jmp .read_string_exit

.failed_read_string:
    lea rax, [rel EMPTY_STRING]
    mov rcx, [rel STRING_BUFFER]
    call free
    
    add rsp, 0x100
    pop rbp 
    pop rbx 
    ret     


.read_string_exit:
    mov rax, [rel STRING_BUFFER]
    mov rcx, [rel STRING_LENGTH]

    mov byte [rax + rcx], 0     ; buffer[length] = '\0'

    add rsp, 0x100
    pop rbp 
    pop rbx 
    ret     


copy_string:
    lodsb                             ; AL = byte at [RSI], RSI++
    stosb                             ; [RDI] = AL, RDI++
    test al, al                       ; Null terminator?
    jnz copy_string
    ret