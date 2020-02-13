#include <p16f887.inc>
#define button PORTB, RB0
list p=16f887
__CONFIG _CONFIG1, 0x2FF4
__CONFIG _CONFIG2, 0x3FFF



	cblock 0x20
		led_cnt
		cnt_1
		cnt_2
		_wreg
		_status
		timer_counter_5s
		timer_counter_50ms
		level ; level:
			; 0 = Dificil
			; 1 = Facil
		sequency
		move
		last_move
		last_input
		timeout	;
			;
		current_move
		
	endc
	
	HARD_TIMEOUT	EQU	.3
	EASY_TIMEOUT	EQU	.5
	MOVE_BASE_ADDR EQU 	0x05F
	TMR0_50MS	EQU	.61		; Constante Literal
	LED_RED	EQU	B'00000001'
	LED_YELLOW	EQU	B'00000010'
	LED_GREEN	EQU	B'00000100'
	LED_BLUE	EQU	B'00001000'
	
	
	org	0x00		; Vetor de reset
	goto 	Start
	
	org	0x04		;Vetor de interrupção
	movwf	_wreg
	swapf	STATUS, W
	movwf	_status
	clrf	STATUS
	btfsc	INTCON, T0IF		; T0IF == 1 ?
	goto	Timer0Interrupt	; Yes	
	goto	ExitInterrupt	; No
	

Timer0Interrupt:
	
	bcf	INTCON, T0IF
	incf	timer_counter_5s, F
	incf	timer_counter_50ms, F
	movlw	TMR0_50MS
	movwf	TMR0			; Reseta contador TMR0
	goto	ExitInterrupt

ExitInterrupt:
	swapf	_status, W
	movwf	STATUS
	swapf	_wreg, F
	swapf	_wreg, W	
	retfie
	
Start:	
	;----- TESTE ------
	movlw	.2
	sublw	.1
	
	
	
	
	;----- I/O config ------
	clrf	timer_counter_5s
	clrf	timer_counter_50ms
	bsf 	STATUS, RP0	; change to bank1
	movlw	 B'11110000'
	movwf 	TRISA		; config RA0-R3 as ouput
				; and RA4-RA7 as input
	bcf	TRISB, TRISB0		
	bcf	TRISB, TRISB1	
	bsf 	STATUS, RP1	; change to bank3
	clrf	ANSEL		; configure all PORTA,
				; pins as digital I/O
	clrf	ANSELH						
	;----- TMR0 configuração ------
	;INTCON; TMR0; OPTION_REG
	;OPTIN_REG: 
	;T0CS= 0(INTOSC/4)
	;PSA= 0 (Prescaler TMR0) 
	;PS=111
	bcf	STATUS,RP1		; Muda para o BANK01
	;--- MASCARA PARA SETAR ---
	movlw	B'00000111'
	iorwf	OPTION_REG, F		; Setado o PSA<2:0>
	;--- MASCARA PARA RESETAR ---
	movlw	B'11010111'	
	andwf	OPTION_REG, F		; Limpa T0CS, PSA
	bcf	STATUS,RP0		; Muda para o BANK00
	movlw 	.61
	movwf	TMR0
	bcf	INTCON, T0IF		; Limpa a flag de interrupção
	bsf	INTCON, T0IE		; Habilita o TMR0 enterrupção
	bsf	INTCON, GIE		; Habilita interrupção
	call	RotinaInicializacao
	movlw	MOVE_BASE_ADDR
	movwf	FSR
	bcf	STATUS, IRP
	clrf	last_move
		
Main:
	
	btfsc	button		; Botão Start foi pressionado ?
	goto	Main
	

	movf	TMR0, W
	movwf	move			; Copia TMR0 para move
	clrf	sequency		; Sequência = 0
	btfsc	PORTB,RB1		; Seletor de nível
	goto 	LevelEasy
	goto 	LevelHard

LevelEasy:
	bcf	level, 0
	goto	Main_Loop	
LevelHard:
	bsf	level, 0
	goto	Main_Loop

