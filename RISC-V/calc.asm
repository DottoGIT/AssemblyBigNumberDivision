# Maciej Scheffer - Projekt RISC-V - program dziel¹cy dwie liczby 40 cyfrowe
	.eqv	Print, 4
	.eqv	PrintInt, 1
	.eqv	PrintChar, 11
	.eqv	Read, 8
	.eqv	Exit, 10
	
	.data
mess0:	.string	"Maciej Scheffer - Projekt RISC-V \n"
mess1:	.string	"Dzielna: "
mess2:	.string	"Dzielnik: "
mess3:	.string "Wynik: "
mess4:	.string "Bledne dane wejsciowe"
mess5:	.string	"Rejestry: "
mess6:	.string	"Iloraz: "
mess7:	.string "Reszta: "
enter:	.string	"\n"
fNum:	.space	46		# Dzielna Input
sNum:	.space	45		# Dzielnik Input
iloraz:	.string	"000000000000000000000000000000000000000000000"		# Iloraz output
reszta: .string	"000000000000000000000000000000000000000000000"		# reszta output
	
	.text
	
# Dzielna zapisywana na rejestrach s0-s4
# Dzielnik zapisywany na rejestrach s5-s9
# Wynik zapisywany na rejestrach a2-a6
# Liczba pomocnicza zapisywana na rejestrach t2-t6
# Zapsanie znaku wyniku rejestr s10
# Wolne rejestry: s11, t0, t1

main:	
	# Zapisz rejestry zachowywane
	jal	save_registers
	# Zapisz dane od u¿ytkownika
	jal	ask_for_data
	# Sprawdz czy nie dzielimy przez zero
	jal	validity_check
	# Zapisz dane na rejestrach
	jal	save_to_registers
	# Podziel liczby
	jal 	divide
	# Wypisz wynik
	jal	print_result
	# Wczytaj rejestry
	jal	load_registers
	# Zakoñcz program
	li	a7, Exit
	ecall

################################### SAVE TO REGISTERS FUNCTION ###################################

save_to_registers:
	# do kolejnych rejestrów wczytywane s¹ fragmenty liczby po 9 cyfr, znak zapisywany w rej. s10 (max 45 cyfr)
	# s11 - dlugosc liczby
	# s10 - rejestr znaku
	# t6 - iterator po liczbie
	# t5 - obecny znak
	# t4 - wskaŸnik na rejestr
	# t3 - licznik segmentów po 9
	# t1 - wyk³adnik dziesi¹tki
	# t0,t2 - tymczasowa pomocnicza
	mv	s10, zero
	mv	t4, zero
	mv	t3, zero
	# Wczytanie pierwszej liczby
	# zapamiêtaj znak
	la	t6, fNum	# iterator po pierwszym znaku w t6
	lbu	t5, (t6)	# pierwszy znak zapisany w t5
	li	t0, '-'
	bne 	t5, t0, save_to_registers_CountLetters
	addi	s10, s10, 1	# Dodaj 1 do rejestru znaku
	addi	t6, t6, 1	# Dodaj 1 do iteratora t6
save_to_registers_CountLetters:
	# Policz dlugosc liczby i przejdz na jej koniec
	lbu	t5, (t6)	# pierwszy znak zapisany w t5
	addi	t6, t6, 1	# Dodaj 1 do iteratora t6
	
	li	t0, ' '
	blt	t5, t0 save_to_registers_LettersCounted # je¿eli koniec liczby to przestañ liczyæ
	
	li	t0, '0'						# Ochrona przed nienumerycznym wejsciem
	bltu 	t5, t0, finish_program_with_error_BadData	#
	li	t0, '9'						#
	bgtu   	t5, t0, finish_program_with_error_BadData	#
	
	addi s11, s11, 1
	j save_to_registers_CountLetters
	
save_to_registers_LettersCounted:
	beqz	s11, finish_program_with_error_BadData		# Ochrona przed pustymi danymi
	li	t1, 1		# wyzeruj wykladnik
	addi	t6, t6, -2	# Wróæ na koniec liczby
save_to_registers_AddLoop:
	lbu	t5, (t6)	# Za³aduj ostatni znak
	addi	t6, t6, -1	# Zmniejsz iterator
	addi	s11, s11, -1	# Zmniejsz licznik dlugosci liczby
	addi	t3, t3, 1	# Zwieksz licznik segmentow o jeden
	
	bltz	s11, save_to_registers_StartSavingSecondNumber # Jezeli liczba sie skonczy zacznij zapisywac kolejna
	
	li	t0, 10		# D³ugoœæ segmentu
	blt	t3, t0, save_to_registers_DontInceaseRegisterCounter
	addi	t4, t4, 1	# Dodaj 1 do wskaznika rejestru
	li	t3, 1		# Wyzeruj licznik segmentow
	li	t1, 1		# Wyzeruj wykladnik
