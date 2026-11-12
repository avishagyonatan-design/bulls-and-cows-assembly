;avishag yonatan
;17.01.2026
;התוכנית מממשת משחק בו המשתמש מנחש 4 ספרות בתוך 10 ניסיונות 
;מנגנון וקלט: שימוש בקריאה ידנית של תווים כדי למנוע קריסות 
;מבנה מודולרי: הקוד מחולק לפונקציות ברורות עם ניהול מחסנית תקין
;תיעוד היסטוריה : כל ניחוש ותוצאותיו נשמרים במערכים ומודפסים בטבלה בסיום המשחק
;בדיקת תקינות: וידוא שהקלט מכיל 4 ספרות שונות בין 1 ל 9

%include "io64.inc"

section .data
    ; === הגדרות קבועות ===                
    secret_num   dq 1234             ; המספר הסודי (ניתן לשינוי)
    n            dq 10               ; מספר הניסיונות המותר
    divisors     dq 1000, 100, 10, 1 ; מחלקים לפירוק המספר

    ; === הודעות למשתמש ===                
    msg_start    db "Welcome! Bulls & Cows. Guess a 4-digit number (1-9, no repeats).", 0
    msg_prompt   db "Enter guess: ", 0
    msg_err_len  db "Error: Number must be 4 digits (cannot start with 0). Try again.", 0
    msg_err_zero db "Error: Number cannot contain zero. Try again.", 0
    msg_err_rep  db "Error: Digits cannot repeat. Try again.", 0
    msg_win      db "Congratulations! You won! Exact match.", 0
    msg_lose     db "Game Over. You ran out of tries.", 0
    msg_hist     db "--- Game History ---", 0
    msg_sep      db " | ", 0

    ; === משתנים גלובליים ===               
    current_turn dq 0                ; מונה התור הנוכחי
    temp_guess   dq 0                ; משתנה זמני לקלט
    
    ; === מערכים ===                    
    ; מערכים קטנים לעבודה שוטפת (פירוק ספרות)
    secret_arr   db 0, 0, 0, 0       
    guess_arr    db 0, 0, 0, 0       

    ; מערכי היסטוריה (שמירת כל המהלכים)
    hist_guesses times 20 dq 0       
    hist_bulls   times 20 db 0       
    hist_cows    times 20 db 0       

    ; משתנים לתוצאת תור בודד
    curr_bulls   dq 0
    curr_cows    dq 0

section .text
global CMAIN      

CMAIN:
    mov rbp, rsp          ; יישור מחסנית 

    call init_game        ; הכנת המספר הסודי (פירוק למערך)
    call game_manager     ; הרצת המשחק עצמו
    
    xor rax, rax
    ret
; פונקציית אתחול              
; מפרקת את המספר הסודי למערך secret_arr פעם אחת בהתחלה
init_game:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi

    mov rax, [secret_num]
    mov rbx, divisors
    mov rdi, secret_arr
    mov rcx, 4
init_loop:
    xor rdx, rdx
    div qword [rbx]       ; חילוק במחלק הנוכחי
    mov [rdi], al         ; שמירה במערך הסוד
    mov rax, rdx          ; השארית ממשיכה הלאה
    add rbx, 8            ; מחלק הבא
    inc rdi               ; תא הבא
    loop init_loop       ; rcx-- ואם לא 0 קפוץ

    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret


; מנהל המשחק                   
; מנהל את התורים, קורא לקלט, בודק ניצחון/הפסד
game_manager:
    push rbx
    push rcx
    push rdx
    push rsi

    PRINT_STRING msg_start
    NEWLINE

game_loop:
    ; בדיקה: האם נגמרו התורים?
    mov rax, [current_turn]
    cmp rax, [n]
    je handle_lose

    ;שלב הקלט                     
    call get_valid_input
    
    ; שמירה בהיסטוריה (המספר השלם)
    mov rsi, [current_turn]
    mov rax, [temp_guess]
    mov [hist_guesses + rsi*8], rax

    ;חישוב תוצאות              
    call calc_results     ; מחשב בולים ופגיעות

    ; שמירת תוצאות להיסטוריה
    mov rsi, [current_turn]
    mov rax, [curr_bulls]
    mov [hist_bulls + rsi], al
    mov rax, [curr_cows]
    mov [hist_cows + rsi], al

    ; סיום תור
    inc qword [current_turn]

    ; בדיקת ניצחון (4 בולים)
    cmp qword [curr_bulls], 4
    je handle_win

    jmp game_loop        ; תור הבא