Main_Loop:
	call	SorteiaNumero
	call	StoreNumber
	goto	Main		
; ----
;Recebe move
SorteiaNumero:

	movlw	0x03
	andwf	move	; Limpa bits <7:2>
	
	movlw	.0
	subwf	move, W
	btfsc	STATUS, Z
	retlw	LED_RED
	
	movlw 	.1
	subwf	move, W
	btfsc	STATUS, Z
	retlw	LED_YELLOW
	
	movlw 	.2
	subwf	move, W
	btfsc	STATUS, Z
	retlw	LED_GREEN
	
	movlw 	.3
	subwf	move, W
	btfsc	STATUS, Z
	retlw	LED_BLUE
	
	
StoreNumber:

	movwf	INDF
	incf	FSR, F
	incf	last_move, F
	return

EntradaMovimento:

	bcf 	STATUS, RP1
	bcf	STATUS, RP0	; Muda para o Banco 0
	clrf	last_input
	movlw	MOVE_BASE_ADDR
	movwf	FSR 
	
InputLoop:
	
	movf	PORTD, W
	andlw	0x0F	; Limpa do RD<7:4>
	sublw	0x00
	btfsc	STATUS, Z	; Testa entradas
	goto	ButtonNotPressed
	goto	ButttonPressed
			
			
ButtonNotPressed:
	
	
	;btfss	timeout	; ocorreu timeout ?
	goto	InputLoop	; Não
	return
	
ButttonPressed:

	movwf	current_move
	call 	CompareInput
	sublw	.0
	btfsc	STATUS, Z	; Botão correto pressionado ?
	return		; Não
	incf	last_input, F	; Sim
	incf	FSR, F
	movf	last_input, W
	subwf	last_move, W
	btfsc	STATUS, C	; last_input > last_move?
	return
	goto	InputLoop
	

	
CompareInput:
	

	movf	current_move
	subwf	INDF
	btfss	STATUS, Z
	retlw	.0
	retlw	current_move

		

RotinaInicializacao:

	bcf 	STATUS, RP1
	bcf 	STATUS, RP0 	; change to bank0
	movlw 	0x0F			
	movwf 	PORTA		; set pins RA0-RA3
	call	Delay_1s		; call delay function			
	clrf 	led_cnt		; led_cnt = 0
	
LedCountLoop:
	clrf	PORTA		; clear pins RA0-RA3
	
	movlw 	.0
	subwf	led_cnt, W
	btfsc	STATUS, Z	; led_cnt=0?
	bsf 	PORTA, RA0	; yes
	
	
	movlw 	.1
	subwf 	led_cnt, W
	btfsc	STATUS, Z	; led_cnt=1?
	bsf 	PORTA, RA1	; yes
	
					
	movlw 	.2
	subwf 	led_cnt, W
	btfsc	STATUS, Z	; led_cnt=1?
	bsf 	PORTA, RA2	; yes
	
	
	movlw 	.3
	subwf 	led_cnt, W
	btfsc	STATUS, Z	; led_cnt=1?
	bsf 	PORTA, RA3	; yes
	
	
	call 	Delay_200ms								
	incf	led_cnt, F 	; incrementa led_cnt
	
	
	movlw	.4
	subwf	led_cnt, W	
	btfss 	STATUS, Z 	; led_cnt=4?
	goto	LedCountLoop		; no
	clrf	PORTA		; yes
	return
	
Delay_1s:
	call	Delay_200ms
	call	Delay_200ms
	call	Delay_200ms
	call	Delay_200ms
	call	Delay_200ms
	return
	
Delay_1ms:
	movlw	.248
	movwf	cnt_1
Delay1:
	nop
	decfsz	cnt_1, F	;decrement cnt_1
	goto 	Delay1
	return				; cnt equals 0

Delay_200ms:
	movlw 	.200
	movwf	cnt_2
Delay2:
	call	Delay_1ms
	decfsz	cnt_2, F
	goto	Delay2	
	return
	
	end
	
