#include<p16f887.inc>
list p=16f887

;--- Cria��o de diretivas ---

	cblock 0x20 		; endere�o de mem�ria livre, registradores de uso geral
	led_cnt 			; led_cnt � igual a 0x20. Dando um nome, a um endere�o
	endc

;--- ----
	org		0x00 		; Vetor de reset
	goto		Start 	; Salto para endere�o de mem�ria de programa
	
	org 		0x04 		; Tratamento de interrup��o, vetor de interrup��o
	retfie			; Sai da interrup��o 
	
;--- ----
Start:

	;--- Configura��o de I/O (Entrada/Sa�da) ----
 	
 	;1111 0000 F0
 	bsf		STATUS,RP0		; Muda para o bank1 01
 	movlw		B'11110000'
 	movwf		TRISA			; TRISA = B'11110000'(RA0,RA1,RA2,RA3 como sa�da)
 	
 	bsf		STATUS,RP1		; Mudar para o bank3 11
 	clrf		ANCEL			; Configura os pinos da PORTA 
 						; como entrada digital
 	
;--- ----
Main:
	goto		Rotinainicializacao
	
	
Rotinainicializacao:
	
	bcf		STATUS,RP0		; Muda para o bank2 10
	bcf		STATUS,RP1		; Muda para o bank0 00
	movlw		0x0F			; W = B'0000 1111 '
	movwf		PORTA			; LEDs iniciam ligados		
	call		delay_1s		; Chama a fun��o de delay
	clrf		PORTA			; Limpa todos os pinos RA0-RA3	