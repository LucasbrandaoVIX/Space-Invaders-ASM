DATASEG
include "strings.asm"

	DebugBool						db	0

	; Game state
	GamePausedBool					db	0		; 0=Game running, 1=Game paused
	ExitConfirmBool					db	0		; 0=Normal play, 1=Showing exit confirmation

	; Difficulty settings
	DifficultyLevel					db	1		; 0=Easy, 1=Medium, 2=Hard
	SelectedMenuItem				db	1		; Current menu selection (0-2)
	InvaderShotChance				db	10		; Chance of invaders shooting (lower = more frequent)

	;Files:

	RandomFileName					db	'Assets/Random.txt', 0
	RandomFileHandle				dw	?

	MainMenuFileName				db	'Assets/MainMenu.bmp',0
	MainMenuFileHandle				dw	?

	InvaderFileName					db	'Assets/Invader.bmp',0
	InvaderFileHandle				dw	?
	InvaderLength					equ	32
	InvaderHeight					equ	32


	ShooterFileName					db	'Assets/Shooter.bmp', 0
	ShooterFileHandle				dw	?
	ShooterLength					equ	16
	ShooterHeight					equ	16


	HeartFileName					db	'Assets/Heart.bmp', 0
	HeartFileHandle					dw	?
	HeartLength						equ	16
	HeartHeight						equ	16

;Enemies move & status info:
	InvadersMoveRightBool			db	?
	InvadersMovesToSideDone			db	?
	InvadersPrintStartLine			dw	?
	InvadersPrintStartRow			dw	?
	InvadersLeftAmount				db	?
	InvadersStatusArray				db	24 dup (?)

	InvadersLoopMoveCounter			db	? ;Invaders move every 4 repeats of the game loop

	
	ShooterLineLocation				equ 149
	ShooterRowLocation				dw	?

	ShootingLength					equ	2
	ShootingHeight					equ	4

	PlayerShootingExists			db	?
	PlayerShootingLineLocation		dw	?
	PlayerShootingRowLocation		dw	?

	InvadersShootingMaxAmount		db	?
	InvadersShootingCurrentAmount	db	?
	InvadersShootingLineLocations	dw	10 dup (?)
	InvadersShootingRowLocations	dw	10 dup (?)

	LivesRemaining					db	?


	HeartsPrintStartLine			equ	182
	HeartsPrintStartRow				equ	125

	StatsAreaBorderLine				equ	175

	FileReadBuffer					db	320 dup (?)

	;Colors:
	BlackColor						equ	0
	GreenColor						equ	30h
	RedColor						equ	40
	BlueColor						equ	54
	WhiteColor						equ	255

CODESEG
include "entities.asm"
include "utils.asm"

; -----------------------------------------------------------
; Prints the lower game area with lives
; -----------------------------------------------------------
proc PrintStatsArea
	; Print border:
	push 320
	push 2
	push StatsAreaBorderLine
	push 0
	push 100
	call PrintColor

	ret
endp PrintStatsArea


;----------------------------------
; Updates the lives shown on screen
;----------------------------------
proc UpdateLives
	;Clear previous hearts:
	push 64
	push 14
	push HeartsPrintStartLine
	push HeartsPrintStartRow
	push BlackColor
	call PrintColor

	push offset HeartFileName
	push offset HeartFileHandle
	call OpenFile

	;Print amount of lifes remaining:
	xor ch, ch
	mov cl, [LivesRemaining]

	mov bx, HeartsPrintStartRow

@@printHeart:
	push bx
	push cx

	push [HeartFileHandle]
	push HeartLength
	push HeartHeight
	push HeartsPrintStartLine
	push bx
	push offset FileReadBuffer
	call PrintBMP

	pop cx
	pop bx
	add bx, 20
	loop @@printHeart

	push [HeartFileHandle]
	call CloseFile

	ret
endp UpdateLives


; --------------------------------------
; Shows the pause menu overlay
; --------------------------------------
proc ShowPauseMenu
	; Print semi-transparent overlay
	push 180
	push 60
	push 50
	push 70
	push 8  ; Dark gray color
	call PrintColor

	; Print "PAUSED" text
	mov ah, 2
	xor bh, bh
	mov dh, 8
	mov dl, 17
	int 10h

	mov ah, 9
	mov dx, offset PausedString
	int 21h

	; Print "Press P to resume" text
	mov ah, 2
	xor bh, bh
	mov dh, 10
	mov dl, 12
	int 10h

	mov ah, 9
	mov dx, offset PressPhideString
	int 21h

	ret
