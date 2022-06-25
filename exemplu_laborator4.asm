.model tiny 
_text segment use16 

org 7C00h
 
start: 
	mov ax, cs ; ma asigur ca DS = CS 
	mov ds, ax 
 
	mov bx, 0 ; bx este indicele caracterului curent 
	mov ah, 0Eh ; INT 10h / AH = 0Eh - teletype output. 
print_loop: 
	mov al, msg[bx] ; incarca un caracter 
	cmp al, 0 ; gata? 
	je halt 
	int 10h ; afișează caracterul 
	inc bx ; următorul 
	jmp print_loop ; rinse and repeat 
halt: 
	cli 
	hlt ; gata! de aici încolo sunt date 
	
msg db "Salut vere!", 0 
db 510-($-start) dup(0) 
dw 0AA55h 

_text ends 
end 