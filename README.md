# Space Invaders 8086

A classic Space Invaders game implementation written in x86 Assembly for DOS systems. This project demonstrates low-level graphics programming, interrupt handling, and game development techniques using 8086 assembly language.

## Features

### Controls
- **Arrow Keys**: Navigate menus and move player ship
- **W**: Shoot projectiles
- **P**: Pause/Resume game
- **Q**: Quit with confirmation dialog
- **ESC**: Exit to main menu
- **Enter**: Select menu options
- **Y/N**: Confirm/Cancel dialogs

### Graphics & Audio
- **VGA Mode 13h** (320x200, 256 colors) for smooth graphics
- **BMP sprite rendering** with transparency support
- **Custom graphics** for player ship, invaders, and UI elements
- **Visual feedback** with blinking effects and color-coded projectiles

### Technical Features
- **Custom keyboard interrupt handler** (INT 9h) for responsive input
- **Real-time game loop** with precise timing control
- **Memory-efficient sprite management** with dynamic loading
- **Modular code architecture** with separate files for different components

## Difficulty Levels

| Difficulty | Enemy Shot Frequency | 
|------------|---------------------|
| **Easy** | Low (1/20 chance) | 
| **Medium** | Moderate (1/10 chance) | 
| **Hard** | High (1/3 chance) | 

## File Structure

```
Space-Invaders-8086/
├── main.asm          # Main program entry point
├── game.asm          # Core game logic and main loop
├── ui.asm            # User interface and menu systems
├── graphics.asm      # BMP loading and rendering functions
├── entities.asm      # Player and enemy entity management
├── keyboard.asm      # Custom keyboard interrupt handler
├── utils.asm         # Utility functions (delay, random, etc.)
├── fileio.asm        # File I/O operations
├── strings.asm       # Game text and messages
└── Assets/           # Game graphics and data files
    ├── Invader.bmp   # Enemy sprite (32x32)
    ├── Shooter.bmp   # Player sprite (16x16)
    ├── Heart.bmp     # Life indicator (16x16)
    └── Random.txt    # Random number data
```

## System Requirements

### Hardware
- **CPU**: 8086/8088 or compatible (286+ recommended)
- **RAM**: 640KB conventional memory
- **Graphics**: VGA-compatible adapter
- **Storage**: ~1MB free disk space

### Software
- **DOS**: MS-DOS 3.0+ or compatible (PC-DOS, FreeDOS)
- **Emulator**: DOSBox 0.74+ (recommended for modern systems)

## Installation & Compilation

### Prerequisites
```bash
# Install TASM (Turbo Assembler)
# Or use MASM (Microsoft Macro Assembler)
```

### Build Instructions
```bash
# Compile the assembly source
tasm /zi main.asm

# Link the object file
tlink /v main.obj

# Run the executable
main.exe
```

### DOSBox Setup (Recommended)
```bash
# Install DOSBox
# Mount the project directory
mount c: c:\path\to\Space-Invaders-8086

# Switch to mounted drive
c:

# Run the game
main.exe
```

## Gameplay Instructions

### Starting the Game
1. Launch the executable to see the main menu
2. Use **Up/Down arrows** to select difficulty
3. Press **Enter** to start the game
4. A 3-second countdown will begin the action

### Playing
- Move your ship with **Left/Right arrows**
- Press **W** to shoot at invaders
- Avoid enemy projectiles (blue)
- Destroy all invaders to win the level
- Don't let invaders reach the bottom!

### Game States
- **Playing**: Normal gameplay with full controls
- **Paused**: Press **P** to pause/resume
- **Exit Confirmation**: Press **Q** then **Y/N** to confirm
- **Game Over**: Choose to restart (**Y**) or exit (**N**)

## Technical Implementation

### Memory Management
- **Segment Architecture**: Uses small memory model (64KB code + 64KB data)
- **Dynamic Loading**: BMP files loaded on-demand to conserve memory
- **Efficient Arrays**: Compact entity status tracking

### Graphics System
- **Direct VRAM Access**: Writing to 0xA000:0000 for maximum performance
- **Sprite Transparency**: Black pixels (color 0) treated as transparent
- **Double Buffering**: Clear-and-redraw strategy for smooth animation

### Input Handling
- **Hardware Interrupts**: Custom INT 9h handler for lag-free input
- **Flag-Based System**: Non-blocking keyboard state checking
- **Simultaneous Keys**: Support for multiple key presses

### Random Number Generation
- **File-Based RNG**: Uses external data file for true randomness
- **Timer Fallback**: System timer as backup random source
- **Seeded Generation**: Time-based seeding for variability

## Contributing

Feel free to fork this project and experiment with:
- Additional enemy types or behaviors
- Sound effects integration
- Enhanced graphics and animations
- Performance optimizations
- Additional game modes
