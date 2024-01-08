;
; a3part-A.asm
;
; Part A of assignment #3
;
;
; Student name:
; Student ID:
; Date of completed work:
;
; **********************************
; Code provided for Assignment #3
;
; Author: Mike Zastre (2022-Nov-05)
;
; This skeleton of an assembly-language program is provided to help you 
; begin with the programming tasks for A#3. As with A#2 and A#1, there are
; "DO NOT TOUCH" sections. You are *not* to modify the lines within these
; sections. The only exceptions are for specific changes announced on
; Brightspace or in written permission from the course instruction.
; *** Unapproved changes could result in incorrect code execution
; during assignment evaluation, along with an assignment grade of zero. ***
;


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================
;
; In this "DO NOT TOUCH" section are:
; 
; (1) assembler direction setting up the interrupt-vector table
;
; (2) "includes" for the LCD display
;
; (3) some definitions of constants that may be used later in
;     the program
;
; (4) code for initial setup of the Analog-to-Digital Converter
;     (in the same manner in which it was set up for Lab #4)
;
; (5) Code for setting up three timers (timers 1, 3, and 4).
;
; After all this initial code, your own solutions's code may start
;

.cseg
.org 0
	jmp reset

; Actual .org details for this an other interrupt vectors can be
; obtained from main ATmega2560 data sheet
;
.org 0x22
	jmp timer1

; This included for completeness. Because timer3 is used to
; drive updates of the LCD display, and because LCD routines
; *cannot* be called from within an interrupt handler, we
; will need to use a polling loop for timer3.
;
; .org 0x40
;	jmp timer3

.org 0x54
	jmp timer4

.include "m2560def.inc"
.include "lcd.asm"

.cseg
#define CLOCK 16.0e6
#define DELAY1 0.01
#define DELAY3 0.1
#define DELAY4 0.5

#define BUTTON_RIGHT_MASK 0b00000001	
#define BUTTON_UP_MASK    0b00000010
#define BUTTON_DOWN_MASK  0b00000100
#define BUTTON_LEFT_MASK  0b00001000

#define BUTTON_RIGHT_ADC  0x032
#define BUTTON_UP_ADC     0x0b0   ; was 0x0c3
#define BUTTON_DOWN_ADC   0x160   ; was 0x17c
#define BUTTON_LEFT_ADC   0x22b
#define BUTTON_SELECT_ADC 0x316

.equ PRESCALE_DIV=1024   ; w.r.t. clock, CS[2:0] = 0b101

; TIMER1 is a 16-bit timer. If the Output Compare value is
; larger than what can be stored in 16 bits, then either
; the PRESCALE needs to be larger, or the DELAY has to be
; shorter, or both.
.equ TOP1=int(0.5+(CLOCK/PRESCALE_DIV*DELAY1))
.if TOP1>65535
.error "TOP1 is out of range"
.endif

; TIMER3 is a 16-bit timer. If the Output Compare value is
; larger than what can be stored in 16 bits, then either
; the PRESCALE needs to be larger, or the DELAY has to be
; shorter, or both.
.equ TOP3=int(0.5+(CLOCK/PRESCALE_DIV*DELAY3))
.if TOP3>65535
.error "TOP3 is out of range"
.endif

; TIMER4 is a 16-bit timer. If the Output Compare value is
; larger than what can be stored in 16 bits, then either
; the PRESCALE needs to be larger, or the DELAY has to be
; shorter, or both.
.equ TOP4=int(0.5+(CLOCK/PRESCALE_DIV*DELAY4))
.if TOP4>65535
.error "TOP4 is out of range"
.endif

reset:
; ***************************************************
; **** BEGINNING OF FIRST "STUDENT CODE" SECTION ****
; ***************************************************

; Anything that needs initialization before interrupts
; start must be placed here.
	ldi temp, low(RAMEND)					; initialize stack pointer
	out SPL, temp

	ldi temp, high(RAMEND)
	out SPH, temp
	rcall lcd_init							; initialize lcd screen

	; Initialize display data with default values
	clr temp
	sts CURRENT_CHAR_INDEX, temp			; initialize current char index to 0
	
	ldi temp, ' '							; initialize top line content with spaces
	ldi ZH, high(TOP_LINE_CONTENT << 1)		; load the address of top line content	
	ldi ZL, low(TOP_LINE_CONTENT << 1)
	ldi r17, 16
	init_top_line_content:
		st Z+, temp
		dec r17
		brne init_top_line_content
											; initialize current charset index with 0's
	clr temp
	ldi ZH, high(CURRENT_CHARSET_INDEX << 1)			
	ldi ZL, low(CURRENT_CHARSET_INDEX << 1)
	ldi r17, 16
	init_current_charset_index:
		st Z+, temp
		dec r17
		brne init_current_charset_index
		
											

; ***************************************************
; ******* END OF FIRST "STUDENT CODE" SECTION *******
; ***************************************************

; =============================================
; ====  START OF "DO NOT TOUCH" SECTION    ====
; =============================================

	; initialize the ADC converter (which is needed
	; to read buttons on shield). Note that we'll
	; use the interrupt handler for timer 1 to
	; read the buttons (i.e., every 10 ms)
	
	ldi temp, (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
	sts ADCSRA, temp
	ldi temp, (1 << REFS0)
	sts ADMUX, temp

	; Timer 1 is for sampling the buttons at 10 ms intervals.
	; We will use an interrupt handler for this timer.
	ldi r17, high(TOP1)
	ldi r16, low(TOP1)
	sts OCR1AH, r17
	sts OCR1AL, r16
	clr r16
	sts TCCR1A, r16
	ldi r16, (1 << WGM12) | (1 << CS12) | (1 << CS10)
	sts TCCR1B, r16
	ldi r16, (1 << OCIE1A)
	sts TIMSK1, r16

	; Timer 3 is for updating the LCD display. We are
	; *not* able to call LCD routines from within an 
	; interrupt handler, so this timer must be used
	; in a polling loop.
	ldi r17, high(TOP3)
	ldi r16, low(TOP3)
	sts OCR3AH, r17
	sts OCR3AL, r16
	clr r16
	sts TCCR3A, r16
	ldi r16, (1 << WGM32) | (1 << CS32) | (1 << CS30)
	sts TCCR3B, r16
	; Notice that the code for enabling the Timer 3
	; interrupt is missing at this point.

	; Timer 4 is for updating the contents to be displayed
	; on the top line of the LCD.
	ldi r17, high(TOP4)
	ldi r16, low(TOP4)
	sts OCR4AH, r17
	sts OCR4AL, r16
	clr r16
	sts TCCR4A, r16
	ldi r16, (1 << WGM42) | (1 << CS42) | (1 << CS40)
	sts TCCR4B, r16
	ldi r16, (1 << OCIE4A)
	sts TIMSK4, r16

	sei

; =============================================
; ====    END OF "DO NOT TOUCH" SECTION    ====
; =============================================

; ****************************************************
; **** BEGINNING OF SECOND "STUDENT CODE" SECTION ****
; ****************************************************

start:
	rjmp check_timer3

check_timer3:
	in r16, TIFR3					; Load TIFR3 into a register
	sbrs r16, OCF3A					; Check is OCF3A is set
	rjmp start						; Otherwise, loop back to start
	call update_lcd				    ; Jump to update LCD if OCF3A is set
	
	ldi r17, (1 << OCF3A)			; Clear the OCF3A flag by writing a logic 1 to it
	out TIFR3, r17					
	rjmp start						; Return to main loop

update_lcd:
	lds temp, BUTTON_IS_PRESSED		; Load in value for BUTTON_IS_PRESSED
	cpi temp, 0						; If value is 0 then the button is not pressed
	breq unset_char					

	ldi temp, 0x2A					; Load in ascii value of '*'
	rjmp display_char				; Button is pressed, so display the char

; Subroutine for updating the LCD at a specific position
; Inputs: r18 - row, r19 - column, r20 - character to display
update_lcd_at_position:
	push r18						; Save row on stack
	push r19						; Save column on stack
	rcall lcd_gotoxy				; Set cursor position
	pop r19							; Restore column from stack
	pop r18							; Restore row from stack

	push temp						; Push character onto stack
	rcall lcd_putchar				; Display character
	pop temp 						; Pop character from stack
	ret
	
unset_char:							; Displays '-' char to show button not pressed
	ldi temp, 0x2D
	ldi r18, 1						; Load the row for lcd_gotoxy
	ldi r19, 15						; Load the final column for lcd_gotoxy
	rcall update_lcd_at_position	; Updates the char on the lcd at the desired position
	rjmp return_to_timer3_call

display_char:		
	ldi r18, 1						; Load the row for lcd_gotoxy
	ldi r19, 15						; Load the final column for lcd_gotoxy
	rcall update_lcd_at_position	; Updates the char on the lcd at the desired position

	lds r16, LAST_BUTTON_PRESSED	; Load in the high and low bytes of the value of the last button pressed
	lds r17, LAST_BUTTON_PRESSED + 1

	mov r20, r16					; Make a copy of ADC value for manipulation
	mov r21, r17

	ldi r18, low(BUTTON_RIGHT_ADC)	; Load in the value of the right button ADC 
	ldi r19, high(BUTTON_RIGHT_ADC)

	; Series of comparisons with button ADC values to determine which was pressed
	cp r20, r18						; Compare with right ADC
	cpc r21, r19
	
	brlo display_right				; Display right 
	breq display_right

	mov r20, r16					; Make a copy of ADC value for manipulation
	mov r21, r17

	ldi r18, low(BUTTON_UP_ADC)		; Load in the value of the up button ADC 
	ldi r19, high(BUTTON_UP_ADC)

	cp r20, r18						; Compare with left ADC
	cpc r21, r19

	brlo display_up					; Display up
	breq display_up
		
	mov r20, r16					; Make a copy of ADC value for manipulation
	mov r21, r17
	   
	ldi r18, low(BUTTON_DOWN_ADC)	; Load in the value of the down button ADC 
	ldi r19, high(BUTTON_DOWN_ADC)

	cp r20, r18						; Compare with down ADC
	cpc r21, r19

	brlo display_down				; display down
	breq display_down

	mov r20, r16					; Make a copy of ADC value for manipulation
	mov r21, r17
	
	ldi r18, low(BUTTON_LEFT_ADC)	; Load in the value of the left button ADC 
	ldi r19, high(BUTTON_LEFT_ADC)

	cp r20, r18						; Compare with left ADC
	cpc r21, r19

	brlo display_left				; Display left
	breq display_left




return_to_timer3_call:				; return to polling loop start
	ret

display_right:
; Display the right character in its respective spot
	lds temp, CHARSET_UPDATED
	cpi temp, 1
	brne return_to_timer3_call

	ldi temp, 'R'					; Load ascii value for R
	sts INDEX_CHANGED, temp			; store the changed index 
	ldi r18, 1						; Load position on lcd row then col
	ldi r19, 3						
	rcall update_lcd_at_position	; Updates the char on the lcd at the desired position
	rcall display_top_line_content	; display the topline char
	rcall update_charset			; mark char update complete
	rjmp return_to_timer3_call



display_left:
; Display the left character in its respective spot, uses the same logic as display_right
	lds temp, CHARSET_UPDATED
	cpi temp, 1
	brne return_to_timer3_call

	ldi temp, 'L'					; Load ascii value for L
	sts INDEX_CHANGED, temp
	ldi r18, 1						; Load position on lcd row then col
	ldi r19, 0
	rcall update_lcd_at_position	; Updates the char on the lcd at the desired position
	rcall display_top_line_content	
	rcall update_charset
	rjmp return_to_timer3_call


display_up:
; Display the up character in its respective spot
	ldi temp, 'U'					; Load ascii value for U
	ldi r18, 1						; Load position on lcd row then col
	ldi r19, 2
	rcall update_lcd_at_position	; Updates the char on the lcd at the desired position

	lds temp, CHARSET_UPDATED		; check if char has been updated this cycle already
	cpi temp, 1
	breq up_char					; if not, increment the character
	rjmp return_to_timer3_call

up_char:
	; Update the char from the hex string 
	rcall display_top_line_content	; displays the next char
	rcall get_current_char_index	; call to get the char index

	inc temp						; temp will contain the current char index
	cpi temp, 17					; loop around if incrementing above number of char sets
	brlo update_index
	clr temp
	rjmp update_index

display_down:
; Display the down character in its respective spot, uses same logic as display_up
	ldi temp, 'D'					; Load ascii value for D
	ldi r18, 1						; Load position on lcd row then col
	ldi r19, 1
	rcall update_lcd_at_position	; Updates the char on the lcd at the desired position
	
	lds temp, CHARSET_UPDATED		; check is charset updated already this cycle
	cpi temp, 1
	breq down_char					; if not, decrement char
	rjmp return_to_timer3_call

down_char:
; decrements the character and displays it to the lcd screen
	; Update the char from the hex string 
	rcall display_top_line_content	; displays the next char
	rcall get_current_char_index	; gets the current char index which is stored in temp
	
	dec temp
	brmi wrap_around				; wrap around if decrementing below the 0th lcd index position
	rjmp update_index

wrap_around:	
; wrap around to 16 again if decrementing below the 0th lcd index position					
	ldi temp, 16
	rjmp update_index

update_index:						; stores the update value of 1 or 0 in the charset_updated data
	st Z, temp

	clr temp
	sts CHARSET_UPDATED, temp		; records whether or not the charset has been updated already this cycle

	rjmp return_to_timer3_call

get_current_char_index:				; returns the current char index in temp
	clr r17
	lds temp, CURRENT_CHAR_INDEX
	ldi ZH, high(CURRENT_CHARSET_INDEX << 1)
	ldi ZL, low(CURRENT_CHARSET_INDEX << 1)
	add ZL, temp
	adc ZH, r17
	ld temp, Z
	ret

display_top_line_content:
	ldi ZH, high(TOP_LINE_CONTENT << 1)		; load the address of top line content	
	ldi ZL, low(TOP_LINE_CONTENT << 1)
	ld temp, Z						; Load in the char to be displayed
	ldi r18, 0						; set the row
	lds r19, CURRENT_CHAR_INDEX		; load in the current column index to display the char
	rcall update_lcd_at_position	; Updates the char on the lcd at the desired position
	ret

update_charset:						; clears the charset update to show that the charset has not been updated this cycle
	clr temp
	sts CHARSET_UPDATED, temp
	ret

stop:
	rjmp stop


timer1:
	; Start ADC conversion
	ldi r16, (1 << ADSC)			; Load bit position of ADSC
		lds r17, ADCSRA					; Load ADCSRA register into r17
		or r17, r16						; Set the ADSC bit in r17	
		sts ADCSRA, r17					; ADSC bit is set to start conversion				

wait_adc:
	lds r16, ADCSRA					; Wait until ADSC bit resets to 0
	sbrs r16, ADSC					; Check if the ADSC bit is still set
	rjmp conversion_complete		; If the bit has reset the conversion is complete
	rjmp wait_adc					; Loop until ADC conversion is complete

conversion_complete:
	; Read ADC result and compare with 900
	ldi r18, low(900)
	ldi r19, high(900)

	lds r16, ADCL					; Load result from ADC
	lds r17, ADCH

	sts LAST_BUTTON_PRESSED, r16	; store the ADC value in the last button pressed data position
	sts LAST_BUTTON_PRESSED+1, r17

	rcall compare_words				; Compare the ADC result to 900

	cpi r25, 0						; Check if r25 has -1, 0, or 1, corresponding to ADC - 900
	brmi button_pressed				; If ADC is less than 900 a button was pressed
		
button_not_pressed:
	; Button is not pressed, set BUTTON_IS_PRESSED to 0
	clr r16							
	sts BUTTON_IS_PRESSED, r16
	rjmp end_isr

button_pressed:
	; Button is pressed, set BUTTON_IS_PRESSED to 1
	ldi r16, 1
	sts BUTTON_IS_PRESSED, r16

end_isr:							; returns from timer1 interrupt
	reti

; timer3:
;
; Note: There is no "timer3" interrupt handler as you must use
; timer3 in a polling style (i.e. it is used to drive the refreshing
; of the LCD display, but LCD functions cannot be called/used from
; within an interrupt handler).


timer4:

	;code to check if the right button is pressed (set in timer3)
	;will increment right or left in the data space and set the right button pressed to 0
	;which in timer3 will cause the loop to break into updating the char
	lds temp, INDEX_CHANGED				; loads in the value of index changed
	cpi temp, 76						; checks if the index was changed left or right
	breq shift_left		
	lds temp, INDEX_CHANGED		
	cpi temp, 82
	breq shift_right
	rjmp update_char					; if index wasnt changed to the left or the right, then fetch next char

shift_left:				
; decrements the position of the char on the lcd screen and wraps around from 0 back to 16
	lds temp, CURRENT_CHAR_INDEX
	dec temp
	cpi temp, 0
	brmi wrap							; if decrementing below 0, then wrap back to 16
	rjmp update_position

wrap:
	ldi temp, 16						; wrap back to 16

update_position:

	sts CURRENT_CHAR_INDEX, temp		; store the next char position in the current_char_index data
	rjmp update_char					; fetch next char

shift_right:
; same logic and shift_left but wraps from 16 back to 0
	lds temp, CURRENT_CHAR_INDEX
	inc temp
	cpi temp, 17
	brlo update_position
	clr temp
	rjmp update_position
	
update_char:
	lds temp, CURRENT_CHAR_INDEX			; fetch the current char index to be displayed to on the lcd screen
	clr r17				
	ldi ZH, high(CURRENT_CHARSET_INDEX << 1); load in the data position of the current charset at the current index
	ldi ZL, low(CURRENT_CHARSET_INDEX << 1)
	add ZL, temp							; add the current char index to retrieve the data at the current position on the lcd screen
	adc ZH, r17
	ld temp, Z								; Load in the char at the current index on the lcd screen
	ldi ZH, high(AVAILABLE_CHARSET << 1)	; Load the address of the charset string
	ldi ZL, low(AVAILABLE_CHARSET << 1)
	add ZL, temp							; Increment the address by the value of the char at the current position		
	adc ZH, r17	
	lpm temp, Z								; Load in the desired char
	ldi ZH, high(TOP_LINE_CONTENT << 1)
	ldi ZL, low(TOP_LINE_CONTENT << 1)		; Load in the data address for the top line content
	st Z, temp								; Store desired char in top_line_content to be displayed next

	ldi temp, 1						
	sts CHARSET_UPDATED, temp				; set the charset updated to 1 to inform that a char has been changed this cycle
	clr temp			
	sts INDEX_CHANGED, temp					; clear index changed to inform that the program is ready to accept the next change

	reti


; ****************************************************
; ******* END OF SECOND "STUDENT CODE" SECTION *******
; ****************************************************


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================

; r17:r16 -- word 1
; r19:r18 -- word 2
; word 1 < word 2? return -1 in r25
; word 1 > word 2? return 1 in r25
; word 1 == word 2? return 0 in r25
;
compare_words:
	; if high bytes are not different, look at lower bytes
	cp r17, r19
	breq compare_words_lower_byte

	; since high bytes are different, use these to
	; determine result
	;
	; if C is set from previous cp, it means r17 < r19
	; 
	; preload r25 with 1 with the assume r17 > r19
	ldi r25, 1
	brcs compare_words_is_less_than
	rjmp compare_words_exit
	

compare_words_is_less_than:
	ldi r25, -1
	rjmp compare_words_exit

compare_words_lower_byte:
	clr r25
	cp r16, r18
	breq compare_words_exit

	ldi r25, 1
	brcs compare_words_is_less_than  ; re-use what we already wrote...

compare_words_exit:
	ret

.cseg
AVAILABLE_CHARSET: .db "0123456789abcdef_", 0


.dseg

BUTTON_IS_PRESSED: .byte 1			; updated by timer1 interrupt, used by LCD update loop
LAST_BUTTON_PRESSED: .byte 1        ; updated by timer1 interrupt, used by LCD update loop

TOP_LINE_CONTENT: .byte 16			; updated by timer4 interrupt, used by LCD update loop
CURRENT_CHARSET_INDEX: .byte 16		; updated by timer4 interrupt, used by LCD update loop
CURRENT_CHAR_INDEX: .byte 1			; ; updated by timer4 interrupt, used by LCD update loop


; =============================================
; ======= END OF "DO NOT TOUCH" SECTION =======
; =============================================


; ***************************************************
; **** BEGINNING OF THIRD "STUDENT CODE" SECTION ****
; ***************************************************

.dseg

; If you should need additional memory for storage of state,
; then place it within the section. However, the items here
; must not be simply a way to replace or ignore the memory
; locations provided up above.
CHARSET_UPDATED: .byte 1		; Track if charset has been updated
INDEX_CHANGED: .byte 1			; Tracks if lcd index changed


; ***************************************************
; ******* END OF THIRD "STUDENT CODE" SECTION *******
; ***************************************************
