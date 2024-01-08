; a2-signalling.asm
; CSC 230: Fall 2022
;
; Student name: Justin Milner
; Student ID: V00906688
; Date of completed work: October 21 2023
;
; *******************************
; Code provided for Assignment #2
;
; Author: Mike Zastre (2022-Oct-15)
;
 
; This skeleton of an assembly-language program is provided to help you
; begin with the programming tasks for A#2. As with A#1, there are "DO
; NOT TOUCH" sections. You are *not* to modify the lines within these
; sections. The only exceptions are for specific changes changes
; announced on Brightspace or in written permission from the course
; instructor. *** Unapproved changes could result in incorrect code
; execution during assignment evaluation, along with an assignment grade
; of zero. ****

.include "m2560def.inc"
.cseg
.org 0

; ***************************************************
; **** BEGINNING OF FIRST "STUDENT CODE" SECTION ****
; ***************************************************

	; initializion code will need to appear in this
    ; section

	; Configure DDRx for output
	ldi r17, 0xFF
	out DDRB, r17
	sts DDRL, r17

	; Initialize stack pointer
	ldi r16, LOW(RAMEND)
	out SPL, r16
	ldi r16, HIGH(RAMEND)
	out SPH, r16





; ***************************************************
; **** END OF FIRST "STUDENT CODE" SECTION **********
; ***************************************************

; ---------------------------------------------------
; ---- TESTING SECTIONS OF THE CODE -----------------
; ---- TO BE USED AS FUNCTIONS ARE COMPLETED. -------
; ---------------------------------------------------
; ---- YOU CAN SELECT WHICH TEST IS INVOKED ---------
; ---- BY MODIFY THE rjmp INSTRUCTION BELOW. --------
; -----------------------------------------------------

	rjmp test_part_e
	; Test code


test_part_a:
	ldi r16, 0b00100001
	rcall set_leds
	rcall delay_long

	clr r16
	rcall set_leds
	rcall delay_long

	ldi r16, 0b00111000
	rcall set_leds
	rcall delay_short

	clr r16
	rcall set_leds
	rcall delay_long

	ldi r16, 0b00100001
	rcall set_leds
	rcall delay_long

	clr r16
	rcall set_leds

	rjmp end


test_part_b:
	ldi r17, 0b00101010
	rcall slow_leds
	ldi r17, 0b00010101
	rcall slow_leds
	ldi r17, 0b00101010
	rcall slow_leds
	ldi r17, 0b00010101
	rcall slow_leds

	rcall delay_long
	rcall delay_long

	ldi r17, 0b00101010
	rcall fast_leds
	ldi r17, 0b00010101
	rcall fast_leds
	ldi r17, 0b00101010
	rcall fast_leds
	ldi r17, 0b00010101
	rcall fast_leds
	ldi r17, 0b00101010
	rcall fast_leds
	ldi r17, 0b00010101
	rcall fast_leds
	ldi r17, 0b00101010
	rcall fast_leds
	ldi r17, 0b00010101
	rcall fast_leds

	rjmp end

test_part_c:
	ldi r16, 0b11111000
	push r16
	rcall leds_with_speed
	pop r16

	ldi r16, 0b11011100
	push r16
	rcall leds_with_speed
	pop r16

	ldi r20, 0b00100000
test_part_c_loop:
	push r20
	rcall leds_with_speed
	pop r20
	lsr r20
	brne test_part_c_loop

	rjmp end


test_part_d:
	ldi r21, 'E'
	push r21
	rcall encode_letter
	pop r21
	push r25
	rcall leds_with_speed
	pop r25

	rcall delay_long

	ldi r21, 'A'
	push r21
	rcall encode_letter
	pop r21
	push r25
	rcall leds_with_speed
	pop r25

	rcall delay_long


	ldi r21, 'M'
	push r21
	rcall encode_letter
	pop r21
	push r25
	rcall leds_with_speed
	pop r25

	rcall delay_long

	ldi r21, 'H'
	push r21
	rcall encode_letter
	pop r21
	push r25
	rcall leds_with_speed
	pop r25

	rcall delay_long

	rjmp end


test_part_e:
	ldi r25, HIGH(WORD02 << 1)
	ldi r24, LOW(WORD02 << 1)
	rcall display_message
	rjmp end

end:
    rjmp end
	





; ****************************************************
; **** BEGINNING OF SECOND "STUDENT CODE" SECTION ****
; ****************************************************