save_to_registers_DontInceaseRegisterCounter:

	# Zapisz liczbe do odpowiedniego rejestru
	mv	t0, t5		# dodaj do rejestru t5*wykladnik dziesiatki
	addi	t0, t0, -48	# Odejmij od charu '0' aby traktowany byl jak int
	mul	t0, t0, t1
	li	t2, 10
	mul	t1, t1, t2	# dodaj 1 do wykladnika diesiatki
	
	mv	t2, zero					# Sprawdz do jakiego rejestru zapisywac
	beq	t4, t2, save_to_registers_fNumMoveToReg0	#
	li	t2, 1						#
	beq	t4, t2, save_to_registers_fNumMoveToReg1	#
	li	t2, 2						#
	beq	t4, t2, save_to_registers_fNumMoveToReg2	#
	li	t2, 3						#
	beq	t4, t2, save_to_registers_fNumMoveToReg3	#
	li	t2, 4						#
	beq	t4, t2, save_to_registers_fNumMoveToReg4	#

save_to_registers_fNumMoveToReg0:
	add	s0, s0, t0
	j save_to_registers_AddLoop
save_to_registers_fNumMoveToReg1:
	add	s1, s1, t0
	j save_to_registers_AddLoop
save_to_registers_fNumMoveToReg2:
	add	s2, s2, t0
	j save_to_registers_AddLoop
save_to_registers_fNumMoveToReg3:
	add	s3, s3, t0
	j save_to_registers_AddLoop
save_to_registers_fNumMoveToReg4:
	add	s4, s4, t0
	j save_to_registers_AddLoop

save_to_registers_StartSavingSecondNumber:
	mv	s11, zero	# Zeresetuj rejestry
	mv 	t4, zero	#
	mv 	t3, zero	#
	# Wczytanie drugiej liczby
	# zapamiêtaj znak
	la	t6, sNum	# iterator po pierwszym znaku w t6
	lbu	t5, (t6)	# pierwszy znak zapisany w t5
	li	t0, '-'
	bne 	t5, t0, save_to_registers_CountLettersSecondNum
	addi	s10, s10, 1	# Dodaj 1 do rejestru znaku
	addi	t6, t6, 1	# Dodaj 1 do iteratora t6
save_to_registers_CountLettersSecondNum:
	# Policz dlugosc liczby i przejdz na jej koniec
	lbu	t5, (t6)	# pierwszy znak zapisany w t5
	addi	t6, t6, 1	# Dodaj 1 do iteratora t6
	
	li	t0, ' '
	blt	t5, t0, save_to_registers_LettersCountedSecondNum # je¿eli koniec liczby to przestañ liczyæ
	
	li	t0, '0'						# Ochrona przed nienumerycznym wejsciem
	bltu 	t5, t0, finish_program_with_error_BadData	#
	li	t0, '9'						#
	bgtu   	t5, t0, finish_program_with_error_BadData	#
	
	addi s11, s11, 1
	j save_to_registers_CountLettersSecondNum
	
save_to_registers_LettersCountedSecondNum:
	beqz	s11, finish_program_with_error_BadData		# Ochrona przed pustymi danymi
	li	t1, 1		# wyzeruj wykladnik
	addi	t6, t6, -2	# Wróæ na koniec liczby
save_to_registers_AddLoopSecondNum:
	lbu	t5, (t6)	# Za³aduj ostatni znak
	addi	t6, t6, -1	# Zmniejsz iterator
	addi	s11, s11, -1	# Zmniejsz licznik dlugosci liczby
	addi	t3, t3, 1	# Zwieksz licznik segmentow o jeden
	
	bltz	s11, save_to_registers_finish # Jezeli liczba sie skonczy zakoncz funkcje
	
	li	t0, 10		# D³ugoœæ segmentu
	blt	t3, t0, save_to_registers_DontInceaseRegisterCounterSecondNum
	addi	t4, t4, 1	# Dodaj 1 do wskaznika rejestru
	li	t3, 1		# Wyzeruj licznik segmentow
	li	t1, 1		# Wyzeruj wykladnik
