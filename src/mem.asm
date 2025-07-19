%define TH32CS_SNAPPROCESS 0x2
%define INVALID_HANDLE_VALUE 0xFFFFFFFFFFFFFFFF
%define PROCESS_ALL_ACCESS 0x1FFFFF

section .text
    global read_memory
    global rbx_pid
    global rbx_base
    global open_handle
    global read_string

    extern RBX_NAME
    extern PID
    extern BASEADRESS
    extern BYTES_READ
    extern HANDLE
    extern BYTES_WRITTEN

    extern STRING_LENGTH
    extern STRING_POINTER
    extern STRING_BUFFER
    extern EMPTY_STRING

    extern CreateToolhelp32Snapshot
    extern OpenProcess
    extern CloseHandle

    extern Process32First
    extern Process32Next
    extern Module32First

    extern WriteProcessMemory
    extern ReadProcessMemory

    extern strcmp
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

    cmp rdi, 256                ; Check if fits in buffer
    ja failed_readstring

    cmp rdi, 15              ;
    jbe normal_read_string

    ; read_memory( NamePointer, &STRING_POINTER, 8                                                    ; uintptr_t  )
    mov r9, 8                                                    ; uintptr_t
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
