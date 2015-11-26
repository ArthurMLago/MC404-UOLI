

@Precisamos setar o motor write em algum lugar bem cedo!

SET_MOTOR_SPEED:
	cmp r0, #1				@Comparar o registrador r0
	bgt invalid_motor_id	@Se for maior que 1, trata erro, ID invalido
	beq will_set_motor_1	@Se for igual a 1, vai para o trecho que altera motor 1

	cmp r1, #0x40			@Se a velocidade for maior ou igual que 64
	bhs invalid_speed

	@Trecho para mudar velocidade do motor 0:
	will_set_motor_0:
		ldr r2, =GPIO_DR		@Carregar o DR atual
		ldr r3, [r2]

		bic r3, #0x1F80000		@Limpa os bits do motor que sera alterado
		orr r3, r1, lsl #19		@Seta os bits da velocidade

		str r3, [r2]			@Manda o novo DR para a memória
		
		mov r0, #0				@Seta r0 como o valor de retorno definido
		mov pc, lr				@Fim do tratamento da interrupcao

	@Trecho para mudar velocidade do motor 1:
	will_set_motor_1:
		ldr r2, =GPIO_DR		@Carregar o DR atual
		ldr r3, [r2]

		bic r3, #0xfc000000		@Limpa os bits do motor que sera alterado
		orr r3, r1, lsl #26		@Seta os bits da velocidade

		str r3, [r2]			@Manda o novo DR para a memória

		mov r0, #0				@Seta r0 como o valor de retorno definido
		mov pc, lr				@Fim do tratamento da interrupcao

	invalid_motor_id:
		mov r1, #-1
		mov pc, lr				@Fim do tratamento da interrupcao

	invalid_speed:
		mov r1, #-2
		mov pc, lr				@Fim do tratamento da interrupcao


SET_MOTORS_SPEED:
	cmp r0, #0x40			@Se a velocidade tiver o sétimo bit setado, ou maior, erro
	bhs invalid_speed_m0

	cmp r1, #0x40
	bhs invalid_speed_m1

	ldr r2, =GPIO_DR		@Carregar o DR atual
	ldr r3, [r2]

	bic r3, #0x1F80000		@Limpa os bits do motor 0
	orr r3, r0, lsl #19		@Seta os bits da velocidade do motor 0

	bic r3, #0xfc000000		@Limpa os bits do motor 1
	orr r3, r1, lsl #26		@Seta os bits da velocidade do motor 1

	str r3, [r2]			@Manda o novo DR para a memória

	mov r0, #0				@Seta r0 como o valor de retorno definido
	mov pc, lr				@Fim do tratamento da interrupcao

	invalid_speed_m0:
		mov r0, #-1				@Seta r0 como o valor de retorno definido
		mov pc, lr				@Fim do tratamento da interrupcao

	invalid_speed_m1:
		mov r0, #-2				@Seta r0 como o valor de retorno definido
		mov pc, lr				@Fim do tratamento da interrupcao
		