save_to_registers_DontInceaseRegisterCounterSecondNum:
	# Zapisz liczbe do odpowiedniego rejestru
	mv	t0, t5		# dodaj do rejestru t5*wykladnik dziesiatki
	addi	t0, t0, -48	# Odejmij od charu '0' aby traktowany byl jak int
	mul	t0, t0, t1
	li	t2, 10
	mul	t1, t1, t2	# dodaj 1 do wykladnika diesiatki
	
	mv	t2, zero					# Sprawdz do jakiego rejestru zapisywac
	beq	t4, t2, save_to_registers_sNumMoveToReg0	#
	li	t2, 1						#
	beq	t4, t2, save_to_registers_sNumMoveToReg1	#
	li	t2, 2						#
	beq	t4, t2, save_to_registers_sNumMoveToReg2	#
	li	t2, 3						#
	beq	t4, t2, save_to_registers_sNumMoveToReg3	#
	li	t2, 4						#
	beq	t4, t2, save_to_registers_sNumMoveToReg4

save_to_registers_sNumMoveToReg0:
	add	s5, s5, t0
	j save_to_registers_AddLoopSecondNum
save_to_registers_sNumMoveToReg1:
	add	s6, s6, t0
	j save_to_registers_AddLoopSecondNum
save_to_registers_sNumMoveToReg2:
	add	s7, s7, t0
	j save_to_registers_AddLoopSecondNum
save_to_registers_sNumMoveToReg3:
	add	s8, s8, t0
	j save_to_registers_AddLoopSecondNum
save_to_registers_sNumMoveToReg4:
	add	s9, s9, t0
	j save_to_registers_AddLoopSecondNum
save_to_registers_finish:
	ret

#####################################   DIVIDE FUNCTION    #######################################
divide:
	# s11 - licznik potêg dwójki
	# a0, a7 - liczby pomocnicze
	# zapisz s11, t0, t1, t2 ( przydatne bo przy wypisywaniu brakuje rejestrow)
	
	mv	a2, zero	# Wyzeruj wynik
	mv	a3, zero
	mv	a4, zero
	mv	a5, zero
	mv	a6, zero
	
	addi	sp, sp, -4	# Zapisz rejestry
	sw	s11, (sp)
	addi	sp, sp, -4	
	sw	t0, (sp)
	addi	sp, sp, -4	
	sw	t1, (sp)
	addi	sp, sp, -4	
	sw	t2, (sp)
	addi	sp, sp, -4	
	sw	t3, (sp)
	
	
divide_start:	
	li	s11, 0	# Licznik = 0	
															
	mv	t6, s9	# P = L2				
	mv	t5, s8	#
	mv	t4, s7	#
	mv	t3, s6	#
	mv	t2, s5	#
	
	mv	a7, ra
	jal	compare_registers
	mv	ra, a7
	
	li	a7, 0
	bgt	a0, a7, divide_L1geL2
	# Przed zakonczeniem funckji wczytaj zmienne pomocnicze
	lw	t3, (sp)	
	addi	sp, sp, 4
	lw	t2, (sp)	
	addi	sp, sp, 4
	lw	t1, (sp)	
	addi	sp, sp, 4
	lw	t0, (sp)	
	addi	sp, sp, 4
	lw	s11, (sp)	
	addi	sp, sp, 4
	ret
	
divide_L1geL2:
	# zapisz pomocnicza 
	mv	a7, ra
	jal	save_pom
	mv	ra, a7
	# porownaj z pomocnicza * 2
	
	mv	a7, ra
	jal	shift_left
	mv	ra, a7
	
	mv	a7, ra
	jal	compare_registers
	mv	ra, a7
	
	li	a7, 0
	bgt	a0, a7, divide_L1geL2_T
	# divide_L1geL2_N - wczytaj pomocnicza
	# Dodaj iloraz
	# Pomnó¿ 2 tyle ile jest w s11	
	li	t2, 1
	mv	t3, zero
	mv	t4, zero
	mv	t5, zero
	mv	t6, zero	
	beqz	s11, divide_loopEnd
divide_loop:
	mv	a7, ra
	jal	shift_left
	mv	ra, a7
	addi	s11, s11, -1
	bnez	s11, divide_loop
	
divide_loopEnd:
	mv	a7, ra
	jal	add_registers
	mv	ra, a7
	# odejmij pomocnicza
	mv	a7, ra
	jal	load_pom
	mv	ra, a7
	
	mv	a7, ra
	jal	subtract_registers
	mv	ra, a7
	b	divide_start
	