endp ShowPauseMenu


; --------------------------------------
; Hides the pause menu and redraws game
; --------------------------------------
proc HidePauseMenu
	; Clear the pause menu area
	push 180
	push 60
	push 50
	push 70
	push BlackColor
	call PrintColor

	; Clear the entire game area to remove any projectile "ghosts"
	push 320
	push 165  ; From top to stats area
	push 0    ; Start line
	push 0    ; Start row
	push BlackColor
	call PrintColor

	; Redraw invaders
	call PrintInvaders

	; Redraw shooter
	push [ShooterFileHandle]
	push ShooterLength
	push ShooterHeight
	push ShooterLineLocation
	push [word ptr ShooterRowLocation]
	push offset FileReadBuffer
	call PrintBMP

	; Do NOT redraw player shot here - let the main game loop handle it
	; This prevents "ghost" projectiles from appearing

	; Redraw invader shots
	call PrintInvadersShots

	ret
endp HidePauseMenu


; --------------------------------------
; Shows the exit confirmation menu overlay
; --------------------------------------
proc ShowExitConfirmMenu
	; Print semi-transparent overlay (centralizado)
	push 240
	push 80
	push 50
	push 40
	push 8  ; Dark gray color
	call PrintColor

	; Print "EXIT GAME?" text (centralizado)
	mov ah, 2
	xor bh, bh
	mov dh, 8
	mov dl, 17
	int 10h

	mov ah, 9
	mov dx, offset ExitConfirmString
	int 21h

	; Print "Press Y for Yes, N for No" text (centralizado)
	mov ah, 2
	xor bh, bh
	mov dh, 10
	mov dl, 7
	int 10h

	mov ah, 9
	mov dx, offset PressYesNoString
	int 21h

	ret
endp ShowExitConfirmMenu


; --------------------------------------
; Hides the exit confirmation menu and redraws game
; --------------------------------------
proc HideExitConfirmMenu
	; Clear the exit confirmation menu area (mesmas dimensões do overlay)
	push 240
	push 80
	push 50
	push 40
	push BlackColor
	call PrintColor

	; Clear the entire game area to remove any menu artifacts
	push 320
	push 165  ; From top to stats area
	push 0    ; Start line
	push 0    ; Start row
	push BlackColor
	call PrintColor

	; Redraw invaders
	call PrintInvaders

	; Redraw shooter
	push [ShooterFileHandle]
	push ShooterLength
	push ShooterHeight
	push ShooterLineLocation
	push [word ptr ShooterRowLocation]
	push offset FileReadBuffer
	call PrintBMP

	; Redraw invader shots
	call PrintInvadersShots

	ret
endp HideExitConfirmMenu


; ------------------------------------------------------------
; Moving invaders + player to initial location, removing shots
; Not getting back dead invaders
; ------------------------------------------------------------
proc MoveToStart
	mov [byte ptr InvadersMoveRightBool], 1
	mov [byte ptr InvadersMovesToSideDone], 0

	mov [byte ptr InvadersLoopMoveCounter], 0

	mov [byte ptr InvadersPrintStartLine], 10
	mov [byte ptr InvadersPrintStartRow], 8


	mov [word ptr ShooterRowLocation], 152
	mov [byte ptr PlayerShootingExists], 0

	mov [byte ptr InvadersShootingCurrentAmount], 0


	cld
	push ds
	pop es

	;Zero invaders shots locations:
	xor ax, ax

	mov di, offset InvadersShootingLineLocations
	mov cx, 10
	rep stosw

	mov di, offset InvadersShootingRowLocations
	mov cx, 10
	rep stosw

	ret
endp MoveToStart

