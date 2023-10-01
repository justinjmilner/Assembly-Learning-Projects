	.cseg
	.org 0

	; 94 + 9 = 03, carry = 1
	; ldi r16, 0x94
	; ldi r17, 0x09

	; 86 + 79 = 65, carry = 1
	; ldi r16, 0x86
	; ldi r17, 0x79

	; 35 + 49 = 84, carry = 0
	; ldi r16, 0x35
	; ldi r17, 0x49

	; 32 + 41 = 73, carry = 0
	ldi r16, 0x32
	ldi r17, 0x41
	
	ldi r18, 0				; track number of divisions by 16 for r16
	ldi r19, 0				; track number of divisions by 16 for r17
	ldi r20, 16				; useful for later on

	r16_loop_start:
		subi r16, 16		; begin subtracting 16's from r16
		brcs r17_loop_start	; once r16 becomes negative then quit subtracting
		inc r18				; store the number of 16's subtracted from r16
		rjmp r16_loop_start

	r17_loop_start:
		subi r17, 16		; begin subtracting 16's from r17
		brcs add_numbers	; once r17 becomes negative then quit subtracting
		inc r19				; store the number of 16's subtracted from r17
		rjmp r17_loop_start

	add_numbers:
		mov r21, r18		; make a copy of r18
		lsl r18				; *2 - multiply r18 by 10 to get the 10's place
		lsl r18				; *4
		lsl r18				; *8
		add r18, r21		; *9
		add r18, r21		; *10 - done multiplying r18 by 10

		mov r22, r19		; make a copy of r19
		lsl r19				; *2 - multiply r19 by 10 to get the 10's place
		lsl r19				; *4
		lsl r19				; *8
		add r19, r22		; *9
		add r19, r22		; *10 - done multiplying r19 by 10

		add r17, r20		; add a 16 back to r17 to get remainder of r17 modulo 16
		add r19, r17		; add r17 remainder to r19 to complete the decimal conversion of the BCD

		add r16, r20		; add a 16 back to r16 to get remainder of r16 modulo 16
		add r18, r16		; add r16 remainder to r18 to complete the decimal conversion of the BCD
				
		add r18, r19		; add the decimal values of the two BCD numbers to get final decimal number result

		ldi r20, 100
		sub r18, r20		; subtract 100 and check if carry flag set, if so number is less than 100
		brcc great_eq_100	
		add r18, r20
		rjmp great_eq_10

	great_eq_100:
		ldi r24, 1			; set the 100's place to 1

	great_eq_10:			
		ldi r23, 10			; check if 10's place in decimal is 0, if so go to store number
		cp r23, r18
		brge store_number
		ldi r23, 0			; clear r23 for the next process

	process_decimal_10s:
		subi r18, 10 		
		brcs convert_decimal_to_hex	; once r16 becomes negative then quit subtracting
		inc r23
		rjmp process_decimal_10s

	convert_decimal_to_hex:
		lsl r23				; *2 - multiply the number of 10's by 16
		lsl r23				; *4
		lsl r23				; *8
		lsl r23				; *16

		ldi r20, 10
		add r18, r20		; add 10 back to r18 because of over-subtraction in processing 10's place
		add r18, r23		; add the number of 10's * 16 back to the resulting number

	store_number:
		mov r25, r18		; store the resulting BCD hex number

bcd_addition_end:
	rjmp bcd_addition_end




