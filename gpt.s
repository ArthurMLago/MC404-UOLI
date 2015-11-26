GET_TIME:
	ldr r1, =SYSTEM_TIME				@ poe em r0, o valor do contador
	ldr r0, [r1]

	movs pc, lr

SET_TIME:
	ldr r1, =SYSTEM_TIME
	str r0, [r1]

	movs pc, lr

SET_ALARM:

	stmfd sp!, {r5 - r11}				@ salvando registradores na pilha

	ldr r2, =ALARM_COUNTER				@ poe em r2, o valor do contador de alarmes
	ldr r2, [r2]

	cmp r2, #MAX_ALARMS					@ compara para checar erro
	bgt max_error

	ldr r3, =SYSTEM_TIME				@ poe em r3, o valor do contador
	ldr r3, [r3]

	cmp r3, r1							@compara para checar erro
	blt time_error

	ldr r4, =ALARM_STACK				@ poe em r4 o endereco da pilha de alarmes

	mov r5, #0							@ iterador para o for
	mov r6, r4							@r6 recebe o endereco do inicio da pilha de alarmes

	loop_insercao:						@ loop que encontra onde o novo alarme deve ser inserido na pilha
		cmp r5, r2
		bge fim_loop_insercao

		ldr r7, [r6]						@ r7 guarda o tempo do alarme da pilha
		cmp r1, r7
		bgt ordenacao						@ salto para a funcao que reorganiza a pilha com a insercao do novo alarme

		add r6, r6, #8
		add r5, r5, #1
		b loop_insercao

	fim_loop_insercao: 

		str r1, [r6]					@ Insercao de novo alarme na lista de alarmes
		str r0, [r6, #4]

		ldr r2, =ALARM_COUNTER
		ldr r3, [r2]
		add r3, r3, #1
		str r3, [r2]

		mov pc, lr 

	ordenacao:
		mov r3, #8
		mul r8, r2, r3					@ endereco final da pilha r8 = r4 + contador* 8
		add r8, r8, r4

	loop_reorganizacao:
		cmp r5, r2
		bge fim_loop_reorganizacao

		mov r9, r8						@ r9 guarda o endereco que contem os dados que devem ser transferidos para frente
		sub r9, r9, #8
		ldr r10, [r9]					@r6 guarda o tempo
		ldr r7, [r9, #4]				@r7 guarda o endereco de salto
		str r10, [r8]
		str r7, [r8, #4]
		sub r8, r8, #8

		add r5, r5, #1
		b loop_reorganizacao

	fim_loop_reorganizacao:

		str r1, [r8]					@ insercao do alarme no seu devido luar na pilha
		str r0, [r8, #4]
		mov pc, lr 

	max_error:
		ldmfd sp!, {r5 - r11}
		mov r0, #-1
		mov pc, lr

	time_error:
		ldmfd sp!, {r5 - r11}
		mov r0, #-2
		mov pc, lr

ALARM_HANDLER:
	ldr r0, =ALARM_STACK	@ carrega em r0 o inicio da pilha
	ldr r1, =ALARM_COUNTER	@ carrega em r1 o valor de ALARM_COUNTER
	ldr r1, [r1]
	mov r2, #8				
	mul r2, r2, r1
	add r0, r0, r2			@ poe em r0 o valor do final da pilha
	sub r0, r0, #4			@ poe em r0 o endereco de salto
	ldr r0, [r0]

	ldr r2, =ALARM_COUNTER
	sub r1, r1, #1
	str r1, [r2]


	stmfd sp!, {lr}			@ salva o lr
	bl r0					@ salta para a funcao desejada
	ldmfd sp!, {lr}
	mov pc, lr