; ------------------------------------------------------------
; Resetting invaders locations, shootings, etc for the game
; ------------------------------------------------------------
proc InitializeInvaders
    mov [InvadersLeftAmount], 24
    mov [byte ptr InvadersShootingMaxAmount], 5

    call MoveToStart

    cld
    push ds
    pop es

    ; Set two rows de invaders, assimétricas:
    ; Linha 1: 0 1 0 1 0 1 0 1
    ; Linha 2: 1 0 1 0 1 0 1 0
    mov di, offset InvadersStatusArray

    ; Primeira linha (8 elementos)
    mov al, 0
    stosb
    mov al, 1
    stosb
    mov al, 0
    stosb
    mov al, 1
    stosb
    mov al, 0
    stosb
    mov al, 1
    stosb
    mov al, 0
    stosb
    mov al, 1
    stosb

    ; Segunda linha (8 elementos)
    mov al, 1
    stosb
    mov al, 0
    stosb
    mov al, 1
    stosb
    mov al, 0
    stosb
    mov al, 1
    stosb
    mov al, 0
    stosb
    mov al, 1
    stosb
    mov al, 0
    stosb

    ; Zera o resto do array (8 elementos restantes)
    mov cx, 8
    mov al, 0
    rep stosb

    ret
endp InitializeInvaders


; -----------------------------------------------
; Resetting every stat to its initial game value
; -----------------------------------------------
proc InitializeGame
	mov [byte ptr LivesRemaining], 3
	mov [byte ptr GamePausedBool], 0  ; Ensure game starts unpaused
	mov [byte ptr ExitConfirmBool], 0  ; Ensure exit confirmation is off

	call InitializeInvaders

	ret
endp InitializeGame

; ------------------------------------------------
; Checking if player had died from invaders' shots
; If no, returned ax = 0, if yes, ax = 1
; ------------------------------------------------
proc CheckIfPlayerDied
	xor ch, ch
	mov cl, [InvadersShootingCurrentAmount]
	cmp cx, 0
	je @@returnZero

	xor si, si

@@checkShot:
	;check from above:
	mov ax, ShooterLineLocation
	sub ax, 3
	cmp ax, [InvadersShootingLineLocations + si]
	ja @@checkNextShot

	;check from below:
	add ax, 3
	add ax, 16 ;height
	cmp ax, [InvadersShootingLineLocations + si]
	jb @@checkNextShot

	;check from left
	mov ax, [ShooterRowLocation]
	dec ax
	cmp ax, [InvadersShootingRowLocations + si]
	ja @@checkNextShot

	;check from right:
	add ax, 16 ;length
	cmp ax, [InvadersShootingRowLocations + si]
	jb @@checkNextShot

	;Player killed:
	mov ax, 1
	ret

@@checkNextShot:
	inc si
	loop @@checkShot

@@returnZero:
	;Player not killed:
	xor ax, ax 
	ret
endp CheckIfPlayerDied


; ---------------------------------------------------------------
; Checks if the currently lowest line of invaders reached too low
; If true, ax = 1. If not, ax = 0.
; ---------------------------------------------------------------
proc CheckIfInvadersReachedBottom
	mov cx, 8
	mov bx, 16

@@checkLineTwo:
	cmp [InvadersStatusArray + bx], 0
	jne @@lineTwoNotEmpty

	inc bx
	loop @@checkLineTwo

	mov cx, 8
	mov bx, 8

@@checkLineOne:
	cmp [InvadersStatusArray + bx], 0
	jne @@lineOneNotEmpty
	
	inc bx
	loop @@checkLineOne

	mov cx, 8
	xor bx, bx

@@checkLineZero:
	cmp [InvadersStatusArray + bx], 0
	jne @@lineZeroNotEmpty
	
	inc bx
	loop @@checkLineZero

	jmp @@invadersDidNotReachBottom

@@lineTwoNotEmpty:
	cmp [word ptr InvadersPrintStartLine], ShooterLineLocation - 59
	ja @@invadersReachedBottom

	jmp @@invadersDidNotReachBottom

@@lineOneNotEmpty:
	cmp [word ptr InvadersPrintStartLine], ShooterLineLocation - 39
	ja @@invadersReachedBottom

	jmp @@invadersDidNotReachBottom

@@lineZeroNotEmpty:
	cmp [word ptr InvadersPrintStartLine], ShooterLineLocation - 19
	ja @@invadersReachedBottom


@@invadersDidNotReachBottom:
	xor ax, ax
	ret

@@invadersReachedBottom:
	mov ax, 1
	ret
endp CheckIfInvadersReachedBottom


; -----------------------------------------------------------
; Initiating the game, combining the game parts together
; Handles shooter + Invaders hits and deaths, movements, etc.
; -----------------------------------------------------------
proc PlayGame
	push offset InvaderFileName
	push offset InvaderFileHandle
	call OpenFile

	push offset ShooterFileName
	push offset ShooterFileHandle
	call OpenFile

	call InitializeGame

	call ClearScreen


