; Keyboard interrupt handler using INT 9h (hardware keyboard interrupt)
; Based on Tecbuf program implementation

DATASEG
    ; Storage for original INT 9h handler
    old_int9_handler_offset  dw 0
    old_int9_handler_segment dw 0

    ; Keyboard state flags
    flag_move_esquerda  db 0    ; Left arrow key
    flag_move_direita   db 0    ; Right arrow key
    flag_atira          db 0    ; W key (shoot)
    flag_fecha_jogo     db 0    ; Q key (quit)
    flag_pausa          db 0    ; P key (pause)
    flag_esc            db 0    ; ESC key
    flag_confirma_sim   db 0    ; Y key (yes confirmation)
    flag_confirma_nao   db 0    ; N key (no confirmation)
    flag_seta_cima      db 0    ; Up arrow key (menu navigation)
    flag_seta_baixo     db 0    ; Down arrow key (menu navigation)
    flag_enter          db 0    ; Enter key (menu selection)

CODESEG

; ---------------------------------------------------------
; Install the custom keyboard interrupt handler (INT 9h)
; ---------------------------------------------------------
proc instala_isr
    CLI                         ; Disable interrupts
    xor ax, ax
    mov es, ax                  ; ES = 0 (interrupt vector table)
    
    ; Save original INT 9h handler
    mov ax, [es:09h*4]
    mov [old_int9_handler_offset], ax
    mov ax, [es:09h*4+2]
    mov [old_int9_handler_segment], ax
    
    ; Install new handler
    mov [es:09h*4+2], cs
    mov [es:09h*4], offset keyboard_isr
    
    STI                         ; Re-enable interrupts
    ret
endp instala_isr

; ---------------------------------------------------------
; Restore the original keyboard interrupt handler
; ---------------------------------------------------------
proc desinstala_isr
    CLI                         ; Disable interrupts
    push ds
    
    xor ax, ax
    mov es, ax                  ; ES = 0 (interrupt vector table)
    
    ; Restore original handler
    mov ax, [old_int9_handler_offset]
    mov [es:09h*4], ax
    mov ax, [old_int9_handler_segment]
    mov [es:09h*4+2], ax
    
    pop ds
    STI                         ; Re-enable interrupts
    ret
endp desinstala_isr

; ---------------------------------------------------------
; Custom keyboard interrupt service routine
; Handles key press and release events
; ---------------------------------------------------------
proc keyboard_isr
    push ax
    push dx
    
    in al, 60h                  ; Read scan code from keyboard port
    
    ; --- LEFT ARROW KEY ---
    cmp al, 4Bh                 ; Left arrow press
    je @@seta_esquerda_press
    cmp al, 0CBh                ; Left arrow release (scan code + 80h)
    je @@seta_esquerda_release
    
    ; --- RIGHT ARROW KEY ---
    cmp al, 4Dh                 ; Right arrow press
    je @@seta_direita_press
    cmp al, 0CDh                ; Right arrow release
    je @@seta_direita_release
    
    ; --- UP ARROW KEY ---
    cmp al, 48h                 ; Up arrow press
    je @@seta_cima_press
    cmp al, 0C8h                ; Up arrow release
    je @@seta_cima_release
    
    ; --- DOWN ARROW KEY ---
    cmp al, 50h                 ; Down arrow press
    je @@seta_baixo_press
    cmp al, 0D0h                ; Down arrow release
    je @@seta_baixo_release
    
    ; --- ENTER KEY ---
    cmp al, 1Ch                 ; Enter key press
    je @@tecla_enter_press
    cmp al, 9Ch                 ; Enter key release
    je @@tecla_enter_release
    
    ; --- W KEY (SHOOT) ---
    cmp al, 11h                 ; W key press
    je @@tecla_w_press
    cmp al, 91h                 ; W key release (11h + 80h)
    je @@tecla_w_release
    
    ; --- Q KEY (QUIT) ---
    cmp al, 10h                 ; Q key press
    je @@tecla_q_press
    cmp al, 90h                 ; Q key release
    je @@tecla_q_release
    
    ; --- P KEY (PAUSE) ---
    cmp al, 19h                 ; P key press
    je @@tecla_p_press
    cmp al, 99h                 ; P key release
    je @@tecla_p_release
    
    ; --- ESC KEY ---
    cmp al, 01h                 ; ESC key press
    je @@tecla_esc_press
    cmp al, 81h                 ; ESC key release
    je @@tecla_esc_release
    
    ; --- Y KEY (YES CONFIRMATION) ---
    cmp al, 15h                 ; Y key press
    je @@tecla_y_press
    cmp al, 95h                 ; Y key release
    je @@tecla_y_release
    
    ; --- N KEY (NO CONFIRMATION) ---
    cmp al, 31h                 ; N key press
    je @@tecla_n_press
    cmp al, 0B1h                ; N key release
    je @@tecla_n_release
    
    jmp @@fim_isr
    
