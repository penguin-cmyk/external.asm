%define TH32CS_SNAPPROCESS 0x2
%define INVALID_HANDLE_VALUE 0xFFFFFFFFFFFFFFFF
%define PROCESS_ALL_ACCESS 0x1FFFFF

section .data
    RBX_NAME             db "RobloxPlayerBeta.exe", 0

    PID                  dd 0  ; DWORD = 4 bytes
    HANDLE               dq 0  ; HANDLE = 8 bytes (alias for void*)
    BASEADRESS           dq 0  ; uintptr_t = 8 bytes
    BYTES_READ           dq 0  ; 8 bytes (SIZE_T)
    BYTES_WRITTEN        dq 0
    
    STRING_LENGTH        dq 0
    STRING_POINTER       dq 0
    STRING_BUFFER        dq 0

    DM_POINTER           dq 0
    DATAMODEL            dq 0
    NAME_POINTER         dq 0 
    
    FMT_DM               db "DM = 0x%llX", 10, 0
    FMT_STR              db "Read string: %s", 10, 0
    
    
    EMPTY_STRING         db ""

section .text
    global rbx_pid
    global rbx_base
    global open_handle
    global real_dm

    extern CreateToolhelp32Snapshot
    extern OpenProcess
    extern CloseHandle

    extern Process32First
    extern Process32Next
    extern Module32First

    extern WriteProcessMemory
    extern ReadProcessMemory
    extern strcmp
    extern printf
    extern malloc
    extern free

; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

rbx_pid:
    push    rbp
    push    rdi
    push    rsi
    push    rbx

    sub rsp, 0x158

    xor edx, edx                    ; th32ProcessId = 0
    mov ecx, TH32CS_SNAPPROCESS     ; dwFlags = TH32CS_SNAPPROCESS
    call CreateToolhelp32Snapshot

    mov rbx, rax                    ; Save Handle
    cmp rax, INVALID_HANDLE_VALUE
    jz fail_pid

    lea rdi, [rsp + 0x20]           ; pe structure
    mov rcx, rax

    lea rbp, [rsp + 0x20 + 44]      ; pe.szExeFile
    mov dword [rsp + 0x20], 0x130   ; pe.dwSize = 0x130
    mov rdx, rdi                    ; lppe
    call Process32First

    test eax, eax
    jnz loop
    jmp cleanup

    align 0x10

next_proc:
    mov rdx, rdi                    ; lppe
    mov rcx, rbx                    ; hSnapshot
    call Process32Next
    test eax, eax
    jz cleanup

loop:
    mov rdx,  RBX_NAME              ; Str2
    mov rcx,  rbp                   ; Str1
    call strcmp

    test eax, eax
    jnz next_proc

    mov esi, [rsp + 0x20 + 8]       ; th32ProcessId
    mov rcx, rbx
    call CloseHandle

    mov eax, esi
    mov [rel PID], esi

    add rsp, 0x158

    pop rbx
    pop rsi
    pop rdi
    pop rbp

    ret

cleanup:
    mov rcx, rbx
    call CloseHandle

fail_pid:
    xor esi, esi
    mov eax, esi
    add rsp, 0x158

    pop rbx
    pop rsi
    pop rdi
    pop rbp

    ret

; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

open_handle:
    push rbp
    mov rbp, rsp
    sub rsp, 0x20

    mov [rbp + 0x10], ecx            ; rbp + 0x10 = pid
    mov eax, [rbp + 0x10]            ; eax = pid

    mov r8d, eax                     ; dwProcessId
    mov edx, 0                       ; bInheritHandle
    mov ecx, PROCESS_ALL_ACCESS      ; dwDesiredAccess

    call OpenProcess
    mov [rel HANDLE], rax

    add rsp, 0x20
    pop rbp

    ret

; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

rbx_base:
    push rbx
    sub rsp, 0x260

    mov edx, [rel PID]              ; th32ProcessId
    mov ecx, 0x18
    call CreateToolhelp32Snapshot

    mov rbx, rax                    ; Save handle
    cmp rax, INVALID_HANDLE_VALUE
    jz  base_fail

    mov rcx, rax                    ; hSnapshot
    lea rdx, [rsp + 0x20]           ; lpme
    mov dword [rsp + 0x20], 0x238   ; dwSize (sizeof(MODULEENTRY32))
    call Module32First

    mov rcx, rbx
    test eax, eax
    jz base_close

    call CloseHandle

    mov rax, [rsp + 0x20 + 24]      ; modBaseAddr (BYTE*)
    lea rdx, [rel BASEADRESS]
    mov [rdx], rax

    add rsp, 0x260
    pop rbx

    ret

