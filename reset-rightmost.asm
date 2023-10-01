    .cseg
    .org 0

	; ldi r16, 0b01011100
	; ldi r16, 0b10110110
	ldi r16, 0b10111111
	; ldi r16, 0b00000000

		mov r20, r16			; make a copy of the number to manipulate
		ldi r17, 1				; keep track of which bit we are parsing
		ldi r18, 0				; will contain the mask used in the mask function
	
	loop_start:
		lsr r20					; shift lsb into the carry flag
		brcs rightmost_loop     ; if carry flag is set then go to rightmost_loop
		lsl r17					; increment to the next bit position
		cpi r17, 0  			; check if all 8 bits have been parsed
		breq reset_rightmost_stop		
		rjmp loop_start

	rightmost_loop:			
		add r18, r17			; set the bit in the mask that are part of rightmost group
		lsl r17					; increment to the next bit position
		lsr r20					; check is lsb is set
		brcs rightmost_loop		; if the next lsb is set continue this loop
		brcc mask_function		; once an unset bit is reached after the rightmost group go to the mask

	mask_function:
		ldi r19, 255		    ; initialize a mask to invert bits in r18
		eor r18, r19			; flip the bits in the mask 
		and r16, r18			; reset the bits in the rightmost group
		mov r25, r16
	
reset_rightmost_stop:
    rjmp reset_rightmost_stop
