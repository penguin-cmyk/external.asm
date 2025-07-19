
A work in progress roblox external purely written in assembly using the nasm compiler and x86_64 architecture. 

To run it you will need to include all of these flags in cmake
```
enable_language(ASM_NASM)
set(NASM_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/src")  
set(NASM_INCLUDE_FLAGS "-I${NASM_INCLUDE_DIR}")

set_source_files_properties(  
        src/external.asm  
        src/mem.asm  
        src/utils.asm  
        src/globals.asm  
        PROPERTIES  
        COMPILE_FLAGS "${NASM_INCLUDE_FLAGS}"  
)

add_executable(
	src/external.asm  
	src/utils.asm  
	src/globals.asm  
	src/mem.asm
)
```

Next you'll need to include these functions in your c project

```c
extern DWORD rbx_pid(void);  
extern HANDLE open_handle(DWORD pid);  
extern uintptr_t rbx_base(void);  
extern void dm(void);
```

And call them in this order to initialize the execution

```c
int main(void) {  
    DWORD rbx = rbx_pid();  
    HANDLE rbxHandle = open_handle(rbx);  
  
    uintptr_t baseAddr = rbx_base();  
  
    dm();  
  
    return 0;  
}
```

---

Note that this is not a project meant to really be used that's why there is no real build or cmake file out there.