@@gameStart:
	call PrintStatsArea
	call UpdateLives

	call CheckAndMoveInvaders

	push [ShooterFileHandle]
	push ShooterLength
	push ShooterHeight
	push ShooterLineLocation
	push [word ptr ShooterRowLocation]
	push offset FileReadBuffer
	call PrintBMP


	call PrintInvaders


	;Print countdown to start:
	mov cx, 3
	mov dx, 33h
@@printCountdownNum:
	push cx
	push dx

	mov ah, 2
	xor bh, bh
	mov dh, 12
	mov dl, 19
	int 10h

	pop dx
	push dx
	mov ah, 2
	int 21h

	push 18
	call Delay

	pop dx
	dec dx
	pop cx
	loop @@printCountdownNum

	;clear number:
	mov ah, 2
	xor bh, bh
	mov dh, 12
	mov dl, 19
	int 10h

	xor dl, dl
	mov ah, 2
	int 21h


@@readKey:
	mov ah, 1
	int 16h

	jz @@checkIfPaused

	;Clean buffer:
 	push ax
 	xor al, al
 	mov ah, 0ch
 	int 21h
 	pop ax
	
	;Check which key was pressed:
	cmp ah, 1 ;Esc
	je @@procEnd

	cmp ah, 10h ;Q for quit with confirmation
	je @@quitPressed

	cmp ah, 19h ;P for pause (scancode for P)
	je @@pausePressed

	; Check if exit confirmation is showing - handle Y/N keys
	cmp [byte ptr ExitConfirmBool], 1
	je @@handleExitConfirm

	; Check if game is paused - if so, ignore other keys except P
	cmp [byte ptr GamePausedBool], 1
	je @@readKey

	cmp ah, 11h ;W
	je @@shootPressed

	cmp ah, 4Bh ;Left
	jne @@checkRight

	cmp [word ptr ShooterRowLocation], 21
	jb @@clearShot

	;Clear current shooter print:
	push ShooterLength
	push ShooterHeight
	push ShooterLineLocation
	push [word ptr ShooterRowLocation]
	push BlackColor
	call PrintColor

	sub [word ptr ShooterRowLocation], 10
	jmp @@printAgain

@@checkRight:
	cmp ah, 4Dh
	jne @@readKey

	cmp [word ptr ShooterRowLocation], 290
	ja @@clearShot

	;Clear current shooter print:
	push ShooterLength
	push ShooterHeight
	push ShooterLineLocation
	push [word ptr ShooterRowLocation]
	push BlackColor
	call PrintColor

	add [word ptr ShooterRowLocation], 10

@@printAgain:
	push [ShooterFileHandle]
	push ShooterLength
	push ShooterHeight
	push ShooterLineLocation
	push [word ptr ShooterRowLocation]
	push offset FileReadBuffer
	call PrintBMP
	jmp @@checkIfPaused

@@pausePressed:
	; Check if exit confirmation menu is already open - if so, ignore pause
	cmp [byte ptr ExitConfirmBool], 1
	je @@readKey

	; Toggle pause state
	cmp [byte ptr GamePausedBool], 0
	je @@pauseGame

	; Unpause game
	mov [byte ptr GamePausedBool], 0
	call HidePauseMenu
	jmp @@readKey

@@pauseGame:
	; Pause game
	mov [byte ptr GamePausedBool], 1
	call ShowPauseMenu
	jmp @@readKey

@@quitPressed:
	; Check if game is paused - if so, ignore quit
	cmp [byte ptr GamePausedBool], 1
	je @@readKey

	; Show exit confirmation menu
	mov [byte ptr ExitConfirmBool], 1
	call ShowExitConfirmMenu
	jmp @@readKey

@@handleExitConfirm:
	; Handle Y/N keys for exit confirmation
	cmp ah, 15h ;Y for yes (scancode for Y)
	je @@confirmExit

	cmp ah, 31h ;N for no (scancode for N)
	je @@cancelExit

	; If other key pressed, ignore and continue reading
	jmp @@readKey

@@confirmExit:
	; User confirmed exit
	jmp @@procEnd

@@cancelExit:
	; User cancelled exit, hide menu and continue
	mov [byte ptr ExitConfirmBool], 0
	call HideExitConfirmMenu
	jmp @@readKey

@@checkIfPaused:
	; If exit confirmation is showing, skip game logic
	cmp [byte ptr ExitConfirmBool], 1
	je @@readKey

	; If game is paused, skip game logic
	cmp [byte ptr GamePausedBool], 1
	je @@readKey

