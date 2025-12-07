# What Is Assembly Language?

Assembly is a **low-level programming language** that sits right above raw machine code (binary). Instead of writing programs in 1s and 0s, you write human-readable instructions that directly correspond to what the CPU does. Eventually C was built on top of Assembly, and so on!

## A Quick Analogy

- **Machine code**: `10110000 01100001` (what the CPU actually executes)
- **Assembly**: `mov w0, #97` (human-readable version of the same thing)
- **Higher-level languages**: `char c = 'a';` (what you write in C, Rust, etc.)

An **assembler** is the tool that converts your assembly code into machine code that the CPU can execute.

---

## Why Learn Assembly?

You might be wondering: "Why would I write assembly when I can use Python/JavaScript/Rust?"

Great question! Here's why:

1. **Understand how computers really work** - See what your high-level code actually becomes
2. **Debug like a pro** - When things break, debuggers show you assembly
3. **Performance optimization** - Sometimes you need that last bit of speed
4. **Reverse engineering & security** - Understand how programs work without source code
5. **Embedded systems & OS development** - Sometimes assembly is the only option
6. **It's genuinely fun!** - There's something satisfying about direct hardware control

---

## Assembly Varies by CPU Architecture

Here's the crucial thing: **assembly is not portable**. Code written for one CPU architecture won't run on another.

### CISC vs RISC

- **x86/x64** (Intel/AMD) - Complex Instruction Set Computing (CISC)
  - Many complex instructions that do a lot in one operation
  - Variable-length instructions
  - Fewer registers

- **ARM** (Apple Silicon, phones, tablets) - Reduced Instruction Set Computing (RISC)
  - Simple, uniform instructions
  - More registers (32 general-purpose registers!)
  - Most instructions execute in a single cycle
  - Load/store architecture (only load/store touch memory)

### Example: Adding two numbers

**x86-64**:
```asm
add rax, rbx    ; Add rbx to rax, store in rax
```

**ARM64**:
```asm
add x0, x1, x2  ; Add x1 and x2, store in x0
```

Similar but different! And these won't run on each other's CPUs.

---

## Operating System Differences Matter Too!

Even on the **same CPU**, different operating systems have different rules:

| Aspect | macOS (this guide) | Linux |
|--------|-------------------|-------|
| **Syscall register** | X16 | X8 |
| **Stack alignment** | 16-byte mandatory | 16-byte mandatory |
| **X18 register** | Reserved (thread pointer) | Available for use |
| **Calling convention** | Apple ARM64 ABI | ARM64 Linux ABI |
| **File format** | Mach-O | ELF |

This means **ARM assembly for Linux won't work on macOS** (and vice versa) without modifications!

### Why This Guide Focuses on ARM64 on macOS

- Apple Silicon (M1/M2/M3/M4) is becoming ubiquitous
- Very few resources exist for macOS-specific ARM assembly
- The tooling (Xcode, lldb) is excellent
- It's what I'm learning and want to share!

---

## ARM64 Architecture Overview

ARM64 (also called AArch64) is a 64-bit RISC architecture. Let's talk about the most important concept: **registers**.

### What Are Registers?

Registers are **tiny, ultra-fast storage locations** built into the CPU. Think of them as variables that live directly on the processor. They're measured in nanoseconds, whereas RAM is measured in microseconds (1000x slower!).

ARM64 has **31 general-purpose registers**, each 64 bits (8 bytes) wide.

### Register Naming

- **X0-X30**: 64-bit registers (full width)
- **W0-W30**: 32-bit registers (lower half of X registers)

When you write to a W register, the upper 32 bits are automatically zeroed:

```asm
mov x0, #0xFFFFFFFFFFFFFFFF   ; x0 = all 1s (64 bits)
mov w0, #42                     ; x0 = 0x000000000000002A (upper half cleared!)
```

---

## ARM64 Register Quick Reference

Here's a visual grouping of what registers do:

```
X0-X7     → Arguments & Returns
X8        → Indirect Result Location (macOS-specific usage)
X9-X15    → Scratch/Temporary (not preserved across calls)
X16-X17   → System/Linker scratch (X16 = syscall number on macOS)
X18       → Reserved by macOS (thread-local storage pointer)
X19-X28   → Preserved across function calls
X29       → Frame Pointer (fp)
X30       → Link Register (lr) - holds return address
SP        → Stack Pointer
XZR/WZR   → Always reads as zero
```

---

## Detailed Register Breakdown

