

READ_SONAR:
	stmfd sp!, {r4-r11, lr}

	cmp r0, #16							@ compara o valor de r0
	bhs read_sonar_invalid_sonar_error	@ se for maior do que 15, trata o erro

	ldr r2, =0x53F84000					@ carregar o DR atual
	ldr r1, [r2]
	
	bic r1, r1, #0x3c					@ Limpa os bits do multiplexador
	orr r1, r1, r0, lsl #2				@ Seta o ID do sonar desejado
	orr r1, r1, #2						@ Seta TRIGGER para 1
@@@@@@@@@@@@@@@@@ Talvez precisa-se dar um delay entre setar o sonar id e o trigger?

	str r1, [r2]						@Enviar o DR tratado de volta

	ldr r2, =0
	ldr r3, =15000
	delay_loop1:
		add r2, r2, #1
		cmp r2, r3
		blt delay_loop1
	fim_delay_loop1:	


	ldr r2, =GPIO_DR					@Carregar o endereco de GPIO DR novamente
	bic r1, r1, #2						@Desativar o trigger (r1 ja tinha o DR passado, nao foi necessario carrega-lo de novo)
	str r1, [r2]						@Enviar o DR tratado de volta

	@ Esperar a flag ser setada:
	ldr r2, =GPIO_DR					@Carregar o endereco de GPIO PSR
	wait_for_flag:
		ldr r1, [r2]					@Carregar o PSR
		and r4, r1, #1					@Pegar apenas o bit de flag
		cmp r4, #1						@Verificar se o bit de flag estava setado
		beq flag_was_set

		ldr r6, =2
		ldr r3, =15000
		delay_loop2:
			add r6, r6, #1
			cmp r6, r3
			blt delay_loop2
		fim_delay_loop2:

			b wait_for_flag
		flag_was_set:

	@ r1 ainda contem o PSR
	ldr r2, =0x3FFC0				
	and r1, r1, r2
	lsr r1, #6

	mov r0, r1

	ldmfd sp!, {r4-r11, lr}

	
	mov pc, lr

read_sonar_invalid_sonar_error:
	ldmfd sp!, {r4}

	mov r0, #-1
	mov pc, lr


REGISTER_PROXIMITY_CALLBACK:
	stmfd sp!, {r4}

	cmp r0, #16
	bhs proximity_invalid_sonar_error	@Caso o sonar seja invalido

	cmp r1, #0x1000
	bhs proximity_invalid_sonar_error	@Caso a distancia seja invalida

	ldr r2, =PROXIMITY_STACK

	ldr r3, =PROXIMITY_COUNTER			@Carregar o numero atual de callbacks
	ldr r3, [r3]						@Achar o endereco do proximo espaco livre
	mov r4, #7
	mul r4, r3, r4
	add r4, r4, #7
	add r4, r4, r2
	strb r0, [r4]						@Guardar 1 byte represetnando o sonar

	add r4, r4, #1
	strh r1, [r4]						@Guardar 2 bytes representando a distancia

	add r4, r4, #2
	str r2, [r4]						@Guardar uma palavra para o poteiro da funcao

	ldr r2, =PROXIMITY_COUNTER
	add r3, r3, #1
	str r3, [r2]

	ldmfd sp!, {r4}

	mov r0, #0
	mov pc, lr

	proximity_invalid_sonar_error:
		ldmfd sp!, {r4}

		mov r0, #-1
		mov pc, lr

	proximity_maxcallbacks_error:
		ldmfd sp!, {r4}

		mov r0, #-2
		mov pc, lr
