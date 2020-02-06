#include<p16f887.inc>
list p=16f887

;--- Criação de diretivas ---

	cblock 0x20 		; endereço de memória livre, registradores de uso geral
	led_cnt 			; led_cnt é igual a 0x20. Dando um nome, a um endereço
	endc

;--- ----
	org		0x00 		; Vetor de reset
	goto		Start 	; Salto para endereço de memória de programa
	
	org 		0x04 		; Tratamento de interrupção, vetor de interrupção
	retfie			; Sai da interrupção 
	
;--- ----
Start:

	;--- Configuração de I/O (Entrada/Saída) ----
 	
 	;1111 0000 F0
 	bsf		STATUS,RP0		; Muda para o bank1 01
 	movlw		B'11110000'
 	movwf		TRISA			; TRISA = B'11110000'(RA0,RA1,RA2,RA3 como saída)
 	
 	bsf		STATUS,RP1		; Mudar para o bank3 11
 	clrf		ANCEL			; Configura os pinos da PORTA 
 						; como entrada digital
 	
;--- ----
Main:
	call		Rotinainicializacao
	
;--- ----	
Rotinainicializacao:
	
	bcf		STATUS,RP0		; Muda para o bank2 10
	bcf		STATUS,RP1		; Muda para o bank0 00
	movlw		0x0F			; W = B'0000 1111 '
	movwf		PORTA			; LEDs iniciam ligados		
	call		delay_1s		; Chama a função de delay
	clrf		led_cnt		; led_cnt == 0


;--- ----
LedContLoop:

	clrf		PORTA			; Limpa todos os pinos RA0-RA3
	movlw		.0
	subwf		led_cnt, W		
	btfsc		STATUS, Z		; led_cnt =0 ?
	bsf		PORTA, RA0		; Sim, led_cnt ==0 ; Acende LED0-RA0
	
	movlw		.1
	subwf		led_cnt, W		
	btfsc		STATUS, Z		; led_cnt =1 ?
	bsf		PORTA, RA1		; Sim, led_cnt ==1 ; Acende LED2-RA1
	
	movlw		.2
	subwf		led_cnt, W		
	btfsc		STATUS, Z		; led_cnt =2 ?
	bsf		PORTA, RA2		; Sim, led_cnt ==2 ; Acende LED2-RA2
	
	movlw		.3
	subwf		led_cnt, W		
	btfsc		STATUS, Z		; led_cnt =3 ?
	bsf		PORTA, RA3		; Sim, led_cnt ==3 ; Acende LED3-RA3
	
	call		Delay_200ms
	incf		led_cnt, F		; Incrementa led_cnt
	
	movlw		.4
	subwf		led_cnt, W		
	btfss		STATUS, Z		; led_cnt = 4 ?
	goto		LedContLoop:	; Não, volta ao inicio da rotina
	clrf		PORTA			; Sim, apaga todos os LEDs
	return
	
	
Delay	