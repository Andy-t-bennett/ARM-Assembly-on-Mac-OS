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

To start, ARM requires we set a `.global` label for the `_start` (or the entry point of our code). The global keyword allows the linker to see where the code actually starts. Think of global as setting a function to public.

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
- **`.data`** is an assembler directive that tells the operating system we are declaring variables and need to allocate some space in storage. Because we are creating the string with a predefined value, the OS knows exactly how much space is needed.
- **`hello_world:`** is the variable name (typically in snake_case)
- **`.ascii`** is the data type
- **`"Hello, World!\n"`** is the value, `\n` is being added to make it print a little cleaner in the terminal

---

## The Code Section

Now that we've set up our entry point, and created a new variable to print out, we need to tell the OS where our code ACTUALLY starts. We do this with the .text directive, which marks the beginning of the code section.

```asm
.global _start

.data
hello_world: .ascii "Hello, World!\n"

.text
```

What will happen here is the OS will allocate space in memory to hold all the assembly code. We'll touch more on memory in a later chapter so don't think you have to understand this now, just know, these directives serve a purpose for the OS.

---

## Alignment

The last directive before our _start function is:

```asm
.align 2
```

This isn't required but is good practice. `.align 2` means align to 2² = 4 bytes, which matches ARM's instruction size (all ARM instructions are 4 bytes). This keeps everything neatly aligned in memory. Don't think too deeply on this yet, just food for thought.

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

It's good to think about what we are trying to accomplish before we get started. The main goal is to print the value from our variable `hello_world` ("Hello, World!\n"). We know that since we created the variable in the `.data` section, the OS automatically added it into memory for us, so all we need to do is find it! But how do we do that?

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

- In ARM assembly, a **PAGE** is a fixed block of memory. The values can range for how large or small these blocks are, but in macOS, a PAGE is 16KB. **PAGEOFF** is a way to find a specific location of data in a PAGE (or block of memory).
  - Think of it like this: the entirety of memory (RAM) is a book, our `.data` section is a chapter, and `hello_world` is a sentence on a page.
- **`adrp`** gets us to the right "page" (a 16KB block) where `hello_world` lives
- **`add`** adds the offset to get the exact byte within that page, or in a way, the "sentance" on that page.
- Together they pinpoint the exact memory location!

*(If you're curious about the technical details of how this works with PC-relative addressing, we'll dive deeper in the memory chapter!)*

Just planting the seed of this knowledge now, we'll circle back on this.

---

## Making the System Call

Now that we've stored the address of the `hello_world` variable, we can use a **System call** to print it to the terminal! System calls are OS specific, so how we use a system call on macOS could be different to how Linux might handle it, even if both are using ARM. This is because system calls live at the OS level.

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
- This sets the value of "1" in the register `x0`
- Telling the OS we want to perform an stdout, aka print to the terminal

**`mov x2, #14`**
- This sets the value of "14" in register `x2`
- Why 14? Well this register is going to store the amount of bytes we want to print to the terminal
- And we know it's 14 because "Hello, World!\n" breaks out to:
  1.  H
  2.  e
  3.  l
  4.  l
  5.  o
  6.  ,
  7.  (space)
  8.  W
  9.  o
  10. r
  11. l
  12. d
  13. !
  14. \n

**`mov x16, #4`**
- Tells OS we are going to be making a system call for printing to the terminal, so go ahead and check registers `x0`, `x1`, and `x2`
- **macOS specific**: The use of register X16 as the marker for what system call to use is macOS specific, Linux for example uses register X8

**`svc #0x80`**
- **Supervisor call** - tells OS to trigger the system call denoted in register X16
- We use `#0x80` following macOS convention, but the value is ignored - the syscall number actually comes from register X16
- `svc` (the instruction itself) is a standard ARM instruction used by all ARM systems

---

## Exiting the Program

At this point, we've done everything to run our program! But we're not done yet, now we just need to end it properly.

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