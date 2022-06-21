# OPIS RADA - Primjer
#
# BOJE: Crvena, žuta, zelena, plava
# TEKST: test3582
#
# 1. dio: t(c) e(ž) s(z) t(p) 3(c) 5(ž) 8(z) 2(plava)
# 2. dio: t(p) e(c) s(ž) t(z) 3(p) 5(c) 8(ž) 2(z)
# 3. dio: t(z) e(p) s(c) t(ž) 3(z) 5(p) 8(c) 2(ž)
# 4. dio: t(ž)....
#
# Svaki put kada dođemo do null terminatora, trebamo pomaknut
# početak sekvence za jedan. To je dovoljno za jednostavan alg.


.section .data

	.equ	COLOR_NUM, 5
	color:
		.ascii "\x1b[31m\x1b[33m\x1b[32m\x1b[34m\x1b[35m\0"
	color_end:

	text_start:
		.ascii "TestTest321\n\0"
	text_end:

	timespec:
		.long 0
		.long 70000000


.equ LINUX_SYSCALL,	0x80
.equ SYS_READ,	3
.equ SYS_WRITE, 4
.equ SYS_EXIT,	1
.equ STDIN,	0
.equ STDOUT,	1
.equ STDERR,	2

# Stack stuff
.equ ST_ARGV_0, 4	# Ime programa
.equ ST_ARGV_1, 8	# String korisnika

.section .text
.globl _start

_start:
	# OPIS: Prolazi escape sekvencu po sekvncu po pomako po jednu sekvcenu
	#	kako bi se ostvario "rainbow" efekt
	#
	# REGISTRI:
	#	%ecx - pozicija u color sekvenci
	#	%edx - pozicija glavnog teksta
	#	%edi - brojač sekvence
	#

	movl	%esp, %ebp	# Stavimo %esp u %ebp
				# Da imamo bar neki bazni okvir za vračanje

	movl	$color, %ecx		# Adresa arraya escape sekvence
	#movl	ST_ARGV_1(%ebp), %edx	# Adresa početka glavnog teksta
	movl	$text_start, %edx
	movl	$0, %edi		# Brojač sekvence
	color_loop:
		cmpl	$0, (%edx)
		je	text_pointer_reset	# Ako smo došli do kraja teksta, postavljamo
						# pokazivać na početak stringa (za loop)
		pushl	%ecx	# Spremanje vrijednosti registara na stog
		pushl	%edi
		pushl	%edx

		print_escapeseq:
			pushl	$5
			pushl   %ecx
                        pushl   $STDOUT
                        call    print		# Ispis sekvence za promjenu boje (5 bajta)
			addl	$12, %esp

			popl	%edx	# vratimo %edx koji sadrži poziciju glavnog
			pushl	%edx	# teksta i odmah ga stavimo opet na stog
		print_text_char:
			pushl	$1
			pushl	%edx
			pushl   $STDOUT
			call	print	# Poziv Print funkcije sa pointerom koji pokazuje
					# na sljedeći bajt glavnog teksta
			addl	$12, %esp

		popl	%edx	# Vračanje vrijednosti registara
		popl	%edi
		popl	%ecx

		incl	%edx		# Povečamo pokazivać teksta za jedan bajt (slovo)

                cmpl    $32, (%edx)     # Ako je char 32 (space), ne povećavamo %ecx
                je      jmp_loop
		addl	$5, %ecx	# Inače povečamo pokazivaća arraya sekvence za 5
					# (da pokazuje na slj. sekvencu)
		cmpl	$color_end-1, %ecx
		je	seq_counter_reset	# Ako smo došli do kraja arraya sekvenca,
						# Trebamo resetirat i postavit pokazivać na početak
		jmp_loop:
			jmp	color_loop

		text_pointer_reset:
			go_sleep:
				pushal		# Spremanje vrijednosti registara na stog
				call	sleep
				popal		# Vračanje vrijednosti registara
				
			#movl	ST_ARGV_1(%ebp), %edx	# Posstavimo ponovno pokazivač na
			movl    $text_start, %edx	# početak teksta

			cmpl	$COLOR_NUM, %edi	# Ako smo došli do kraja brojača (%edi),
			jne	color_arih		# tada ga resetiramo
							# On gleda koliko smo puta pogodili null
							# terminator i napravili arih. za postavljanje
							# pokazivača na pravilnu sekvencu kada ponovno
							# ispisujemo tekst
			movl	$0, %edi
			color_arih:
				movl    $COLOR_NUM-1, %eax
                        	subl    %edi, %eax
				imul	$5, %eax

				movl	$color, %ecx
                        	addl    %eax, %ecx

                        	incl    %edi    # Povečamo brojać loopa sekvence za jedan
			jmp color_loop
		seq_counter_reset:
			movl	$color, %ecx
			jmp	color_loop

	program_end:
		movl	$SYS_EXIT, %eax
		movl	$0, %ebx
		int	$LINUX_SYSCALL	# Izlaz iz programa



# OPIS: PISE ODREDEN BROJ SLOVA U DAN FD
#	ILI DOK NIJE POGODENA 0
#
#
# PARAMETRI:
#	1. Parametar 1 - FD 			<-- 8(%ebp)
#	2. Parametar 2 - Adresa podatka		<-- 12(%ebp)
#	3. Parametar 3 - Broj ispisa znakova	<-- 16(%ebp)
# VRACA: BROJ UPISANIH BAJTA
#
# REGISTRI:
#	%ebx	-	FD (aka. parametar 1)
#	%ecx	-	Adresa podataka (aka. par. 2)
#	%edi	-	Broj znakova za ispisat (aka. par 3)
#
print:
	pushl	%ebp		# Izrada okvira stoga
	movl	%esp, %ebp

	# Spremanje parametra u reg.
	movl	8(%ebp), %ebx
	movl	12(%ebp), %ecx
	movl	16(%ebp), %edi
	movl	$1, %edx	# Stavimo da se piše jedno slovo
				# da ne moramo pisat stalno u petlji

	print_loop:
		is_index_zero:
			cmpl	$0, %edi
			je	print_end
		is_char_zero:
			cmpl	$0, (%ecx)
			je	print_end
		movl	$SYS_WRITE, %eax
		movl	$1, %edx
		int	$LINUX_SYSCALL
		decl	%edi	# Smanjimo brojac
		incl	%ecx	# Povecamo adresu lokacije podataka
		jmp print_loop

	print_end:
		movl	%ebp, %esp
		popl	%ebp
		ret


sleep:
	pushl 	%ebp
	movl 	%esp, %ebp

	movl	$0xa2, %eax
	movl	$timespec, %ebx
	movl	$0, %ecx
	int	$LINUX_SYSCALL

	movl	%ebp, %esp
	popl	%ebp
	ret
