DATASEG
include "Strings.asm"

	DebugBool						db	0

	; Difficulty settings
	DifficultyLevel					db	1		; 0=Easy, 1=Medium, 2=Hard
	SelectedMenuItem				db	1		; Current menu selection (0-2)
	InvaderShotChance				db	10		; Chance of invaders shooting (lower = more frequent)

	;Files:

	RandomFileName					db	'Assets/Random.txt', 0
	RandomFileHandle				dw	?

	ScoresFileName					db	'Assets/Scores.txt', 0
	ScoresFileHandle				dw	?

	ScoreTableFileName				db	'Assets/ScoreTab.bmp', 0
	ScoreTableFileHandle			dw	?

	AskSaveFileName					db	'Assets/AskSave.bmp', 0
	AskSaveFileHandle				dw	?

	MainMenuFileName				db	'Assets/MainMenu.bmp',0
	MainMenuFileHandle				dw	?

	InstructionsFileName			db	'Assets/Instruct.bmp',0
	InstructionsFileHandle			dw	?

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

	Score							db	?
	LivesRemaining					db	?
	Level							db	?

	DidNotDieInLevelBool			db	?


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
include "Invader.asm"
include "Procs.asm"

; -----------------------------------------------------------
; Prints the lower game area with score, lives, level, etc...
; -----------------------------------------------------------
proc PrintStatsArea
	; Print border:
	push 320
	push 2
	push StatsAreaBorderLine
	push 0
	push 100
	call PrintColor

	;Print labels:

	;Level label:
	xor bh, bh
	mov dh, 23
	mov dl, 1
	mov ah, 2
	int 10h

	mov ah, 9
	mov dx, offset LevelString
	int 21h


	;Score label:
	xor bh, bh
	mov dh, 23
	mov dl, 29
	mov ah, 2
	int 10h

	mov ah, 9
	mov dx, offset ScoreString
	int 21h

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


;----------------------------------
; Updates the score shown on screen
;----------------------------------
proc UpdateScoreStat
	xor bh, bh
	mov dh, 23
	mov dl, 36
	mov ah, 2
	int 10h

	xor ah, ah
	mov al, [Score]
	push ax
	call HexToDecimal

	push ax
	mov ah, 2
	int 21h
	pop dx
	xchg dl, dh
	int 21h
	xchg dl, dh
	int 21h

	ret
endp UpdateScoreStat


; ---------------------------------------
; Updates the level # and the score count
; ---------------------------------------
proc UpdateStats
	;Update level:
	xor bh, bh
	mov dh, 23
	mov dl, 8
	mov ah, 2
	int 10h

	mov ah, 2
	mov dl, [byte ptr Level]
	add dl, 30h
	int 21h

	;Update score:
	call UpdateScoreStat

	ret
endp UpdateStats


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
; Resetting invaders locations, shootings, etc for a new level
; ------------------------------------------------------------
proc InitializeLevel
    mov [InvadersLeftAmount], 24

    cmp [byte ptr Level], 1
    jne @@checkLevelTwo

    mov [byte ptr InvadersShootingMaxAmount], 3
    jmp @@resetDidNotDieBool

@@checkLevelTwo:
    cmp [byte ptr Level], 2
    jne @@setLevelThree

    mov [byte ptr InvadersShootingMaxAmount], 5
    jmp @@resetDidNotDieBool

@@setLevelThree:
    mov [byte ptr InvadersShootingMaxAmount], 7

@@resetDidNotDieBool:
    mov [byte ptr DidNotDieInLevelBool], 1 ;true

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
endp InitializeLevel


; -----------------------------------------------
; Resetting every stat to its initial game value,
; and setting the first level
; -----------------------------------------------
proc InitializeGame
	mov [byte ptr Score], 0
	mov [byte ptr LivesRemaining], 3
	mov [byte ptr Level], 1


	call InitializeLevel

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


@@firstLevelPrint:
	call PrintStatsArea
	call UpdateStats
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

	jz @@checkShotStatus

	;Clean buffer:
 	push ax
 	xor al, al
 	mov ah, 0ch
 	int 21h
 	pop ax
	
	;Check which key was pressed:
	cmp ah, 1 ;Esc
	je @@procEnd

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
	mov dl, 8
	int 10h

	;tell user he was hit, -5 score...
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

	;sub 5 score if possible, if he doesn't have 5 yet, just reset to 0:
	cmp [byte ptr Score], 5
	jb @@resetScoreAfterDeath

	sub [byte ptr Score], 5
	jmp @@resetBeforeContinueAfterDeath


@@resetScoreAfterDeath:
	mov [byte ptr Score], 0

@@resetBeforeContinueAfterDeath:
	call MoveToStart

	mov [byte ptr DidNotDieInLevelBool], 0 ;false


	push 24
	call Delay

	call ClearScreen

	
	jmp @@firstLevelPrint


	jmp @@readKey

@@printDied:
	call ClearScreen
; Print a message when game is over:
	mov ah, 2
	xor bh, bh
	mov dh, 12
	mov dl, 15
	int 10h

	mov ah, 9
	mov dx, offset GameOverString
	int 21h

	;print actual score #:
	mov ah, 2
	xor bh, bh
	mov dh, 13
	mov dl, 10
	int 10h

	mov ah, 9
	mov dx, offset YouEarnedXString
	int 21h
	
	xor ah, ah
	mov al, [Score]
	push ax
	call HexToDecimal

	push ax
	mov ah, 2
	int 21h
	pop dx
	xchg dl, dh
	int 21h
	xchg dl, dh
	int 21h

	mov ah, 9
	mov dx, offset ScoreWordString
	int 21h
	
	push 54
	call Delay

	jmp @@procEnd


@@setNewLevel:
	cmp [byte ptr DidNotDieInLevelBool], 1
	jne @@SkipPerfectLevelBonus

	add [byte ptr Score], 5 ;special bonus for perfect level (no death in level)

	;print bonus message:
	mov ah, 2
	xor bh, bh
	mov dh, 12
	mov dl, 8
	int 10h

	mov ah, 9
	mov dx, offset PerfectLevelString
	int 21h

	push 24
	call Delay

	call ClearScreen


@@SkipPerfectLevelBonus:

	cmp [byte ptr Level], 3
	je @@printWin


	inc [byte ptr Level]
	call InitializeLevel

	call ClearScreen
	jmp @@firstLevelPrint

@@printWin:
; Print win message to user (finished 3 levels):
	mov ah, 9
	mov dx, offset WinString
	int 21h

	;print actual score #:
	mov ah, 2
	xor bh, bh
	mov dh, 13
	mov dl, 15
	int 10h

	mov ah, 9
	mov dx, offset YouEarnedXString
	int 21h

	xor ah, ah
	mov al, [Score]
	push ax
	call HexToDecimal

	push ax
	mov ah, 2
	int 21h
	pop dx
	xchg dl, dh
	int 21h
	xchg dl, dh
	int 21h

	mov ah, 9
	mov dx, offset ScoreWordString
	int 21h


@@procEnd:
	push [ShooterFileHandle]
	call CloseFile

	push [InvaderFileHandle]
	call CloseFile

	ret
endp PlayGame