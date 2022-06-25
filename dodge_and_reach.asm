.model tiny 
_text segment use16 

org 7C00h
pre_start:
	jmp start

;mingile proiectil ce se vor misca doar pe axa x 
ball_x db 0       
ball_y db 15        
ball_dx db 1

;avatarul/caracterul care trebuie sa atinga gate-ul
paddle_x db 75   
paddle_y db 20  
paddle_dx db 0          
paddle_dy db 0 

; dupa 3 ciclii jocul se termina, ecranul este eliberat (un ciclu inseamna atingerea peretelui din dreapta si inapoi)
timer_x db 1
; aici retin numarul de ciclii
time_limit db 0 

start: 
	; initializare
    mov ax, cs
    mov ds, ax

    ; ascund cursorul
    mov ch, 32
    mov ah, 1
    int 10h         ;  INT 10h / AH = 01h

    ;eliberez ecranul
    mov cx, 25
cls:
    mov ah, 0Eh
    mov al, 10
    int 10h         
    loop cls	

game:
    ; desenez gate-ul - punctul de final
	call gate_draw

	; desenez cele 2 proiectile
	call ball_draw 
    sub ball_y, 10 
    call ball_draw 

    ; desenez caracterul format din 4 stelute
	call paddle_draw
    add paddle_y, 1
    call paddle_draw
    sub paddle_y, 1

    ; desenez inceputul peretelui ce reprezinta si timer-ul
    call wall_draw
    add timer_x, 1

    ; apelez functia de verificare a coliziunii pentru ambele proiectile
    call check_collision
    add ball_y, 10
    call check_collision    

    call delay ;apelarea functiei de delay

    ; apelez functiile pentru stergerea caracterelor vechi de pe pozitile initiale odata ce sunt mutate in pozitii noi
    call ball_erase
    sub ball_y, 10
    call ball_erase
    add ball_y, 10	
	
    call paddle_erase
    add paddle_y, 1
    call paddle_erase
    sub paddle_y, 1	
	
	call wall_erase
	
    ; aici daca peretele ajunge la maximul din dreapta, isi da reset, iar timpul limita este incrementat
	.if (timer_x == 83)
        mov timer_x, 0
        inc time_limit
    .endif

    ; daca timpul limita este 3, jocul se sfarseste

    .if(time_limit == 3)
        jmp Ending
    .endif
	
    ;apelez functiile pentru mutarea caracterelor in noua pozitie
    call ball_move
	call paddle_move
	
    ; daca ajung la gate, jocul se sfarseste
	.if(paddle_x == 0) && (paddle_y == 0)
		jmp Ending
    .endif

	jmp game

; practic, daca coordonata avatarului si a mingii proiectil este aceeasi la un moment de timp, acestea s-au ciocnit
check_collision proc
    mov al, paddle_x
    mov bl, paddle_y
    .if (al == ball_x) && (bl == ball_y)   
        jmp Ending
    .endif

    add bl, 1
    .if (al == ball_x) && (bl == ball_y)
        jmp Ending
    .endif
    sub bl, 1
check_collision endp

; delay pentru fps
delay proc
    mov ah, 086h
    mov cx, 0
    mov dx, 25000
    int 15h         ;  INT 15h / AH = 86h - functia de asteptare a BIOS-ului. 
    ret
delay endp

; setez pozitia punctului de finish
gate_setpos proc
    mov dl, 0
    mov dh, 0
    mov bh, 0
    mov ah, 2
    int 10h
    ret
gate_setpos endp

; desenez punctul de finish la pozitia setata
gate_draw proc
    call gate_setpos
    mov ah, 0Ah
    mov al, 'G'
    mov cx, 1      
    int 10h      
    ret
gate_draw endp

;setez pozitia noua a mingii proiectil
ball_setpos proc
    mov dl, ball_x
    mov dh, ball_y
    mov bh, 0
    mov ah, 2
    int 10h        
    ret
ball_setpos endp

;desenez proiectilul la pozitia setata
ball_draw proc
    call ball_setpos
    mov ah, 0Ah
    mov al, 'O'
    mov cx, 1
    int 10h        
    ret
ball_draw endp

; setez pozitia caracterului
paddle_setpos proc
    mov dl, paddle_x
    mov dh, paddle_y
    mov bh, 0
    mov ah, 2
    int 10h
    ret
paddle_setpos endp

; desenez caracterul la pozitia setata
paddle_draw proc
    call paddle_setpos
    mov ah, 0Ah
    mov al, '*'
    mov cx, 2       
    int 10h         
    ret
paddle_draw endp

;practic peretele este timer-ul
wall_setpos proc
    mov dl, 0
    mov dh, 24
    mov bh, 0
    mov ah, 2
    int 10h
    ret
wall_setpos endp 

wall_draw proc  
    call wall_setpos    
    mov ah, 0Ah 
    mov al, '=' 
    mov bl, timer_x
    mov bh, 0
    mov cx, bx
    int 10h             
    ret 
wall_draw endp

;sterg pozitia anterioara a obstacolului
ball_erase proc
    call ball_setpos
    mov ah, 0Ah
    mov al, ' '
    mov cx, 1
    int 10h        
    ret
ball_erase endp

;calculez noua pozitie a obstacolului
ball_move proc
    mov al, ball_x
    mov bl, ball_dx
    add al, bl
    mov ball_x, al

    .if (al == 79) || (al == 0)
        neg ball_dx
    .endif 
    ret
ball_move endp

;sterg pozitia anterioara a caracterului
paddle_erase proc
    call paddle_setpos
    mov ah, 0Ah
    mov al, ' '
    mov cx, 2
    int 10h        
    ret
paddle_erase endp

;utilizand tastele 'wasd' mut caracaterul in pozitia nou calculata
paddle_move proc
    mov ah, 1
    int 16h         ;  INT 16h / AH = 01h - verific apasare de tasta in bufferul tastaturii.
    je no_key       ;  ZF = 1 daca n-a fost apasata tasta.
    
    mov ah, 0       ;  INT 16h / AH = 00h - preiau comanda de apasare a unei taste de la tastatura.
    int 16h         ;  (daca apare vreo apasare de tasta, aceasta este scoasa din bufferul tastaturii). 


    .if (al == 'a')
        mov paddle_dx, -1
        mov paddle_dy, 0
    .endif

    .if (al == 'd')
        mov paddle_dx, 1
        mov paddle_dy, 0
    .endif
    
    .if al == 'w'
        mov paddle_dx, 0
        mov paddle_dy, -1
    .endif
    
    .if (al == 's') 
        mov paddle_dx, 0
        mov paddle_dy, 1
    .endif
    
    mov al, paddle_x
    mov bl, paddle_dx
    add al, bl
    
    .if (al <= 80-2) &&  (al >= 0)
        mov paddle_x, al
    .endif
    
    mov al, paddle_y
    mov bl, paddle_dy
    add al, bl
    
    .if (al <= 23)
        mov paddle_y, al 
    .endif
no_key:              
    ret
paddle_move endp

wall_erase proc 
    call wall_setpos    
    mov ah, 0Ah 
    mov al, ' ' 
    mov bl, timer_x
    mov bh, 0
    mov cx, bx
    int 10h         
    ret 
wall_erase endp

Ending:
db 510-($-pre_start) dup(0) 
dw 0AA55h 

_text ends 
end 
