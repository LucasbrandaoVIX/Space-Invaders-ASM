# Space Invaders 8086

This project is an implementation of the classic Space Invaders game in x86 Assembly for DOS. The game uses BMP graphics and direct video manipulation, as well as files to save scores and settings.

## Requirements
- DOS emulator (e.g., DOSBox)
- x86 Assembly compiler (e.g., TASM, MASM)
- Compatible operating system (Windows recommended for running via DOSBox)

## How to Run
1. Compile the main file to generate the executable.
2. Run the executable in a DOS environment (DOSBox recommended).
    
    ```bash
    tasm /zi main.asm
    tlink /v main.obj
    main.exe
    ```
