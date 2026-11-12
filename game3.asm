;avishag yonatan
;התוכנית מרחיבה את בדיקת הניחוש הבודד לכדי משחק שלם המתנהל בלולאה
;מהלך המשחק :למשתמש יש עד 10 ניסיונות לנחש את המספר הסודי 
;ניהול זיכרון:כל ניחוש מספר הבולים ומספר הפגיעות נשמרים במעריכים יעודיים בזיכון
;לוגיקה: בדיקת הספרות מתבצעת באמצעות ללאות יעילות 
;סיום: המשחק ניגמר בניצחון או בניצול כל הניסיונות ולאחר מכן מודפסת טבלה מלאה של כל מעריכי המשחק שבוצעו 

%include "io64.inc"

section .data ;data segment
  ;  הגדרות המשחק                  
    secret_num   dq 1234             ; המספר הסודי
    n            dq 10               ; מספר הניחושים המירבי
    divisors     dq 1000, 100, 10, 1 ; מחלקים לפירוק ספרות

    ; מערכים לשמירת היסטוריית המשחק                 
    ; נניח עד 20 ניחושים                 
    ; history_guesses שומר את המספרים השלמים (8 בייטים למספר)
    history_guesses times 20 dq 0    
    ; המערכים הבאים שומרים את כמות הבולים והפגיעות (בייט אחד לכל תור)    
    history_bulls   times 20 db 0    
    history_cows    times 20 db 0    

    ;משתני עזר                  
    current_turn dq 0               ; מונה התור הנוכחי (מתחיל ב-0)
    
    ; מערכים זמניים לפירוק הספרות                
    secret_arr   db 0, 0, 0, 0      
    guess_arr    db 0, 0, 0, 0      

    ; משתנים זמניים לחישוב               
    temp_guess   dq 0
    current_bulls dq 0
    current_cows  dq 0

    ;הודעות                  
    msg_start    db "Welcome! You have 10 tries.", 0
    msg_prompt   db "Enter guess: ", 0
    msg_win      db "You Won! Exact match.", 0
    msg_lose     db "Game Over. The number was: ", 0
    msg_history  db "Game History (Guess | Bulls | Cows):", 0
    msg_sep      db " | ", 0


   
section .text ;code segment
global CMAIN
CMAIN:

 mov rbp, rsp; for correct debugging

    PRINT_STRING msg_start
    NEWLINE

       ;  פירוק המספר הסודי למערך  secret_arr
   
    mov rax, [secret_num]       
    mov rbx, divisors           
    mov rdi, secret_arr         
    mov rcx, 4                  

init_secret_loop:
    xor rdx, rdx                
    div qword [rbx]             
    mov [rdi], al               
    mov rax, rdx                
    add rbx, 8                  
    inc rdi                     
    dec rcx
    cmp rcx, 0
    jne init_secret_loop

    ; לולאת המשחק הראשית         
game_loop:
    ;  בדיקה אם נגמרו הניסיונות        
    mov rax, [current_turn]
    cmp rax, [n]
    je game_over_lose           ; אם הגענו ל-n  הפסדנו

    ; קליטת הניחוש        
    PRINT_STRING msg_prompt
    GET_DEC 8, [temp_guess]
    NEWLINE

    ; שמירת הניחוש במערך ההיסטוריה        
    ; חישוב הכתובת: history_guesses + (current_turn * 8)
    mov rsi, [current_turn]
    mov rax, [temp_guess]
    mov [history_guesses + rsi*8], rax

       ; פירוק הניחוש הנוכחי למערך guess_arr
    
    mov rax, [temp_guess]       
    mov rbx, divisors           
    mov rdi, guess_arr          
    mov rcx, 4                  

break_guess_loop:
    xor rdx, rdx
    div qword [rbx]
    mov [rdi], al
    mov rax, rdx
    add rbx, 8
    inc rdi
    dec rcx
    cmp rcx, 0
    jne break_guess_loop

    ; חישוב בולים (Bulls)
    mov qword [current_bulls], 0
    mov rcx, 0                  ; אינדקס לולאה

check_bulls:
    mov al, [secret_arr + rcx]
    mov bl, [guess_arr + rcx]
    cmp al, bl
    jne not_bull_check
    inc qword [current_bulls]
not_bull_check:
    inc rcx
    cmp rcx, 4
    jl check_bulls

    ; חישוב פגיעות (Cows)     
    mov qword [current_cows], 0
    mov rcx, 0                  ; אינדקס חיצוני (על הניחוש)

outer_cow:
    mov rdx, 0                  ; אינדקס פנימי (על הסוד)
inner_cow:
    cmp rcx, rdx                ; אם המיקום זהה - דלג (זה בול)
    je cow_next_inner

    mov al, [guess_arr + rcx]
    mov bl, [secret_arr + rdx]
    cmp al, bl                  ; אם הספרות לא זהות - דלג
    jne cow_next_inner

    ; מצאנו פגיעה         
    inc qword [current_cows]
    jmp cow_next_outer          ; עוברים לספרה הבאה בניחוש

cow_next_inner:
    inc rdx
    cmp rdx, 4
    jl inner_cow

cow_next_outer:
    inc rcx
    cmp rcx, 4
    jl outer_cow

        ; סיום התור: שמירת התוצאות ובדיקת ניצחון
    
    ; שמירת בולים ופגיעות למערכי ההיסטוריה      
    mov rsi, [current_turn]     ; האינדקס הנוכחי
    mov rax, [current_bulls]
    mov [history_bulls + rsi], al
    mov rax, [current_cows]
    mov [history_cows + rsi], al

    ; קידום מונה התורים           
    inc qword [current_turn]

    ; בדיקת ניצחון: האם בולים == 4?     
    cmp qword [current_bulls], 4
    je game_over_win

    ; חזרה לתחילת הלולאה     
    jmp game_loop


       ; טיפול בסיום המשחק (ניצחון או הפסד)

game_over_win:
    PRINT_STRING msg_win
    NEWLINE
    jmp print_history_label

game_over_lose:
    PRINT_STRING msg_lose
    PRINT_DEC 8, [secret_num]
    NEWLINE
    jmp print_history_label

    ; הדפסת היסטוריית המשחק
    ; רצים מ-0 ועד current_turn ומדפיסים הכל        
print_history_label:
    NEWLINE
    PRINT_STRING msg_history
    NEWLINE
    
    mov rcx, 0                  ; אינדקס להדפסה (i)

history_print_loop:
    cmp rcx, [current_turn]     ; האם הגענו לסוף התורים ששוחק
    jge finish_program          ; אם כן, סיים

    ; הדפסת המספר שניחשו          
    PRINT_DEC 8, [history_guesses + rcx*8]
    
    PRINT_STRING msg_sep        ; מפריד " | "
    
    ; הדפסת הבולים           
    xor rax, rax
    mov al, [history_bulls + rcx]
    PRINT_DEC 1, al             ; הדפסת בולים
    
    PRINT_STRING msg_sep        ; מפריד " | "
    
    ; הדפסת הפגיעות         
    xor rax, rax
    mov al, [history_cows + rcx]
    PRINT_DEC 1, al             ; הדפסת פגיעות
    
    NEWLINE

    inc rcx                     ; i++
    jmp history_print_loop

finish_program:
End:             
   xor rax, rax
   PRINT_STRING 'Press any key to exit'
   GET_CHAR bl
   GET_CHAR bl
 
ret
