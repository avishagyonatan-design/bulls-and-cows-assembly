; avishag yonatan

%include "io64.inc"

section .data ;data segment

       ; נגדיר את ה"חוקים" - במה לחלק כל פעם
    ; dq אומר שכל מספר תופס 8 בייטים
    divisors dq 1000, 100, 10, 1
   
section .text ;code segment
global CMAIN
CMAIN:

    mov rbp, rsp; for correct debugging
    
    ; === קלט: קבלת מספר מהמשתמש ===                     
    ; הפקודה GET_DEC מקבלת מספר ושמה אותו ברגיסטר rax
    GET_DEC 8, rax   
    
    ; === הכנה ללולאה ===                         
    mov rbx, divisors  ; rbx יצביע על המערך (מתחיל ב-1000)
    mov rcx, 4         ; rcx הוא המונה של הלולאה (יש 4 מחלקים)

my_loop:
    ; איפוס שארית 
    xor rdx, rdx       
    
    ; חילוק      
    ; מחלקים את rax במספר ש-rbx מצביע עליו כרגע
    div qword[rbx]    
    ; התוצאה: rax = הספרה להדפסה, rdx = השארית בהמשך
    
    ; הדפסה
    PRINT_DEC 8, rax   ; מדפיס את הספרה
    PRINT_CHAR ' '     ; מדפיס רווח ליד הספרה
    
    ; הכנה לסיבוב הבא
    mov rax, rdx       ; מעבירים את השארית להיות המספר שנחלק בפעם הבאה
    add rbx, 8         ; מקדמים את המצביע למספר הבא במערך (מ-1000 ל-100 וכן הלאה)
    
    ;  ניהול הלולאה
    dec rcx            ; מורידים 1 מהמונה
    cmp rcx, 0         ; בודקים אם הגענו ל-0
    jne my_loop        ; אם לא 0, חוזרים להתחלה (my_loop)
    
    
End:             
   xor rax, rax
   NEWLINE
   PRINT_STRING 'Press any key to exit'
   GET_CHAR bl
   GET_CHAR bl
 
ret