divide_L1geL2_T:
	addi	sp, sp, 20
	addi	s11, s11, 1
	b 	divide_L1geL2	

####################################   PRZESUNIECIE W LEWO  #######################################

shift_left:
	# Mno¿y liczbe pomocnicz¹ przez 2 za pomoc¹ przesuniêcia binarnego
	# t0 - liczba pomocnicza
	li	t0, 1000000000 # liczba ktora trzeba odjac aby poprawic przepelnienie
	slli	t6, t6, 1	# Przesuñ ostatni rejestr (nie moze byc przepelniony)
	# Przesuwanie 4 rejestru
	mv	t1, t5
	slli	t1, t1, 1
	blt	t1, t0, shift_left_dontAddS4 # Nie poprawiaj jezeli nie nastapi przepelnienie
	sub	t1, t1, t0
	addi	t6, t6, 1
shift_left_dontAddS4:
	mv	t5, t1
	# Przesuwanie 3 rejestru
	mv	t1, t4
	slli	t1, t1, 1
	blt	t1, t0, shift_left_dontAddS3 # Nie poprawiaj jezeli nie nastapi przepelnienie
	sub	t1, t1, t0
	addi	t5, t5, 1
shift_left_dontAddS3:
	mv	t4, t1
	# Przesuwanie 2 rejestru
	mv	t1, t3
	slli	t1, t1, 1
	blt	t1, t0, shift_left_dontAddS2 # Nie poprawiaj jezeli nie nastapi przepelnienie
	sub	t1, t1, t0
	addi	t4, t4, 1
shift_left_dontAddS2:
	mv	t3, t1
	# Przesuwanie 1 rejestru
	mv	t1, t2
	slli	t1, t1, 1
	blt	t1, t0, shift_left_dontAddS1 # Nie poprawiaj jezeli nie nastapi przepelnienie
	sub	t1, t1, t0
	addi	t3, t3, 1
shift_left_dontAddS1:
	mv	t2, t1
	ret

#####################################   COMPARE FUNCTION    #######################################
compare_registers:
	# Porównuje dzieln¹ z pomocnicz¹
	# a0 - wynik porównania (0 mniejsza, 1 równa, 2 wiêksza)
	
	bgt	s4, t6, return_greater
	blt	s4, t6	return_less
	
	bgt	s3, t5, return_greater
	blt	s3, t5	return_less
	
	bgt	s2, t4, return_greater
	blt	s2, t4	return_less
	
	bgt	s1, t3, return_greater
	blt	s1, t3	return_less
	
	bgt	s0, t2, return_greater
	blt	s0, t2	return_less
	
	b	return_equal
	
return_greater:
	li	a0, 2
	ret
return_equal:
	li	a0, 1
	ret
return_less:
	li	a0, 0
	ret

##########################################   ADD REGISTERS  ######################################

add_registers:
	# Dodaje do wyniku licznik poteg dwojki
	# t0 - zajêty
	# t1 - pomocniczy
	li	t1, 1000000000
	# Po prostu dodaj rejestry
	add 	a2, a2, t2
	add 	a3, a3, t3
	add 	a4, a4, t4
	add 	a5, a5, t5
	add 	a6, a6, t6
	# Popraw przepe³nienia
	blt	a2, t1, add_registers_0NotOverflow
	sub	a2, a2, t1
	addi	a3, a3, 1
add_registers_0NotOverflow:
	blt	a3, t1, add_registers_1NotOverflow
	sub	a3, a3, t1
	addi	a4, a4, 1
add_registers_1NotOverflow:
	blt	a4, t1, add_registers_2NotOverflow
	sub	a4, a4, t1
	addi	a5, a5, 1
add_registers_2NotOverflow:
	blt	a5, t1, add_registers_3NotOverflow
	sub	a5, a5, t1
	addi	a6, a6, 1
add_registers_3NotOverflow:
	ret
	
#######################################   SUBTRACT REGISTERS  ####################################

subtract_registers:
	# Odejmuje od dzielnej liczbe pomocnicza
	# t0 - zajete
	# t1 - pomocniczy
	li 	t1, 1000000000
	# Przygotuj sie do odejmowanie (pododawaj odpowiednie wartosci do rejestrow od innych odejmij)
	bge	s0, t2, subtract_registers_0RegIsBigger
	add	s0, s0, t1
	addi	s1, s1, -1
