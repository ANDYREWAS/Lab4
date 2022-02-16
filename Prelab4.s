


//LAB4 - prelab4.s
    
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

	
PSECT	udata_bank0 ;memoria común
	cont:	DS  2
	
PSECT	udata_shr   ;memoria común
	W_TEMP:		DS	1
	STATUS_TEMP:	DS	1
    
PSECT	resVect,    class=code,abs,delta=2 ;Vector de reseteo
ORG 00h
resetVec:
    PAGESEL main
    goto    main
    
PSECT	intVect,    class=code,abs,delta=2  ;Vector de interrupción
ORG 04h
    
push:
    movwf   W_TEMP
    swapf   STATUS,w
    movwf   STATUS_TEMP
    
isr:
   btfsc    RBIF	;si la bandera está encendida 
   call	    int_iocb
    
pop:
    swapf   STATUS_TEMP,w
    movwf   STATUS
    swapf   W_TEMP,F
    swapf   W_TEMP,W
    
retfie
    
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
    
    
;_______CONFIGURACIONES_________
    
main:
    call config_io
    call config_reloj
    call config_iocb
    call config_int_enable
    
loop:
    
    goto loop
    
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
    
   return


config_reloj:
   banksel OSCCON
   bsf	    IRCF2	    
   bsf	    IRCF1
   bcf	    IRCF0
   bsf	    SCS		    ;reloj interno 4mhz
    
   return
    
    
config_int_enable:
    bsf	GIE
    bsf	RBIE
    bcf RBIF
    
    return