; Set leds function
set_leds:
	
	; Extract and map bits for PORTL
	mov r17, r16			; Copy r16 to r1x for manipulation
	lsl r17					; Shift bit into the respective position that maps to the PORTL output
	lsl r17
	andi r17, 0b10000000	; Set the bit in PORTL if the respective bit is set in r16
	
	mov r18, r16			; Repeat for each PORTL mapped bit
	lsl r18
	andi r18, 0b00100000

	mov r19, r16
	andi r19, 0b00001000

	mov r20, r16
	lsr r20
	andi r20, 0b00000010

	or r17, r18				; Combine all set bits
	or r17, r19
	or r17, r20

	sts PORTL, r17			; Write desired output to PORTL

	; Extract and map bits for PORTB
	mov r17, r16			; Copy r16 to r1x for manipulation
	lsl r17					; Shift bit into the respective position that maps to the PORTB output
	lsl r17
	andi r17, 0b00001000	; Set the bit in PORTB if the respective bit is set in r16

	mov r18, r16			; Repeat for all PORTB mapped bits
	lsl r18
	andi r18, 0b00000010

	or r17, r18				; Combine all set bits
	out PORTB, r17			; Write to PORTB

	ret

; Slow leds functino
slow_leds:
	mov r16, r17			; Copy r17 into r16 to work with set_leds function
	rcall set_leds			; set the LED's
	rcall delay_long		; Delay the computer by 1 second
	clr r16
	rcall set_leds			; Clear LED's

	ret

; Fast leds functino
fast_leds:
	mov r16, r17			; Copy r17 into r16 to work with set_leds function
	rcall set_leds			; set the LED's
	rcall delay_short		; Delay the computer by 1/4 second
	clr r16
	rcall set_leds			; Clear LED's
	
	ret

; Leds with speed function
leds_with_speed:
	in YH, SPH				; Initialize Y psuedo register with SP for loading data from the memory
	in YL, SPL

	ldd r17, Y + 4			; Load the byte located above the return address in the stack

	mov r18, r17			; Make a copy of r17 in r18 for manipulation
	andi r18, 0b11000000	; Apply mask to remove all but the 2 MSB's

	cpi r18, 0b11000000		; Determine if the 2 MSB's are set or not
	breq slow_leds			; Call slow leds if they are set

	cpi r18, 0x00
	breq fast_leds			; Call fast leds if the 2 MSB's are not set

	ret


; Note -- this function will only ever be tested
; with upper-case letters, but it is a good idea
; to anticipate some errors when programming (i.e. by
; accidentally putting in lower-case letters). Therefore
; the loop does explicitly check if the hyphen/dash occurs,
; in which case it terminates with a code not found
; for any legal letter.

; Encode letter function
encode_letter:
	clr r25					; Prepare r25 to hold return value
	in YH, SPH				; Initialize Y psuedo register with SP for loading data from the memory
	in YL, SPL

	ldd r17, Y + 4			; Load the character byte located above the return address in the stack
	ldi r30, LOW(PATTERNS << 1)   ; Initialize a pointer to the PATTERNS data table address using Z pseudo register
	ldi r31, HIGH(PATTERNS << 1)

	ldi r16, 7				; Prepare r16 to loop 7 times over the data sequence

search_loop:
	lpm r18, Z				; Load the value pointed to in the data table by Z into r18			
	cp r17, r18	  			; Compare the character to the byte from the table
	breq found				; If they match, jump to found
	adiw r30, 8				; Increment to the next char in PATTERNS
	rjmp search_loop		
	

found:
	; Read ASCII values from table and convert to a byte
	dec r16
	breq speed_factor		; On the 7th iteration branch to read in the speed factor
	adiw r30, 1				; Point the Z psuedo register to the next byte in PATTERNS table
	lpm r17, Z 				; Read the byte into r17
	cpi r17, 0x6F			; If the current char read is 'o' then proceed to set the respective bit
	breq on
	rjmp found				; If the current char read is not 'o' then leave the bit unset and proceed

on:
	mov r19, r16 			; Make a copy of the iteration counter in r19
	ldi r18, 1
	subi r19, 1				; Subract 1 from r19 to match the number of bits
	breq set_bit			; If the value in r19 is 0 then dont shift any bits and set the 0 bit

shift_loop:				
	lsl r18					; Shift the bit by the desired positions to set the respective bit
	dec r19
	brne shift_loop			; Continue looping while the bit counter is above zero

