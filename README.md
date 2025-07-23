# Space Invaders 8086

This project is an implementation of the classic Space Invaders game in x86 Assembly for DOS. The game uses BMP graphics and direct video manipulation, as well as files to save scores and settings.

## Requirements
- DOS emulator (e.g., DOSBox)
- x86 Assembly compiler (e.g., TASM, MASM)
- Compatible operating system (Windows recommended for running via DOSBox)

## How to Run
1. Compile the `.asm` files to generate the `SPACE.EXE` executable.
2. Run `SPACE.EXE` in a DOS environment (DOSBox recommended).
3. Use the arrow keys to navigate the menu and press Enter to start the game.

## File Structure
- `Space.asm`: Main file, initializes the game and calls modules.
- `Game.asm`: Game logic, controls levels, lives, and score.
- `Invader.asm`: Invader control, movement, and shooting.
- `Menus.asm`: Difficulty selection and instructions menus.
- `Print.asm`: Routines for printing BMPs and text on the screen.
- `FileUse.asm`: File handling (open, close, errors).
- `Procs.asm`: Utility procedures (delay, random, clear screen).
- `Macros.asm`: Macros to facilitate loops and other operations.
- `Strings.asm`: Strings used for messages and menus.
- `Assets/`: BMP images and data files used by the game.

## Credits
Developed by Lucas Brandão for the Embedded Systems course - UFES.
