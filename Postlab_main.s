; Archivo:	PostLab4.s
; Dispositivo:	PIC16F887
; Autor:	Andres Najera
; Compilador:	pic-as (v2.35), MPLABX V6.00
;                
; Programa:	TMR0 y contador en PORTA con push buttons
; Hardware:	LEDs		
;
; Creado:	18 feb 2022

// PIC16F887 Configuration Bit Settings

// 
    
// 'C' source line config statements
PROCESSOR 16F887
#include <xc.inc>
// CONFIG1
CONFIG FOSC=INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
CONFIG WDTE=OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
CONFIG PWRTE=ON       // Power-up Timer Enable bit (PWRT enabled)
CONFIG MCLRE=OFF      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
CONFIG CP=OFF         // Code Protection bit (Program memory code protection is disabled)
CONFIG CPD=OFF        // Data Code Protection bit (Data memory code protection is disabled)

CONFIG BOREN=OFF      // Brown Out Reset Selection bits (BOR disabled)
CONFIG IESO=OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
CONFIG FCMEN=OFF      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
CONFIG LVP=ON         // Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

// CONFIG2

CONFIG WRT=OFF        // Flash Program Memory Self Write Enable bits (Write protection off)
CONFIG BOR4V=BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
    
// #pragma config statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.

	
UP	EQU	0 ;bit 0
DOWN	EQU	7 ;bit 7

RESET_TMR0 MACRO TMR_VAR
   BANKSEL TMR0	    ; cambiamos de banco
   MOVLW   TMR_VAR
   MOVWF   TMR0	    ; configuramos tiempo de retardo
   BCF	    T0IF	    ; limpiamos bandera de interrupción
   ENDM
	
PSECT	udata_bank0 ;memoria común
	cont:		DS 2
	valor:		DS 1
	contd:		DS 2
	
    	
PSECT	udata_shr   ;memoria común
	W_TEMP:		DS	1
	STATUS_TEMP:	DS	1
    
    
PSECT	resVect,    class =CODE, abs ,delta=2 ;Vector de reseteo
ORG 00h
resetVec:
    PAGESEL main
    goto    main
    
PSECT	intVect,    class =CODE, abs, delta=2  ;Vector de interrupción
ORG 04h
    
push:
    movwf   W_TEMP
    swapf   STATUS,w
    movwf   STATUS_TEMP
    
isr:
   banksel  PORTA
   btfsc    RBIF	;si la bandera está encendida 
   call	    int_iocb
   
   btfsc    T0IF
   call	    int_t0 
pop:
    swapf   STATUS_TEMP,w
    movwf   STATUS
    swapf   W_TEMP,F
    swapf   W_TEMP,W
    
retfie

int_t0:
    
    RESET_TMR0 216	    ; Reiniciamos TMR0 para 10ms
    INCF    cont
    
    movlw   10		    
    subwf   PORTC, W	    ;Revisamos si ya llegamos a los diez segundos
    btfsc   STATUS, 2	    
    clrf    PORTC	    ;Si llegamos a diez limpiamos el contador de segundos
    
    return
    
    
    
int_iocb:
    BANKSEL PORTA
    btfss   PORTB,  UP
    incf    PORTA
    btfsc   PORTA,  4
    clrf    PORTA
    
    btfss   PORTB,  DOWN
    decf    PORTA
    bcf	    RBIF
    
    
    return
    
PSECT	mainVect,    class =CODE, abs, delta=2  ;Vector de interrupción
ORG 100h
    
;_______CONFIGURACIONES_________
    
main:
    call config_io
    call config_reloj
    call config_iocb
    call config_tmr0
    call config_int_enable
    call cont1s
    clrf PORTD
    banksel PORTA
    
loop:
    call cont1s
    call cont_decs
    call clr_contdecs
    goto loop

cont1s:
    
    movlw   100
    subwf   cont, W
    btfss   STATUS, 2
    return
    incf    PORTC
    incf    contd   ;cada segundo que cuente, tambien lo guardamos en esta variable para poder saber cuando llegue a diez
    clrf    cont

return
    
clr_contdecs:
    movlw   6
    subwf   PORTD, W  ;Cuando el portd llegue a 6 significa que han pasado 6 ciclos del tmr de segundos, que se reinicia cada 10 segundos, es decir que han pasado 60 segundos y se reinicia
    btfss   STATUS, 2 ;encendió la bandera Z?
    return
    clrf    PORTD
    
cont_decs:
    movlw   10
    subwf   contd, W
    btfss   STATUS, 2
    return
    incf    PORTD
    clrf    contd
    
    
    
config_iocb:
    banksel TRISA
    bsf	    IOCB, UP
    bsf	    IOCB, DOWN
    
    banksel PORTA
    movf    PORTB,W ; mismatch
    bcf	    RBIF    
    
    return
    

config_io:
   bsf	STATUS, 5
   bsf	STATUS,	6   ;Banco 11 - 3
   clrf ANSEL
   clrf	ANSELH
   
   bsf	STATUS,	5
   bcf	STATUS,	6   ;banco 01 - 1
   clrf	TRISA	    ;Puerto A para salidas
   bsf	TRISB,	UP
   bsf	TRISB,	DOWN	;bits 0 y 7 del puerto B como entradas
   
   bcf	OPTION_REG,7 ;habilita las resistencias pullups
   bsf	WPUB,	UP
   bsf	WPUB,	DOWN
   
   bcf	STATUS, 5
   bcf	STATUS, 6
   clrf	PORTA
   
   ;tmr0
   clrf    PORTC
   BANKSEL TRISC
   CLRF    TRISC	    ; PORTC como salida
   
  ;tmr decs
   clrf    PORTD
   BANKSEL TRISD
   CLRF    TRISD	    ; PORTD como salida
   return


config_reloj:
   banksel OSCCON
   bsf	    IRCF2	    
   bsf	    IRCF1
   bcf	    IRCF0
   bsf	    SCS		    ;reloj interno 4mhz
    
   return
    
    
config_int_enable:
    BANKSEL INTCON
    bsf	GIE
    bsf	RBIE
    bcf RBIF
    
    ;tmr0
    BSF	    T0IE	    ; Habilitamos interrupcion TMR0
    BCF	    T0IF
    
    return
    
config_tmr0:
    BANKSEL OPTION_REG	    ; cambiamos de banco
    BCF	    T0CS	    ; TMR0 como temporizador
    BCF	    PSA		    ; prescaler a TMR0
    BSF	    PS2
    BSF	    PS1
    BSF	    PS0		    ; PS<2:0> -> 111 prescaler 1 : 256
    
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   216
    MOVWF   TMR0	    ; 10ms retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    RETURN 