### X0–X7 — Argument + Return Registers
- Used to pass the first 8 arguments to functions
- **X0** = primary return value
- **X1-X7** = additional arguments (or multi-value returns if needed)
- **Not preserved** across function calls (caller must save if needed)

Example:
```asm
mov x0, #1        ; First argument
mov x1, #2        ; Second argument
bl my_function    ; Call function - it can use these
; x0 now contains the return value
```

---

### X8 — Indirect Result Location
- On **macOS**: Used for returning large structs (holds pointer to where result goes)
- On **Linux**: Used as the syscall number (macOS uses X16 instead)

---

### X9–X15 — Scratch (Temporary) Registers
- Use these for temporary calculations
- **Not preserved** across function calls
- You can freely clobber these without saving

---

### X16–X17 — Inter-Procedure Call Scratch
- Used by the linker and PLT (Procedure Linkage Table) stubs
- **X16 is critical on macOS**: holds the **syscall number**
- Don't rely on these being preserved

Example syscall:
```asm
mov x16, #1       ; syscall number (1 = exit on macOS)
mov x0, #0        ; exit code
svc #0            ; make the syscall
```

---

### X18 — Reserved by macOS
- **Linux** allows programs to use X18 freely
- **macOS** reserves X18 as the **thread-local storage (TLS) base pointer**
- **Don't touch this register on macOS!**

---

### X19–X28 — Callee-Saved Registers (Non-Volatile)
- **Preserved across function calls** (callee must save and restore)
- Perfect for:
  - Long-lived local variables
  - Values that must survive function calls
  - Loop counters in complex functions

If a function uses these, it must:
```asm
stp x19, x20, [sp, #-16]!   ; Save x19 and x20
; ... use x19 and x20 ...
ldp x19, x20, [sp], #16     ; Restore before returning
```

---

### X29 — Frame Pointer (fp)
- Points to the current stack frame
- **Critical on macOS** for stack unwinding and debugging
- Even though it's technically optional in the ABI, macOS tools expect it

Typical function prologue:
```asm
stp x29, x30, [sp, #-16]!   ; Save frame pointer and link register
mov x29, sp                  ; Set up new frame pointer
```

---

### X30 — Link Register (lr)
- Automatically set by `bl` (branch with link) instructions
- Contains the **return address** (where to go back to)
- You return by branching to it: `ret` is shorthand for `br x30`

---

### SP — Stack Pointer
- Points to the top of the stack
- **Must stay 16-byte aligned** on macOS (always!)
- Grows downward (toward lower addresses)

---

### XZR/WZR — Zero Register
- Always reads as **zero**
- Writes are discarded (useful for testing without storing)

Example:
```asm
cmp x0, xzr       ; Compare x0 to zero
str wzr, [x1]     ; Store zero to memory address in x1
```

---

### PC — Program Counter
- Holds the address of the current instruction
- Not directly accessible in most instructions (use `adr` to get nearby addresses)

---

## Understanding PSTATE (Condition Flags)

ARM64 has **condition flags** that get set by certain instructions. These are stored in a special register called PSTATE (Process State).

### The Four Main Flags

- **N (Negative)** - Set if the result is negative (bit 31 is 1)
- **Z (Zero)** - Set if the result is zero
- **C (Carry)** - Set if there was an unsigned overflow (carry out)
- **V (Overflow)** - Set if there was a signed overflow

### Example

```asm
subs x0, x1, x2   ; x0 = x1 - x2, and set flags
; If result is zero, Z flag is set
; If result is negative, N flag is set
; If there was a borrow, C flag is cleared
; If signed overflow occurred, V flag is set

beq  is_zero      ; Branch if Z flag is set (result was zero)
blt  is_negative  ; Branch if N != V (signed less than)
```

These flags are used by conditional branch instructions like `beq` (branch if equal), `bne` (branch if not equal), `blt` (branch if less than), etc.

---

## What's Next?

Now that you understand what assembly is, why it matters, and how ARM64 registers work, you're ready to set up your environment and write some code!

Head to **01-setup/** to get your Mac ready for assembly programming.

---

## Quick Tips for Beginners

1. **Don't memorize everything** - You'll learn registers through practice
2. **Use a reference** - Keep this page open while coding
3. **Start simple** - Master one concept before moving to the next
4. **Read compiler output** - See what your C code becomes: `clang -S file.c`
5. **Experiment** - Breaking things is how you learn!

---

**Ready? Let's go! →** [Next: Setup](../01-setup/)
