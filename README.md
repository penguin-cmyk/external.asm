# 🛠️ external.asm - A Pure Assembly External (WIP)

Welcome! This is a **work-in-progress external project** written entirely in x86_64 assembly using Intel syntax.

Right now, it features a simple functionality: modifying the walkspeed of a humanoid and changing the position of parts.

The project uses **NASM** as the assembler, and a build script is included under scripts/build.sh for convenience.

---

## 🔧 Requirements

To build this project, you'll need:
  - [MSYS2 MINGW64](https://www.msys2.org/)
  - gcc
  - nasm
---

## 📦 Building the Project

1. Clone the repository:
```bash
git clone https://github.com/penguin-cmyk/external.asm.git
```

2. Navigate into the project directory:
```
cd external.asm
```

3. Navigate into the scripts folder:
```bash
cd scripts
```

4. Run the build script:
```nginx
sh build.sh
```
