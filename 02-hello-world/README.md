# Hello, World!

## What You'll Learn

- How to structure an ARM assembly program
- Making your first syscall (printing to terminal)
- How to properly exit a program

---

It's only tradition that the first program we write is "Hello, World!". You're not meant to understand everything happening here, I'm still learning too! But it's supposed to be a way to get your hands dirty, write something, and get that little dopamine bump of seeing some code run.

So let's dive into this step by step. Some of these instructions and conventions are universal across ARM assembly, while some are specific to macOS. I will do my best to differentiate this and let you know when things are specific to macOS.

---

## Setting Up the Entry Point

To start, we need to set a `.global` directive so the linker can see where our code starts. The global keyword makes `_start` visible to the linker - think of it like setting a function to public.

```asm
.global _start
```

**Why "_" before the start?** It's not a requirement but it is a convention used by macOS, that makes Assembly more compatible with higher languages like C and their compilers. It's a good habit to use "_start", and it'll make your life a little easier later.

---

## Declaring Data

Now if you're familiar with another programming language already you might have seen something like:

```javascript
let helloWorld = "Hello, World!"
```

In assembly we can declare variables as well, in a different way:

```asm
.global _start

.data
hello_world: .ascii "Hello, World!\n"
```

Let's break this down:
- **`.data`** is an assembler directive that tells the assembler to place the following data in the data section of the program. Because we are creating the string with a predefined value, the assembler knows exactly how much space is needed.
- **`hello_world:`** is the variable name (typically in snake_case)
- **`.ascii`** is the data type
- **`"Hello, World!\n"`** is the value, `\n` is being added to make it print a little cleaner in the terminal

---

## The Code Section

Now that we've set up our entry point, and created a new variable to print out, we need to tell the assembler where our code ACTUALLY starts. We do this with the `.text` directive, which marks the beginning of the code section.

```asm
.global _start

.data
hello_world: .ascii "Hello, World!\n"

.text
```

What will happen here is the assembler will place all the assembly instructions in the text section. When the program runs, the OS will load this section into memory as executable code. We'll touch more on memory in a later chapter so don't think you have to understand this now, just know, these directives tell the assembler how to organize your program.

---

## Alignment

The last directive helps with performance and compatibility:

```asm
.align 2
```

This isn't required but is good practice. `.align 2` means align to 2² = 4 bytes, which matches ARM's instruction size (all ARM instructions are 4 bytes). This keeps everything neatly aligned in memory for optimal performance. We'll dive deeper into alignment in the memory chapter.

---

## Writing the Code

Now we finally get to our code!

```asm
.global _start

.data
hello_world: .ascii "Hello, World!\n"

.text
.align 2

_start:
```

It's good to think about what we are trying to accomplish before we get started. The main goal is to print the value from our variable `hello_world` ("Hello, World!\n"). We know that since we created the variable in the `.data` section, the linker placed it in memory and the OS loads it when the program runs, so all we need to do is find its address! But how do we do that?

---

## Loading the Address

```asm
.global _start

.data
hello_world: .ascii "Hello, World!\n"

.text
.align 2

_start:
    adrp x1, hello_world@PAGE
    add x1, x1, hello_world@PAGEOFF
```

You'll probably have a few questions here, and it might already look a little intimidating, but stick with me! My goal is to try not to overload you too fast, but I do want to explain some of these concepts.

### To break this down:

- In ARM assembly, the `adrp` instruction works with 4KB-aligned addresses (even though macOS uses 16KB memory pages under the hood). **PAGEOFF** is the offset within that 4KB block.
  - Think of it like this: the entirety of memory (RAM) is a book, our `.data` section is a chapter, and `hello_world` is a sentence on a page.
- **`adrp`** gets us to the right "neighborhood" (a 4KB-aligned block) where `hello_world` lives
- **`add`** adds the offset to get the exact byte within that block, or in a way, the exact "sentence" on that page.
- Together they pinpoint the exact memory location!

Just planting the seed of this knowledge now, we'll circle back on this in the memory chapter!

---

## Making the System Call

Now that we've stored the address of the `hello_world` variable, we can use a **System call** to print it to the terminal! System calls are OS specific, so how we use a system call on macOS could be different to how Linux might handle it, even if both are using ARM.

