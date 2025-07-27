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
	; Check keyboard flags instead of using int 16h
	
	; Check for Up Arrow
	cmp [byte ptr flag_seta_cima], 1
	je @@moveUp

	; Check for Down Arrow
	cmp [byte ptr flag_seta_baixo], 1
	je @@moveDown

	; Check for Enter key
	cmp [byte ptr flag_enter], 1
	je @@startGame

	; Check for Esc key
	cmp [byte ptr flag_esc], 1
	je @@procEnd

	jmp @@getKey

@@moveUp:
	; Clear the flag
	mov [byte ptr flag_seta_cima], 0
	
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
	; Clear the flag
	mov [byte ptr flag_seta_baixo], 0
	
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
	; Clear the flag
	mov [byte ptr flag_enter], 0
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
	; Clear the ESC flag
	mov [byte ptr flag_esc], 0
	
	; Clear screen before exit
	mov ah, 00h
	mov al, 03h
	int 10h
	ret
endp PrintMainMenu