@@checkShotStatus:
	;Check if shooting already exists in screen:
	cmp [byte ptr PlayerShootingExists], 0
	jne @@moveShootingUp

	jmp @@clearShot

@@shootPressed:
	;Check if shooting already exists in screen:
	cmp [byte ptr PlayerShootingExists], 0
	jne @@moveShootingUp

@@initiateShot:
	;Set initial shot location:
	mov ax, ShooterLineLocation
	sub ax, 6
	mov [word ptr PlayerShootingLineLocation], ax
	mov ax, [ShooterRowLocation]
	add ax, 7
	mov [word ptr PlayerShootingRowLocation], ax

	mov [byte ptr PlayerShootingExists], 1
	jmp @@printShooting

@@moveShootingUp:
	cmp [word ptr PlayerShootingLineLocation], 10
	jb @@removeShot

	sub [word ptr PlayerShootingLineLocation], 10

@@printShooting:
	push ShootingLength
	push ShootingHeight
	push [word ptr PlayerShootingLineLocation]
	push [word ptr PlayerShootingRowLocation]
	push RedColor
	call PrintColor

	jmp @@clearShot

@@removeShot:
	mov [byte ptr PlayerShootingExists], 0
	mov [word ptr PlayerShootingLineLocation], 0
	mov [word ptr PlayerShootingRowLocation], 0

@@clearShot:
	push 2
	call Delay


	;Clear shot:
	push ShootingLength
	push ShootingHeight
	push [word ptr PlayerShootingLineLocation]
	push [word ptr PlayerShootingRowLocation]
	push BlackColor
	call PrintColor

	cmp [byte ptr InvadersLeftAmount], 0
	je @@setNewLevel

	;Check if invader killed:
	call CheckAndKillInvader

@@moveInvaders:
	call ClearInvadersShots

	call CheckAndMoveInvaders
	
	call CheckIfInvadersReachedBottom
	cmp ax, 1
	je @@playerDied

	call UpdateInvadersShots
	call InvadersRandomShot
	call printInvadersShots


	;Check if player was killed:
	call CheckIfPlayerDied
	cmp ax, 0
	je @@readKey

@@playerDied:
	;Player died:
	push 18
	call Delay

	;decrease amount of lives left, check if 0 left:
	dec [byte ptr LivesRemaining]
	cmp [byte ptr LivesRemaining], 0
	je @@printDied

	;Clear screan without stats area:
	push 320
	push StatsAreaBorderLine
	push 0 ;line
	push 0 ;row
	push BlackColor
	call PrintColor

	mov ah, 2
	xor bh, bh
	mov dh, 12
	mov dl, 10
	int 10h

	;tell user he was hit...
	mov ah, 9
	mov dx, offset HitString
	int 21h

; Nice blink animation for death:
	mov cx, 3
@@blinkShooter:
	push cx

	push ShooterLength
	push ShooterHeight
	push ShooterLineLocation
	push [word ptr ShooterRowLocation]
	push BlackColor
	call PrintColor

	push 6
	call Delay

	push [word ptr ShooterFileHandle]
	push ShooterLength
	push ShooterHeight
	push ShooterLineLocation
	push [word ptr ShooterRowLocation]
	push offset FileReadBuffer
	call PrintBMP

	push 6
	call Delay

	pop cx
	loop @@blinkShooter

@@resetBeforeContinueAfterDeath:
	call MoveToStart

	push 24
	call Delay

	call ClearScreen

	
	jmp @@gameStart


	jmp @@readKey

@@printDied:
	call ClearScreen
; Print a message when game is over:
	mov ah, 2
	xor bh, bh
	mov dh, 12
	mov dl, 17
	int 10h

	mov ah, 9
	mov dx, offset GameOverString
	int 21h

	push 54
	call Delay

	jmp @@procEnd


@@setNewLevel:
	; Game completed - all invaders destroyed!
	call ClearScreen
	
	; Print win message to user:
	mov ah, 2
	xor bh, bh
	mov dh, 12
	mov dl, 18
	int 10h

	mov ah, 9
	mov dx, offset WinString
	int 21h
	
	push 54
	call Delay

	jmp @@procEnd


@@procEnd:
	push [ShooterFileHandle]
	call CloseFile

	push [InvaderFileHandle]
	call CloseFile

	ret
endp PlayGame