CODESEG
; ----------------------------------------
; Print the difficulty selection menu, handle user choices
; ----------------------------------------
proc PrintMainMenu
	; Initialize menu selection to medium difficulty
	mov [byte ptr SelectedMenuItem], 1
	mov [byte ptr DifficultyLevel], 1

@@printMenu:
	; Set text mode for menu
	mov ax, 03h
	int 10h
	
	call PrintDifficultyMenu

@@getKey:
	xor ah, ah
	int 16h

	; Check for Up Arrow (scan code 48h)
	cmp ah, 48h
	je @@moveUp

	; Check for Down Arrow (scan code 50h) 
	cmp ah, 50h
	je @@moveDown

	; Check for Enter key (scan code 1Ch)
	cmp ah, 1Ch
	je @@startGame

	; Check for Esc key (scan code 1)
	cmp ah, 1
	je @@procEnd

	jmp @@getKey

@@moveUp:
	mov al, [SelectedMenuItem]
	cmp al, 0
	je @@wrapToBottom
	dec al
	mov [SelectedMenuItem], al
	jmp @@updateDisplay

@@wrapToBottom:
	mov [byte ptr SelectedMenuItem], 2
	jmp @@updateDisplay

@@moveDown:
	mov al, [SelectedMenuItem]
	cmp al, 2
	je @@wrapToTop
	inc al
	mov [SelectedMenuItem], al
	jmp @@updateDisplay

@@wrapToTop:
	mov [byte ptr SelectedMenuItem], 0

@@updateDisplay:
	call UpdateDifficultyMenuDisplay
	jmp @@getKey

@@startGame:
	; Set difficulty level based on selection
	mov al, [SelectedMenuItem]
	mov [DifficultyLevel], al
	
	; Set difficulty parameters
	call SetDifficultyParameters
	
	; Switch to graphics mode for game
	mov ax, 13h
	int 10h
	
	call PlayGame

	; Return to text mode and show menu again
	mov ax, 03h
	int 10h
	jmp @@printMenu

@@procEnd:
	; Clear screen before exit
	mov ah, 00h
	mov al, 03h
	int 10h
	ret
endp PrintMainMenu