base_fail:
    xor eax, eax
    add rsp, 0x260
    pop rbx
    ret

base_close:
    call CloseHandle

; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

read_memory:
    push rbp
    mov rbp, rsp
    sub rsp, 0x40
    ; rdx = Adress
    ; r8  = OutBuffer
    ; r9  = Size
    lea rcx, [rel BYTES_READ]
    mov [rsp+0x20], rcx                     ; lpNumberOfBytesRead
    mov rcx, [rel HANDLE]                   ; hProcess
    call ReadProcessMemory

    test eax, eax
    jz rpm_fail

    add rsp, 0x40
    pop rbp
    ret

write_memory:
  push rbp 
  mov rbp, rsp
  sub rsp, 0x40

  ; rdx = Address 
  ; r8 =  InBuffer (data)
  ; r9 =  size 
  
  lea rcx, [rel BYTES_WRITTEN]
  mov [rsp + 0x20], rcx                 ; lpNumberOfBytesWritten 
  mov rcx, [rel HANDLE]
  
  call WriteProcessMemory
  
  test eax, eax
  jz wpm_fail 
  
  add rsp, 0x40
  pop rbp
  ret 
  
read_string:
    push rbp
    mov rbp, rsp
    push r14
    push r13
    push r12
    push rdi
    push rsi
    push rbx
    sub rsp, 0x50

    mov rbx, rdx                ; Save original address

    ; Read string length
    add rdx, 0x10               ; Length offset
    lea r8, [rel STRING_LENGTH]
    mov r9, 8
    call read_memory

    test eax, eax
    jz failed_readstring

    mov rdi, [rel STRING_LENGTH]
    test rdi, rdi
    jz failed_readstring

    cmp rdi, 0x1000             ; Max 4KB string
    ja failed_readstring

    cmp rdi, 255                ; Check if fits in buffer
    ja failed_readstring

    cmp rdi, 16              ;
    jbe normal_read_string

    ; read_memory( NamePointer, &STRING_POINTER, 8 )
    mov r9, 8
    lea r8, [rel STRING_POINTER]
    mov rdx, rbx
    call read_memory

    test eax, eax
    jz failed_readstring

    ; read_memory( STRING_POINTER, &STRING_BUFFER, STRING_LENGTH )
    mov r9, [rel STRING_LENGTH]
    lea r8, [rel STRING_BUFFER]
    mov rdx, [rel STRING_POINTER]
    call read_memory

    test eax, eax
    jz failed_readstring

    jmp done_readstring

normal_read_string:
    ; Short string
    mov r9, rdi
    lea r8, [rel STRING_BUFFER]
    mov rdx, rbx
    call read_memory

    test eax, eax
    jz failed_readstring

done_readstring:
    ; Null terminate
    mov rax, [rel STRING_LENGTH]
    lea r13, [rel STRING_BUFFER]
    mov byte [r13 + rax], 0

    mov rax, r13                ; Return buffer address
    jmp read_string_exit

failed_readstring:
    lea rax, [rel EMPTY_STRING]

read_string_exit:
    add rsp, 0x50
    pop rbx
    pop rsi
    pop rdi
    pop r12
    pop r13
    pop r14
    pop rbp
    ret
  
wpm_fail:
  add rsp, 0x40
  pop rbp 
  ret 


rpm_fail:
    add rsp, 0x40
    pop rbp
    ret

; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
dm_name:
    push rbp
    mov rbp, rsp

    sub rsp, 0x38

    mov rdx, [rel NAME_POINTER]
    call read_string

    mov rdx, rax
    mov rcx, FMT_STR
    call printf

    add rsp, 0x38
    pop rbp
    ret

real_dm:
    sub rsp, 0x40

    ; ////////////////////////////////////////////////////////////////

    mov rdx, [rel BASEADRESS]
    add rdx, 0x682B928

    lea r8,  [rel DM_POINTER]
    mov r9,  8               ; uintptr_t

    call read_memory

    mov rdx, [rel DM_POINTER]
    add rdx, 0x1B8
    
    lea r8,  [rel DATAMODEL]
    mov r9, 8
    
    call read_memory

    ; ////////////////////////////////////////////////////////////////
    mov rdx, [rel DATAMODEL]
    add rdx, 0x78
    
    lea r8,  [rel NAME_POINTER]
    mov r9,  8
    
    call read_memory
    call dm_name
    ; ////////////////////////////////////////////////////////////////

    add rsp, 0x40
    ret
    