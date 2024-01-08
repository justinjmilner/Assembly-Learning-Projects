;
; lab6.asm
;
.include "m2560def.inc"

;SPH, SPL etc are defined in "m2560def.inc"

	; initialize the stack pointer
.cseg

	ldi r16, 0xFF
	out SPL, r16
	ldi r16, 0x21
	out SPH, r16
	
	;example of passing parameter by reference	
	;call subroutine void strcpy(src, dest)
	;push 1st parameter - src address
	ldi r16, high(src << 1)
	push r16
	ldi r16, low(src <<1)
	push r16

	;push 2nd parameter - dest address
	ldi r16, high(dest)
	push r16
	ldi r16, low(dest)
	push r16

	call strcpy
	pop ZL
	pop ZH
	pop r16
	pop r16

	;Write your code here: call subroutine int strlen(string dest)
	;string dest is stored in SRAM, not flash memory
	;return value is in r24
	;push parameter dest, note it is in register Z already (line 31, 32)
	push ZH
	push ZL
	rcall strlength
	pop ZL
	pop ZH
	
	;Write your code here: call the method strLength
	
	;clear the stack and write the result to length in SRAM
	;Write your code here:
	

done: jmp done

strcpy:
	push r30
	push r31
	push r29
	push r28
	push r26
	push r27
	push r23 ; hold each character read from program memory
	IN YH, SPH ;SP in Y
	IN YL, SPL
	ldd ZH, Y + 14 ; Z <- src address
	ldd ZL, Y + 13
	ldd XH, Y + 12 ; Y <- dest address
	ldd XL, Y + 11

next_char:
	lpm r23, Z+
	st X+, r23
	tst r23
	brne next_char
	pop r23
	pop r27
	pop r26
	pop r28
	pop r29
	pop r31
	pop r30
	ret
	
;One parameter - the address of the string, could be in 
;flash or SRAM (chose one). The length of the string is
;going to be stored in r24
strlength:
	;write your code here
	ldi r24, -1
nxt_char:
	inc r24
	ld r23, Z+
	tst r23
	brne nxt_char
	
	ret

src: .db "Hello, world!", 0 ; c-string format

.dseg
.org 0x200
dest: .byte 14
length: .byte 1
