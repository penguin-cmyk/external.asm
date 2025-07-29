%define TH32CS_SNAPPROCESS 0x2
%define INVALID_HANDLE_VALUE 0xFFFFFFFFFFFFFFFF
%define PROCESS_ALL_ACCESS 0x1FFFFF

%define PROCESSENTRY32_SIZE 0x130
%define MODULEENTRY32_SIZE  0x238

section .data 
    extern PROCESS_NAME 
    
    global ProccesId
    global BaseAdress
    global Handle 

    BaseAdress      dq 0
    ProccesId       dd 0
    Handle          dq 0

    BYTES_READ      dq 0
    BYTES_WRITTEN   dq 0

section .text 
    ; call get_pid first
    ; then call open_handle 

    global get_pid                                   
    global rebase
    global open_handle                                  
    global get_base_address

    global read_memory
    global write_memory

    extern CreateToolhelp32Snapshot
    extern Process32First
    extern Module32First
    extern Process32Next
    extern CloseHandle
    extern OpenProcess

    extern ReadProcessMemory
    extern WriteProcessMemory

    extern strcmp 

get_pid:
    push rbp 
    push rdi 
    push rsi
    push rbx 
    
    sub rsp, 0x158


    xor edx, edx            
    mov ecx, TH32CS_SNAPPROCESS
    call CreateToolhelp32Snapshot                    ; CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)

    
    mov rbx, rax                                     ; just saving our handle in rbx                     
    cmp rax, INVALID_HANDLE_VALUE
    jz .failed_pid 

    lea rdi, [rsp + 0x20]                            ; Our pe structure (PROCESSENTRY32)
    mov rcx, rax                                     ; rcx now also contains our handle 

                                                       
    lea rbp, [rsp + 0x20 + 44]                       ; pe.szExeFile (rbp will now always be the name of the program since it contains the address not value)  
    
    mov dword [rsp + 0x20], PROCESSENTRY32_SIZE      ; entry.dwSize = sizeof(PROCESSENTRY32)
    mov rdx, rdi
    call Process32First                              ; rcx, rdx 
                                                     ; Process32First( snapshot, &entry )

    test eax, eax 
    jnz .pid_loop                                    
    jmp .pid_cleanup 

.next_process:
    mov rcx, rbx 
    mov rdx, rdi 
    call Process32Next                              ; Process32Next(snapshot, &entry)

    test eax, eax
    jz .pid_cleanup  

.pid_loop:
    mov rcx, rbp                                     ; process name
    mov rdx, PROCESS_NAME                            ; process to find 
    call strcmp                                      ; strcmp( rcx, PROCESS_NAME )

    test eax, eax 
    jnz .next_process

    mov esi, [rsp + 0x20 + 8]                        ; th32processid
    mov rcx, rbx                                     ; Our saved handle
    call CloseHandle

    mov eax, esi 
    mov [rel ProccesId], esi 

    add rsp, 0x158
    
    pop rbx 
    pop rsi 
    pop rdi 
    pop rbp 

    ret 

.pid_cleanup:
    mov rcx, rbx 
    call CloseHandle

.failed_pid:
    xor esi, esi 
    mov eax, esi 
    add rsp, 0x158
    
    pop rbx 
    pop rsi 
    pop rdi 
    pop rbp 

    ret 


open_handle:
    push rbp
    mov rbp, rsp 
    sub rsp, 0x20 

    mov r8d, [rel ProccesId] 
    mov edx, 0 
    mov ecx, PROCESS_ALL_ACCESS

    call OpenProcess     
    mov [rel Handle], rax 

    add rsp, 0x20 
    pop rbp 

    ret 

get_base_address:
    push rbx 
    sub rsp, 0x260

    mov edx, [rel ProccesId]
    mov ecx, 0x18                                      ; TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32
    call CreateToolhelp32Snapshot

    mov rbx, rax 
    cmp rax, INVALID_HANDLE_VALUE
    jz .base_fail 



    ; Module32First(snapshot, &entry)
    mov rcx, rax                                      ; snapshot 
    lea rdx, [rsp + 0x20]                             ; pe structure
    mov dword [rsp + 0x20], MODULEENTRY32_SIZE        ; entry.dwSize = sizeof(MODULEENTRY32)
    call Module32First


    mov rcx, rbx 
    test eax, eax 
    jz .base_close 

    call CloseHandle

    mov rax, [rsp + 0x20 + 24]                         ; modBaseAddr
    mov [rel BaseAdress], rax 

    add rsp, 0x260
    pop rbx 

    ret 

.base_close:
    call CloseHandle   

.base_fail:
    xor eax, eax 
    add rsp, 0x260
    pop rbx 
    ret 


read_memory:
    push rbp 
    mov rbp, rsp 
    sub rsp, 0x40 

    ; rdx = address
    ; r8  = outbuffer
    ; r9  = size 

    ; ReadProcessMemory( handle, address, outbuffer, size, bytes_read )

    lea rcx, [rel BYTES_READ]
    mov [rsp + 0x20], rcx

    mov rcx, [rel Handle]               
    call ReadProcessMemory

    add rsp, 0x40 
    pop rbp 
    ret  


write_memory:
    push rbp 
    mov rbp, rsp 
    sub rsp, 0x40 

    ; rdx = address
    ; r8  = in buffer
    ; r9  = size 

    ; WriteProcessMemory( handle, address, outbuffer, size, bytes_written )
    lea rcx, [rel BYTES_WRITTEN]
    mov [rsp + 0x20], rcx

    mov rcx, [rel Handle]               
    call WriteProcessMemory

    add rsp, 0x40 
    pop rbp 
    ret

    