handle_win:
    PRINT_STRING msg_win
    NEWLINE
    call print_history
    jmp exit_manager

handle_lose:
    PRINT_STRING msg_lose
    NEWLINE
    call print_history

exit_manager:
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret
; קבלת קלט תקין          
; פונקציה זו לא חוזרת עד שהמשתמש מכניס מספר חוקי        
get_valid_input:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi

input_loop_start:
    PRINT_STRING msg_prompt
    GET_DEC 8, [temp_guess]
    NEWLINE
    ;טווח            
    ; המספר הכי קטן ללא אפס בהתחלה הוא 1000
    ; המספר הכי גדול הוא 9999
    mov rax, [temp_guess]
    cmp rax, 1000
    jl err_range
    cmp rax, 9999
    jg err_range
    ; פירוק למערך (כדי לבדוק אפסים וכפילויות)   
    mov rax, [temp_guess]
    mov rbx, divisors
    mov rdi, guess_arr
    mov rcx, 4

break_check_loop:
    xor rdx, rdx
    div qword [rbx]       ; rax=ספרה, rdx=שארית
    
    ;אפסים                
    cmp al, 0
    je err_zero          ; אם הספרה היא 0, שגיאה

    mov [rdi], al         ; שמירה למערך
    mov rax, rdx          ; הכנת השארית
    add rbx, 8
    inc rdi
    loop break_check_loop
    ; כפילויות           
    ; נשווה כל תא במערך לכל התאים שאחריו          
    mov rcx, 0            ; i = 0
outer_dup:
    mov rdx, rcx
    inc rdx               ; j = i + 1
inner_dup:
    cmp rdx, 4
    jge next_outer_dup
    
    mov al, [guess_arr + rcx]
    mov bl, [guess_arr + rdx]
    cmp al, bl
    je err_repeat        ;אם שווים - שגיאה

    inc rdx
    jmp inner_dup

next_outer_dup:
    inc rcx
    cmp rcx, 3
    jl outer_dup
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret                   ; חוזרים ל-Game Manager

; טיפול בשגיאות           
err_range:
    PRINT_STRING msg_err_len
    NEWLINE
    jmp input_loop_start ; מנסים שוב (לולאה פנימית)

err_zero:
    PRINT_STRING msg_err_zero
    NEWLINE
    jmp input_loop_start

err_repeat:
    PRINT_STRING msg_err_rep
    NEWLINE
    jmp input_loop_start

; חישוב תוצאות           
; משווה בין guess_arr ל-secret_arr
calc_results:
    push rax
    push rbx
    push rcx
    push rdx

    mov qword [curr_bulls], 0
    mov qword [curr_cows], 0

    ; חישוב בולים           
    mov rcx, 0
bulls_loop:
    mov al, [secret_arr + rcx]
    mov bl, [guess_arr + rcx]
    cmp al, bl
    jne no_bull
    inc qword [curr_bulls]
no_bull:
    inc rcx
    cmp rcx, 4
    jl bulls_loop

    ; חישוב פגיעות            
    mov rcx, 0            ; i (ניחוש)
cow_outer:
    mov rdx, 0            ; j (סוד)
cow_inner:
    cmp rcx, rdx          ; אם אותו מיקום
    je skip_cow          ; דלג (זה בול)

    mov al, [guess_arr + rcx]
    mov bl, [secret_arr + rdx]
    cmp al, bl
    jne skip_cow
    
    inc qword [curr_cows]
    jmp next_cow_outer   ; מצאנו פגיעה לספרה הזו, עבור לבאה

skip_cow:
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


; הדפסת היסטוריה                
print_history:
    push rax
    push rcx
    
    PRINT_STRING msg_hist
    NEWLINE
    
    mov rcx, 0
hist_loop:
    cmp rcx, [current_turn]
    jge hist_done

    ; הדפסת המספר              
    PRINT_DEC 8, [hist_guesses + rcx*8]
    PRINT_STRING msg_sep
    
    ; הדפסת בולים               
    xor rax, rax
    mov al, [hist_bulls + rcx]
    PRINT_DEC 1, al
    PRINT_STRING msg_sep
    
    ; הדפסת פגיעות                
    xor rax, rax
    mov al, [hist_cows + rcx]
    PRINT_DEC 1, al
    NEWLINE

    inc rcx
    jmp hist_loop

hist_done:
    pop rcx
    pop rax
    ret
End:             
   xor rax, rax
   PRINT_STRING 'Press any key to exit'
   GET_CHAR bl
   GET_CHAR bl
 
ret