subtract_registers_0RegIsBigger:
	bge	s1, t3, subtract_registers_1RegIsBigger
	add	s1, s1, t1
	addi	s2, s2, -1
subtract_registers_1RegIsBigger:
	bge	s2, t4, subtract_registers_2RegIsBigger
	add	s2, s2, t1
	addi	s3, s3, -1
subtract_registers_2RegIsBigger:
	bge	s3, t5, subtract_registers_3RegIsBigger
	add	s3, s3, t1
	addi	s4, s4, -1
subtract_registers_3RegIsBigger:
	# Odejmij kolejne rejestry
	sub	s0, s0, t2	
	sub	s1, s1, t3
	sub	s2, s2, t4
	sub	s3, s3, t5
	sub	s4, s4, t6
	ret


######################################### VALIDITY CHECK #########################################

validity_check:
	la	t6, sNum
validity_check_nextChar:
	lbu	t5, (t6)
	addi	t6, t6, 1
	
	li	t0, ' '
	bltu	t5, t0, finish_program_with_error_BadData
	beqz	t5, finish_program_with_error_BadData
	
	li	t0, '0'
	bne	t5, t0, validity_check_valid
	
	j validity_check_nextChar

validity_check_valid:
	ret
	
#######################################    PRINT RESULT    ######################################
print_result:
	# Zapisz na stosie reszte
	addi	sp, sp, -4	
	sw	s4, (sp)
	addi	sp, sp, -4	
	sw	s3, (sp)
	addi	sp, sp, -4	
	sw	s2, (sp)
	addi	sp, sp, -4	
	sw	s1, (sp)
	addi	sp, sp, -4	
	sw	s0, (sp)
	# Zapisz na stosie iloraz
	addi	sp, sp, -4	
	sw	a6, (sp)
	addi	sp, sp, -4	
	sw	a5, (sp)
	addi	sp, sp, -4	
	sw	a4, (sp)
	addi	sp, sp, -4	
	sw	a3, (sp)
	addi	sp, sp, -4	
	sw	a2, (sp)
	
	# t0 - wskaznik wyjscia ilorazu
	# t1 - wskaznik wyjscia reszty
	# s11 - licznik cyfry
	# t2 - pomocnicza
	# t3 - licznik rejestrow
	la	t0, iloraz
	la	t1, reszta
	addi	t0, t0, 44
	addi	t1, t1, 44
	mv	t3, zero
	mv	s11, zero
	# Ustaw dzieln¹ na 10
	li	s5, 10
	mv	s6, zero
	mv	s7, zero
	mv	s8, zero
	mv	s9, zero
	# Wyzeruj pozosta³e rejestry L1
	mv	s1, zero
	mv	s2, zero
	mv	s3, zero
	mv	s4, zero
	
print_result_MainLoop_Iloraz_NextReg:
	lw	a2, (sp)	
	addi	sp, sp, 4
	mv	s11, zero
		
print_result_MainLoop_Iloraz:
	# Wczytaj iloraz jako L1
	mv	s0, a2
	# Divide L1/10
	mv	t2, ra
	jal	divide
	mv	ra, t2
	# Zapisz reszte na t0
	addi	s0, s0, '0'
	sb	s0, (t0)
	addi	t0, t0, -1
	
	# Dodaj 1 do licznika cyfr
	addi	s11, s11, 1
	li	t2, 9
	bne	s11, t2, print_result_MainLoop_Iloraz
	addi	t3, t3, 1
	li	t2, 5
	bne	t3, t2, print_result_MainLoop_Iloraz_NextReg
	mv	t3, zero
	
print_result_MainLoop_Reszta_NextReg:
	lw	s0, (sp)	
	addi	sp, sp, 4
	mv	s11, zero
print_result_MainLoop_Reszta:
	# Divide L1/10
	mv	t2, ra
	jal	divide
	mv	ra, t2
	# Zapisz reszte na t0
	addi	s0, s0, '0'
	sb	s0, (t1)
	addi	t1, t1, -1
	
	mv	s0, a2
	
	# Dodaj 1 do licznika cyfr
	addi	s11, s11, 1
	li	t2, 9
	bne	s11, t2, print_result_MainLoop_Reszta
	addi	t3, t3, 1
	li	t2, 5
	bne	t3, t2, print_result_MainLoop_Reszta_NextReg

	# WYTNIJ ZERA WIOD¥CE Z WYNIKÓW
	#	t3 - nowy adres ilorazu
	#	t4 - nowy adres reszty
	
	la	t0, iloraz
	mv	t1, ra
	jal	print_result_CutZeros
	mv	ra, t1
	mv	t3, t0
	
	la	t0, reszta
	mv	t1, ra
	jal	print_result_CutZeros
	mv	ra, t1
	mv	t4, t0
	
	# ZACZNIJ WYPISYWAC WYNIKI
	li	a7, Print
	la	a0, mess6
	ecall
	
	# DOPISZ ZNAK
	li	t0, 1
	bne	s10, t0, print_result_DontPrintNegativeSign
	
	li	a7, PrintChar
	li	a0, '-'
	ecall
	
