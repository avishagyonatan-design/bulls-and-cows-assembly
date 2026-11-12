%include "io64.inc"

section .data
    ; === הגדרות משחק ===
    secret_num   dq 0                ; יחושב רנדומלית בתחילת המשחק
    n            dq 10               ; מספר הניסיונות
    
    ; הודעות
    msg_start    db "Welcome! Guess the 4-digit number (1-9, no repeats).", 0
    msg_prompt   db "Enter guess: ", 0
    msg_err      db "Invalid input! (Must be 4 digits, 1-9 only, no repeats).", 0
    msg_win      db "You Won! Exact match.", 0
    msg_lose     db "Game Over. The number was: ", 0
    msg_hist     db "--- History ---", 0
    msg_sep      db " | ", 0

    ; === משתנים ===
    current_turn dq 0                
    temp_guess   dq 0                ; המספר הסופי (אחרי המרה)
    
    ; חוצץ לקליטת מחרוזת
    input_str    times 10 db 0       

    ; מערכים
    secret_arr   db 0, 0, 0, 0       
    guess_arr    db 0, 0, 0, 0       
    
    ; היסטוריה
    hist_guesses times 20 dq 0       
    hist_bulls   times 20 db 0       
    hist_cows    times 20 db 0       

    curr_bulls   dq 0
    curr_cows    dq 0

section .text
global Cmain

;Main Program

Cmain:
    mov rbp, rsp          ; יישור מחסנית

    ; במקום לאתחל מספר קבוע, אני מגרילה מספר!
    call generate_random_secret
    
    call game_manager     ; הפעלת המשחק
    
    xor rax, rax
    ret
                        ; Generate Random Secret
; מגרילה 4 ספרות שונות (1-9) ושומרת ב-secret_arr וב-secret_num
generate_random_secret:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    push r8

    mov rcx, 0      ; מונה ספרות שנמצאו (0 עד 3)
    mov rdi, secret_arr

retry_digit:
    ; קריאת שעון המעבד (Time Stamp Counter)
    ; התוצאה מגיעה ל-EDX:EAX
    rdtsc           
    
    ; מניפולציה קטנה לערבוב הביטים (כדי למנוע חזרות מהירות)
    xor rax, rdx    
    
    ; נרמול לטווח 1-9                 
    xor rdx, rdx    ; איפוס שארית
    mov rbx, 9
    div rbx         ; חלוקה ב-9. השארית ב-RDX היא 0-8
    inc rdx         ; הופכים את זה ל 1-9
    
    mov r8b, dl     ; שומרים את הספרה המוגרלת ב-R8B

    ;בדיקת כפילויות                  
    ; רצים על המערך עד האינדקס הנוכחי (RCX) לבדוק אם המספר קיים
    mov rsi, 0
check_dup:
    cmp rsi, rcx
    jge is_unique   ; אם הגענו ל-RCX סימן שאין כפילות
    
    cmp [rdi + rsi], r8b
    je retry_digit  ; מצאנו כפילות! נסה להגריל שוב
    
    inc rsi
    jmp check_dup

is_unique:
    ; המספר ייחודי - נשמור אותו                
    mov [rdi + rcx], r8b
    inc rcx
    cmp rcx, 4
    jl retry_digit

    ;סיום ההגרלה: שמירת המספר השלם                
    ; ממירים את המערך למספר שלם לתוך secret_num (כדי להציג בהפסד)
    mov rax, 0
    xor rbx, rbx
    
    ; אלפים                  
    mov bl, [secret_arr + 0]
    imul rbx, 1000
    add rax, rbx
    ; מאות                  
    mov bl, [secret_arr + 1]
    imul rbx, 100
    add rax, rbx
    ; עשרות                 
    mov bl, [secret_arr + 2]
    imul rbx, 10
    add rax, rbx
    ; אחדות                 
    mov bl, [secret_arr + 3]
    add rax, rbx
    
    mov [secret_num], rax

    pop r8
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret
               ; Game Manager
game_manager:
    push rbx
    push rcx
    push rdx
    push rsi

    PRINT_STRING msg_start
    NEWLINE

game_loop:
    mov rax, [current_turn]
    cmp rax, [n]
    je handle_lose

    ; קלט בטוח                  
    call get_safe_input
    
    ; שמירה בהיסטוריה                  
    mov rsi, [current_turn]
    mov rax, [temp_guess]
    mov [hist_guesses + rsi*8], rax

    ; חישוב תוצאות              
    call calc_results

    ; שמירת תוצאות             
    mov rsi, [current_turn]
    mov rax, [curr_bulls]
    mov [hist_bulls + rsi], al
    mov rax, [curr_cows]
    mov [hist_cows + rsi], al

    inc qword [current_turn]

    cmp qword [curr_bulls], 4
    je handle_win

    jmp game_loop

