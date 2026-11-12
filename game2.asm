
;-----------------------------------------------------------------------------
; avishag yonatan 
; 21.12.25
;איתחלתי מספר שאני רוצה פירקתי אותו ל4 ספרות באמצעות חילוק לאחר מכן ביקשתי 
;מהמשתמש להכניס מספרומתבצעת בדיקה אם הניחוש נכון ב100 אחוז התוכנית מסתיימת 
;ואם לא התוכנית ממשיכה התכנית מפרקת את המספר ל4 ספרות בודדות 
;וכן עשיתי לולאה על חישוב הבולים ולולאה כפולה על חישוב הפגיעות 
;---------------------------------------------------------------------------------------------

%include "io64.inc"

section .data ;data segment

    secret_num   dq 1234            ; המספר הסודי
    divisors     dq 1000, 100, 10, 1  ; המחלקים

    ; משתנים (מאותחלים ל-0)                
    guess_num    dq 0               ; המספר שנקלוט
    
    ; מערכים לשמירת הספרות (4 תאים לכל אחד)                
    secret_arr   db 0, 0, 0, 0      
    guess_arr    db 0, 0, 0, 0      

    ; מונים                  
    bulls         dq 0
    pgiot         dq 0

   
section .text ;code segment
global CMAIN
CMAIN:


    mov rbp, rsp; for correct debugging

    ; פירוק המספר הסודי                
    mov rax, [secret_num]       ; המספר שרוצים לפרק
    mov rbx, divisors           ; מצביע למחלקים
    mov rdi, secret_arr         ; מצביע למערך התוצאה
    mov rcx, 4                  ; מונה ל-4 ספרות

loop_secret:
    xor rdx, rdx                ; איפוס שארית
    div qword [rbx]             ; חילוק: rax=ספרה, rdx=שארית
    mov [rdi], al               ; שמירת הספרה במערך
    mov rax, rdx                ; השארית עוברת לסיבוב הבא
    add rbx, 8                  ; מחלק הבא
    inc rdi                     ; תא הבא במערך
    dec rcx
    cmp rcx, 0
    jne loop_secret

    ; קליטת הניחוש ובדיקת ניצחון מיידי                  
    PRINT_STRING "Enter guess: "
    GET_DEC 8, [guess_num]
    NEWLINE

    mov rax, [guess_num]
    cmp rax, [secret_num]
    je you_won                  ; אם המספרים זהים בדיוק - ניצחת

    
    ; פירוק הניחוש למערך guess_arr                
    mov rax, [guess_num]        ; המספר שנקלט
    mov rbx, divisors           ; איפוס מצביע למחלקים
    mov rdi, guess_arr          ; איפוס מצביע למערך הניחוש
    mov rcx, 4                  ; איפוס מונה

loop_guess:
    xor rdx, rdx
    div qword [rbx]
    mov [rdi], al
    mov rax, rdx
    add rbx, 8
    inc rdi
    dec rcx
    cmp rcx, 0
    jne loop_guess

   
    ; חישוב בולים                
    mov rcx, 0                  ; אינדקס (0 עד 3)
    mov qword [bulls], 0        ; איפוס מונה בולים

check_bulls:
    mov al, [secret_arr + rcx]  ; ספרה מהסוד
    mov bl, [guess_arr + rcx]   ; ספרה מהניחוש
    cmp al, bl
    jne not_a_bull              ; אם שונה - דלג
    inc qword [bulls]           ; אם זהה - בול

not_a_bull:
    inc rcx
    cmp rcx, 4
    jl check_bulls

   
    ; חישוב פגיעות                      
    mov rcx, 0                  ; אינדקס הניחוש (i)
    mov qword [pgiot], 0         ; איפוס מונה פגיעות

outer_loop:
    mov rdx, 0                  ; אינדקס הסוד (j)

inner_loop:
    cmp rcx, rdx                ; בדיקה: האם זה אותו מיקום?
    je next_j                   ; אם כן, דלג (כי זה בול, לא פגיעה)

    mov al, [guess_arr + rcx]   ; קח ספרה מהניחוש
    mov bl, [secret_arr + rdx]  ; קח ספרה מהסוד
    cmp al, bl                  ; האם הן שוות?
    jne next_j                  ; אם לא, תמשיך לחפש

    ; מצאנו פגיעה                        
    inc qword [pgiot]
    jmp next_i                  ; מפסיקים לחפש את הספרה הזו (עוברים לבאה)

next_j:
    inc rdx
    cmp rdx, 4
    jl inner_loop               ; סוף לולאה פנימית

next_i:
    inc rcx
    cmp rcx, 4
    jl outer_loop               ; סוף לולאה חיצונית

        ; הדפסת התוצאות וסיום                   
    PRINT_STRING "Bulls: "
    PRINT_DEC 8, [bulls]
    PRINT_STRING ", pgiot: "
    PRINT_DEC 8, [pgiot]
    NEWLINE
    jmp End

you_won:
    PRINT_STRING "You won! Exact match."
    NEWLINE



End:             
   xor rax, rax
   PRINT_STRING 'Press any key to exit'
   GET_CHAR bl
   GET_CHAR bl
 
ret
