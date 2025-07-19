
**A work-in-progress external for Roblox written entirely in x86_64 assembly using the NASM compiler.**  
This project is purely experimental and is not intended for practical use.

---

## 🛠 Requirements

To build the project, you'll need to configure CMake with NASM support and provide the necessary flags.

### CMake Setup

Make sure to include the following in your `CMakeLists.txt`:

```cmake
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
    external
    src/external.asm
    src/utils.asm
    src/globals.asm
    src/mem.asm
)
```

---
## 🔗 Integration with C

To use this project in a C application, import the following external assembly functions:

```c
extern DWORD rbx_pid(void);
extern HANDLE open_handle(DWORD pid);
extern uintptr_t rbx_base(void);
extern void dm(void);
```

## Example usage

Call them in the following order to initialize and execute:

```c
int main(void) {
	// variables were only there for debugging!
    DWORD rbx = rbx_pid();
    HANDLE rbxHandle = open_handle(rbx);

    uintptr_t baseAddr = rbx_base();

    dm();

    return 0;
}
```

---

## ⚠️ Disclaimer

This is not a finished or production-ready project.  
There is no proper build system or full CMake configuration beyond the basic integration example above. It is meant purely for experimentation and low-level learning.