```asm
.global _start

.data
hello_world: .ascii "Hello, World!\n"

.text
.align 2

_start:
    adrp x1, hello_world@PAGE
    add x1, x1, hello_world@PAGEOFF

    mov x0, #1
    mov x2, #14
    mov x16, #4
    svc #0x80
```

### Let's go line by line:

**`mov x0, #1`**
- This sets register `x0` to 1, which is the **file descriptor** for stdout (the terminal)
- Other file descriptors: 0=stdin (keyboard input), 2=stderr (error output), 3+=files

**`mov x2, #14`**
- This sets the value of "14" in register `x2`
- Why 14? Well this register is going to store the amount of bytes we want to print to the terminal
- And we know it's 14 because "Hello, World!\n" breaks out to:

```
 1. H
 2. e
 3. l
 4. l
 5. o
 6. ,
 7. (space)
 8. W
 9. o
10. r
11. l
12. d
13. !
14. \n
```

**`mov x16, #4`**
- Tells OS we are going to be making a system call for writing/printing (syscall #4)
- **macOS specific**: The use of register X16 as the syscall number is macOS specific, Linux uses register X8
- Think of X16 as saying "which function to call" (write, read, exit, etc.) and the other registers (x0, x1, x2) as the arguments to that function

**`svc #0x80`**
- **Supervisor call** - tells OS to trigger the system call denoted in register X16
- We use `#0x80` following macOS convention, but the value is ignored - the syscall number actually comes from register X16
- `svc` (the instruction itself) is a standard ARM instruction used by all ARM systems

---

## Exiting the Program

At this point, we've done everything to run our program! Congrats! But we're not done yet, now we just need to end it properly.

```asm
.global _start

.data
hello_world: .ascii "Hello, World!\n"

.text
.align 2

_start:
    adrp x1, hello_world@PAGE
    add x1, x1, hello_world@PAGEOFF

    mov x0, #1
    mov x2, #14
    mov x16, #4
    svc #0x80

    mov x0, #0
    mov x16, #1
    svc #0x80
```

This last chunk probably looks a little similar to what we did to print to the terminal. A quick breakdown:

**`mov x0, #0`**
- Now we're setting register `x0` with the value of "0"
- This tells the OS we're going to exit the program with exit code 0 (success)

**`mov x16, #1`**
- Set register `x16` with value of "1"
- Telling OS we want to run the syscall for exiting a program (we don't need to set any other registers for this)

**`svc #0x80`**
- Just like what we did for printing to the terminal, initiate the syscall

If you've ever done a check in a different programming language for exit code = 0, this is what's happening!

---

## Building and Running

Finally, we're ready to run this! In your terminal run these commands, and see your message come to life:

```bash
as -o hello_world.o hello_world.s
ld -o hello_world hello_world.o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -e _start -arch arm64
./hello_world
```

You should see:
```
Hello, World!
```

You did it! It might feel like this is all gibberish and doesn't make sense, but it doesn't have to yet. You wrote a program in assembly, and that's an achievement! Hopefully this got you interested and hungry to learn more!

---

## What Just Happened?

When you ran those commands:

1. **`as`** - The **assembler** converted your `.s` file into machine code (`.o` object file)
2. **`ld`** - The **linker** created an executable, linking in macOS system libraries
   - `-lSystem` = link with macOS system library (provides syscall interface)
   - `-syslibroot` = tells linker where to find macOS SDK
   - `-e _start` = sets entry point to `_start`
   - `-arch arm64` = specifies ARM64 architecture
3. **`./hello_world`** - Ran your program!

---

## Experiments to Try

Want to understand it better? Try these:

- Change "Hello, World!" to your name - remember to update `x2` with the new byte count!
- Remove the `\n` - what happens?
- Change `mov x0, #0` to `mov x0, #1` in the exit code - check the exit status with `echo $?` after running
- Try changing `x0` from `#1` to `#2` in the write syscall - this writes to stderr instead of stdout!

---

## Common Errors

- **"Bad CPU type"**: You're probably on an Intel Mac - this only works on Apple Silicon
- **Segmentation fault**: Check your byte count in `x2` - it should match your string length exactly
- **Nothing prints**: Did you forget the write syscall? Check that `x0=#1`, `x16=#4`
- **"Undefined symbols"**: Make sure you have `.global _start` and the linker flag `-e _start`

---

## Next Steps

Feeling confident? Head to [**03-registers/**](../03-registers/) to learn what all those `x0`, `x1`, `x16` registers really mean and how to use them effectively!