handle_win:
    PRINT_STRING msg_win
    NEWLINE
    call print_history
    jmp exit_manager

handle_lose:
    PRINT_STRING msg_lose
    PRINT_DEC 8, [secret_num] ; הדפסת המספר הסודי שהוגרל
    NEWLINE
    call print_history

exit_manager:
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret
; Get Safe Input (תו-אחר-תו, מונע קריסות)
get_safe_input:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi

retry_safe:
    PRINT_STRING msg_prompt
    
    mov dword [guess_arr], 0
    mov rcx, 0      

read_char_loop:
    GET_CHAR al
    
    cmp al, 10      ; Enter
    je error_short_input

    cmp al, '1'
    jl input_has_garbage
    cmp al, '9'
    jg input_has_garbage

    sub al, '0'
    mov [guess_arr + rcx], al
    
    inc rcx
    cmp rcx, 4
    jl read_char_loop

    ; בדיקת ה-Enter הסופי              
    GET_CHAR al
    cmp al, 10
    jne input_has_garbage 

    ; בדיקת כפילויות בניחוש             
    mov rcx, 0         
check_dup_outer:
    mov rdx, rcx
    inc rdx            
check_dup_inner:
    cmp rdx, 4
    jge next_dup_outer
    
    mov al, [guess_arr + rcx]
    mov bl, [guess_arr + rdx]
    cmp al, bl
    je error_logic      

    inc rdx
    jmp check_dup_inner

next_dup_outer:
    inc rcx
    cmp rcx, 3
    jl check_dup_outer

    ; המרה למספר שלם               
    mov rax, 0
    xor rbx, rbx
    
    mov bl, [guess_arr + 0]
    imul rbx, 1000
    add rax, rbx
    
    mov bl, [guess_arr + 1]
    imul rbx, 100
    add rax, rbx
    
    mov bl, [guess_arr + 2]
    imul rbx, 10
    add rax, rbx
    
    mov bl, [guess_arr + 3]
    add rax, rbx
    
    mov [temp_guess], rax

    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; טיפול בשגיאות קלט            
input_has_garbage:
    cmp al, 10       
    je print_err
flush_loop:
    GET_CHAR al      
    cmp al, 10       
    jne flush_loop

print_err:
    PRINT_STRING msg_err
    NEWLINE
    jmp retry_safe   

error_short_input:
    PRINT_STRING msg_err
    NEWLINE
    jmp retry_safe

error_logic:
    PRINT_STRING msg_err
    NEWLINE
    jmp retry_safe
                ;  Calc Results
calc_results:
    push rax
    push rbx
    push rcx
    push rdx

    mov qword [curr_bulls], 0
    mov qword [curr_cows], 0

    ; Bulls
    mov rcx, 0
bulls_loop:
    mov al, [secret_arr + rcx]
    mov bl, [guess_arr + rcx]
    cmp al, bl
    jne skip_bull
    inc qword [curr_bulls]
skip_bull:
    inc rcx
    cmp rcx, 4
    jl bulls_loop

    ; Cows
    mov rcx, 0
cow_outer:
    mov rdx, 0
cow_inner:
    cmp rcx, rdx
    je skip_cow_logic
    
    mov al, [guess_arr + rcx]
    mov bl, [secret_arr + rdx]
    cmp al, bl
    jne skip_cow_logic
    
    inc qword [curr_cows]
    jmp next_cow_outer

skip_cow_logic:
    inc rdx
    cmp rdx, 4
    jl cow_inner

next_cow_outer:
    inc rcx
    cmp rcx, 4
    jl cow_outer

    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret
                 ;  Print History
print_history:
    push rax
    push rcx
    
    PRINT_STRING msg_hist
    NEWLINE
    
    mov rcx, 0
hist_loop:
    cmp rcx, [current_turn]
    jge hist_done

    PRINT_DEC 8, [hist_guesses + rcx*8]
    PRINT_STRING msg_sep
    
    xor rax, rax
    mov al, [hist_bulls + rcx]
    PRINT_DEC 1, al
    PRINT_STRING msg_sep
    
    mov al, [hist_cows + rcx]
    PRINT_DEC 1, al
    NEWLINE

    inc rcx
    jmp hist_loop

hist_done:
    pop rcx
    pop rax
    ret