@@seta_esquerda_press:
    mov [byte ptr flag_move_esquerda], 1
    jmp @@fim_isr
    
@@seta_esquerda_release:
    mov [byte ptr flag_move_esquerda], 0
    jmp @@fim_isr
    
@@seta_direita_press:
    mov [byte ptr flag_move_direita], 1
    jmp @@fim_isr
    
@@seta_direita_release:
    mov [byte ptr flag_move_direita], 0
    jmp @@fim_isr
    
@@tecla_w_press:
    mov [byte ptr flag_atira], 1
    jmp @@fim_isr
    
@@tecla_w_release:
    mov [byte ptr flag_atira], 0
    jmp @@fim_isr
    
@@tecla_q_press:
    mov [byte ptr flag_fecha_jogo], 1
    jmp @@fim_isr
    
@@tecla_q_release:
    mov [byte ptr flag_fecha_jogo], 0
    jmp @@fim_isr
    
@@tecla_p_press:
    mov [byte ptr flag_pausa], 1
    jmp @@fim_isr
    
@@tecla_p_release:
    mov [byte ptr flag_pausa], 0
    jmp @@fim_isr
    
@@tecla_esc_press:
    mov [byte ptr flag_esc], 1
    jmp @@fim_isr
    
@@tecla_esc_release:
    mov [byte ptr flag_esc], 0
    jmp @@fim_isr
    
@@tecla_y_press:
    mov [byte ptr flag_confirma_sim], 1
    jmp @@fim_isr
    
@@tecla_y_release:
    mov [byte ptr flag_confirma_sim], 0
    jmp @@fim_isr
    
@@tecla_n_press:
    mov [byte ptr flag_confirma_nao], 1
    jmp @@fim_isr
    
@@tecla_n_release:
    mov [byte ptr flag_confirma_nao], 0
    jmp @@fim_isr

@@seta_cima_press:
    mov [byte ptr flag_seta_cima], 1
    jmp @@fim_isr
    
@@seta_cima_release:
    mov [byte ptr flag_seta_cima], 0
    jmp @@fim_isr
    
@@seta_baixo_press:
    mov [byte ptr flag_seta_baixo], 1
    jmp @@fim_isr
    
@@seta_baixo_release:
    mov [byte ptr flag_seta_baixo], 0
    jmp @@fim_isr
    
@@tecla_enter_press:
    mov [byte ptr flag_enter], 1
    jmp @@fim_isr
    
@@tecla_enter_release:
    mov [byte ptr flag_enter], 0
    jmp @@fim_isr
    
@@fim_isr:
    ; Send End of Interrupt signal to PIC
    mov al, 20h
    out 20h, al
    
    pop dx
    pop ax
    iret                        ; Return from interrupt
endp keyboard_isr

; ---------------------------------------------------------
; Clear all keyboard flags (useful for initialization)
; ---------------------------------------------------------
proc clear_keyboard_flags
    mov [byte ptr flag_move_esquerda], 0
    mov [byte ptr flag_move_direita], 0
    mov [byte ptr flag_atira], 0
    mov [byte ptr flag_fecha_jogo], 0
    mov [byte ptr flag_pausa], 0
    mov [byte ptr flag_esc], 0
    mov [byte ptr flag_confirma_sim], 0
    mov [byte ptr flag_confirma_nao], 0
    mov [byte ptr flag_seta_cima], 0
    mov [byte ptr flag_seta_baixo], 0
    mov [byte ptr flag_enter], 0
    ret
endp clear_keyboard_flags

; ---------------------------------------------------------
; Check if any movement key is pressed
; Returns: AX = 1 if any movement key pressed, 0 otherwise
; ---------------------------------------------------------
proc check_movement_keys
    xor ax, ax
    
    cmp [byte ptr flag_move_esquerda], 1
    je @@movement_detected
    
    cmp [byte ptr flag_move_direita], 1
    je @@movement_detected
    
    jmp @@no_movement
    
@@movement_detected:
    mov ax, 1
    
@@no_movement:
    ret
endp check_movement_keys
