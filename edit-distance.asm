    .cseg
    .org 0

	ldi r16, 0b10101010
	ldi r17, 0b01010101

	ldi r18, 0					; count of differing bits
	ldi r19, 0					; count of total bits parsed
	loop_start:
		mov r20, r16			; make a copy of r16 to manipulate
		eor r20, r17			; eor will be non zero if r20 and r17 have a different bit
		lsr r20					; shift r20 to the right to push lsb out to carry to test if 1 or 0
		brcs increment			; if the carry bit is set then lsb is different between the two, increment counter
		lsr r16					; shift the bits right to prepare to eor the next lsb of both binary numbers
		lsr r17
		inc r19					; increase count of total bits checked
		cpi r19, 8				; check if all 8 bits have been checked
		breq store_result		
		rjmp loop_start

	increment:
		inc r18					; increase count of differing bits
		inc r19					; increase count of total bits checked
		cpi r19, 8				; check if all 8 bits have been checked
		breq store_result		
		lsr r16					; shift the bits right to perapre to eor the next lsb of both binary numbers
		lsr r17
		rjmp loop_start

	store_result:
		mov r25, r18

edit_distance_stop:
    rjmp edit_distance_stop