print_result_DontPrintNegativeSign:

	# WYPISZ ZMODYFIKOWANE WYNIKI
	li	a7, Print
	mv	a0, t3
	ecall
	li	a0, ' '
	li	a7, PrintChar
	ecall
	li	a7, Print
	la	a0, mess7
	ecall
	mv	a0, t4
	ecall
	ret
	
print_result_CutZeros:
	# t0, string address in/ret
	# t5, aktualny znak
	# t6, pomocnicza
	# a2, max mozliwych zer do wycieca
	li	a2, 45
print_result_CutZeros_loop:
	lbu	t5, (t0)
	addi	t0, t0, 1
	li	a6, '0'
	addi	a2, a2, -1
	beqz	a2, print_result_finish
	beq	t5, a6, print_result_CutZeros_loop
print_result_finish:
	addi	t0, t0, -1
	ret
	
########################################  OTHER FUNCTIONS  #######################################
ask_for_data:
	# Wprowadzanie Danych
	la	a0, mess0
	li	a7, Print
	ecall
	la	a0, mess1
	ecall
	la	a0, fNum
	li	a1, 46
	li	a7, Read
	ecall
	la	a0, mess2
	li	a7, Print
	ecall
	la	a0, sNum
	li	a1, 46
	li	a7, Read
	ecall
	ret

finish_program_with_error_BadData:
	# Wypisz wynik
	la	a0, mess4		
	li	a7, Print
	ecall
	# Wczytaj rejestry zachowywane
	jal	load_registers
	# Zakoñcz program
	li	a7, Exit
	ecall

load_registers:
	lw	s11, (sp)	
	addi	sp, sp, 4
	lw	s10, (sp)	
	addi	sp, sp, 4
	lw	s9, (sp)	
	addi	sp, sp, 4
	lw	s8, (sp)	
	addi	sp, sp, 4
	lw	s7, (sp)	
	addi	sp, sp, 4
	lw	s6, (sp)	
	addi	sp, sp, 4
	lw	s5, (sp)	
	addi	sp, sp, 4
	lw	s4, (sp)	
	addi	sp, sp, 4
	lw	s3, (sp)	
	addi	sp, sp, 4
	lw	s2, (sp)	
	addi	sp, sp, 4
	lw	s1, (sp)	
	addi	sp, sp, 4
	lw	s0, (sp)	
	addi	sp, sp, 4
	ret
	
save_registers:
	addi	sp, sp, -4	
	sw	s0, (sp)
	addi	sp, sp, -4	
	sw	s1, (sp)
	addi	sp, sp, -4	
	sw	s2, (sp)
	addi	sp, sp, -4	
	sw	s3, (sp)
	addi	sp, sp, -4	
	sw	s4, (sp)
	addi	sp, sp, -4	
	sw	s5, (sp)
	addi	sp, sp, -4	
	sw	s6, (sp)
	addi	sp, sp, -4	
	sw	s7, (sp)
	addi	sp, sp, -4	
	sw	s8, (sp)
	addi	sp, sp, -4	
	sw	s9, (sp)
	addi	sp, sp, -4	
	sw	s10, (sp)
	addi	sp, sp, -4	
	sw	s11, (sp)
	ret

save_pom:
	addi	sp, sp, -4	
	sw	t2, (sp)
	addi	sp, sp, -4	
	sw	t3, (sp)
	addi	sp, sp, -4	
	sw	t4, (sp)
	addi	sp, sp, -4	
	sw	t5, (sp)
	addi	sp, sp, -4	
	sw	t6, (sp)
	ret

load_pom:
	lw	t6, (sp)	
	addi	sp, sp, 4
	lw	t5, (sp)	
	addi	sp, sp, 4
	lw	t4, (sp)	
	addi	sp, sp, 4
	lw	t3, (sp)	
	addi	sp, sp, 4
	lw	t2, (sp)	
	addi	sp, sp, 4
	ret