set_bit:					
	or r25, r18				; Set the desired bit in r25
	rjmp found

speed_factor:
	adiw r30, 1				; Point the Z psuedo register to the next byte in PATTERNS table
	lpm r17, Z 				; Read the byte into r17
	cpi r17, 1				; If the speed factor is 1, then 2 MSB's get set, otherwise return
	breq set_2MSBs
	ret
	
set_2MSBs:
	ori r25, 0b11000000		; Set the two MSB's for 1 second delay
	ret


; Display message function
display_message:
	movw r31:r30, r25:r24	; Initialize Z psuedo register pointer to access data from memory	

next_char:	
	lpm r16, Z 				; Read in data from Z register
	cpi r16, 0
	breq return				; Return if r16 contains the null character which is ASCII 0
	push ZL					; Save the current address of the Z pointer onto the stack
	push ZH
	push r16				; Push the char onto the stack
	rcall encode_letter		; Encode the letter
	pop r16					; Remove r16 from the stack
	pop ZH					; Retrieve the memory address of the Z pointer for the particular word
	pop ZL
	push r25				; Push the result from encoding the letter onto the stack
	rcall leds_with_speed	; Call function to activate the LED's
	rcall delay_long		; Delay the computer by 1 second
	pop r25					
	adiw r30, 1				; Increment data pointer to the next byte
	rjmp next_char			; Jump back to process the next character
	
return:
	ret


; ****************************************************
; **** END OF SECOND "STUDENT CODE" SECTION **********
; ****************************************************




; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================

; about one second
delay_long:
	push r16

	ldi r16, 14
delay_long_loop:
	rcall delay
	dec r16
	brne delay_long_loop

	pop r16
	ret


; about 0.25 of a second
delay_short:
	push r16

	ldi r16, 4
delay_short_loop:
	rcall delay
	dec r16
	brne delay_short_loop

	pop r16
	ret

; When wanting about a 1/5th of a second delay, all other
; code must call this function
;
delay:
	rcall delay_busywait
	ret


; This function is ONLY called from "delay", and
; never directly from other code. Really this is
; nothing other than a specially-tuned triply-nested
; loop. It provides the delay it does by virtue of
; running on a mega2560 processor.
;
delay_busywait:
	push r16
	push r17
	push r18

	ldi r16, 0x08
delay_busywait_loop1:
	dec r16
	breq delay_busywait_exit

	ldi r17, 0xff
delay_busywait_loop2:
	dec r17
	breq delay_busywait_loop1

	ldi r18, 0xff
delay_busywait_loop3:
	dec r18
	breq delay_busywait_loop2
	rjmp delay_busywait_loop3

delay_busywait_exit:
	pop r18
	pop r17
	pop r16
	ret


; Some tables
PATTERNS:
	; LED pattern shown from left to right: "." means off, "o" means
    ; on, 1 means long/slow, while 2 means short/fast.
	.db "A", "..oo..", 1
	.db "B", ".o..o.", 2
	.db "C", "o.o...", 1
	.db "D", ".....o", 1
	.db "E", "oooooo", 1
	.db "F", ".oooo.", 2
	.db "G", "oo..oo", 2
	.db "H", "..oo..", 2
	.db "I", ".o..o.", 1
	.db "J", ".....o", 2
	.db "K", "....oo", 2
	.db "L", "o.o.o.", 1
	.db "M", "oooooo", 2
	.db "N", "oo....", 1
	.db "O", ".oooo.", 1
	.db "P", "o.oo.o", 1
	.db "Q", "o.oo.o", 2
	.db "R", "oo..oo", 1
	.db "S", "....oo", 1
	.db "T", "..oo..", 1
	.db "U", "o.....", 1
	.db "V", "o.o.o.", 2
	.db "W", "o.o...", 2
	.db "X", "oo....", 2
	.db "Y", "..oo..", 2
	.db "Z", "o.....", 2
	.db "-", "o...oo", 1   ; Just in case!

WORD00: .db "HELLOWORLD", 0, 0
WORD01: .db "THE", 0
WORD02: .db "QUICK", 0
WORD03: .db "BROWN", 0
WORD04: .db "FOX", 0
WORD05: .db "JUMPED", 0, 0
WORD06: .db "OVER", 0, 0
WORD07: .db "THE", 0
WORD08: .db "LAZY", 0, 0
WORD09: .db "DOG", 0

; =======================================
; ==== END OF "DO NOT TOUCH" SECTION ====
; =======================================

