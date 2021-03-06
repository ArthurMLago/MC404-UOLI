@Constantes para os enderecos do TZIC
.set TZIC_BASE,				0x0FFFC000
.set TZIC_INTCTRL,			0x0
.set TZIC_INTSEC1,			0x84
.set TZIC_ENSET1,			0x104
.set TZIC_PRIOMASK,			0xC
.set TZIC_PRIORITY9,		0x424

@Constantes para os enderecos do GPT
.set GPT_CR,				0x53FA0000
.set GPT_PR,				0x53FA0004
.set GPT_SR,				0x53FA0008
.set GPT_IR,				0x53FA000C
.set GPT_OCR1,				0x53FA0010

@Constantes para os enderecos do GPIO
.set GPIO_DR,				0x53F84000
.set GPIO_GDIR,				0x53F84004
.SET GPIO_PSR,				0x53F84008

@ Constantes para as regioes de memoria
.set SYSTEM_STACK,			0x778018AA
.set SUPERVISOR_STACK,		0x77801AEA
.set IRQ_STACK,				0x77801D2A

@ Constante para os alarmes
.set MAX_ALARMS, 			0x00000008
.set TIME_SZ,				5000

.org 0x0
.section .iv, "a"

_start:

interrupt_vector:
	b RESET_HANDLER
.org 0x08
	b SVC_HANDLER 
.org 0x18
	b IRQ_HANDLER


.org 0x100
.text


RESET_HANDLER:

	ldr r2, =SYSTEM_TIME
	mov r0, #0
	str r0, [r2]

	ldr r0, =interrupt_vector
	mcr p15, 0, r0, c12, c0, 0

SET_GPIO:
	ldr r0, = 0xFFFC003E
	ldr r1, = GPIO_GDIR
	str r0, [r1]

SET_TZIC:
	@ Liga o controlador de interrupcoes
	@ R1 <= TZIC_BASE

	ldr r1, =TZIC_BASE

	@ Configura interrupcao 39 do GPT como nao segura
	mov r0, #(1 << 7)
	str r0, [r1, #TZIC_INTSEC1]

	@ Habilita interrupcao 39 (GPT)
	@ reg1 bit 7 (gpt)

	mov r0, #(1 << 7)
	str r0, [r1, #TZIC_ENSET1]

	@ Configure interrupt39 priority as 1
	@ reg9, byte 3

	ldr r0, [r1, #TZIC_PRIORITY9]
	bic r0, r0, #0xFF000000
	mov r2, #1
	orr r0, r0, r2, lsl #24
	str r0, [r1, #TZIC_PRIORITY9]

	@ Configure PRIOMASK as 0
	eor r0, r0, r0
	str r0, [r1, #TZIC_PRIOMASK]

	@ Habilita o controlador de interrupcoes
	mov r0, #1
	str r0, [r1, #TZIC_INTCTRL]

	@instrucao msr - habilita interrupcoes
	msr  CPSR_c, #0x13					@ SUPERVISOR mode, IRQ/FIQ enabled
	
SET_GPT:
	ldr r0, =GPT_CR
	mov r1, #0x41
	str r1, [r0]

	ldr r0, =GPT_PR
	mov r1, #0
	str r1, [r0]

	ldr r0, =GPT_OCR1
	ldr r1, =TIME_SZ
	str r1, [r0]

	ldr r0, =GPT_IR
	mov r1, #1
	str r1, [r0]

SET_STACKS:
	ldr r0, =SYSTEM_STACK				@ inicializa a pilha deste modo
	msr CPSR_c, #0x1F					@ poe o processador no modo system
	mov sp, r0

	ldr r0, = SUPERVISOR_STACK			@ inicializa a pilha deste modo
	msr CPSR_c, #0x13					@ poe o processador no modo supervisor
	mov sp, r0

	ldr r0, = IRQ_STACK					@ inicializa a pilha deste modo
	msr CPSR_c, #0x12					@ poe o processador no modo IRQ
	mov sp, r0

	@Nao precisamos setar a pilha do usuario pois eh a mesma pilha do system

GO_TO_USER_PROGRAM:
	msr CPSR_c, #0x10
	ldr r1, =0x77802000
	mov pc, r1

SVC_HANDLER:

	stmfd sp!, {lr}

	cmp r7, #7
	beq ALARM_END_CALLBACK

	cmp r7, #8
	beq PROXIMITY_END_CALLBACK

	cmp r7, #16
	bleq READ_SONAR

	cmp r7, #17
	bleq REGISTER_PROXIMITY_CALLBACK

	cmp r7, #18
	bleq SET_MOTOR_SPEED

	cmp r7, #19
	bleq SET_MOTORS_SPEED

	cmp r7, #20
	bleq GET_TIME

	cmp r7, #21
	bleq SET_TIME

	cmp r7, #22
	bleq SET_ALARM

	ldmfd sp!, {lr}

	movs pc, lr

	ALARM_END_CALLBACK:
		ldmfd sp!, {lr}
		msr CPSR_c, #0x12					@ poe o processador no modo IRQ
		b ALARM_COMEBACK_IRQ

	PROXIMITY_END_CALLBACK:
		ldmfd sp!, {lr}
		msr CPSR_c, #0x12					@ poe o processador no modo IRQ
		b PROXIMITY_COMEBACK_IRQ
	
	
IRQ_HANDLER:

	stmfd sp!, {r0-r11}

	ldr r0, =GPT_SR
	mov r1, #1

	str r1, [r0]

	ldr r0, =SYSTEM_TIME
	ldr r1, [r0]					@ r1 contem o valor de SYSTEM_TIME
	add r1, r1, #1					@ incrementando o tempo
	str r1, [r0]

	@Verificar se algum alarme foi atingido:
	ldr r2, =ALARM_STACK			@ carrega em r2 o inicio da pilha
	ldr r3, =ALARM_COUNTER			@ carrega em r3 o valor de ALARM_COUNTER
	ldr r3, [r3]

	cmp r3, #0						@Se nao existirem alarmas para serem procurados, pular o alarm handler:
	beq skip_alarm_handler

	mov r4, #8		
	mul r4, r3, r4
	add r2, r2, r4					@ poe em r2 o valor do final da pilha
	sub r2, r2, #8					@ poe em r2 o endereco de salto
	ldr r2, [r2]

	cmp r2, r1

	stmfd sp!, {lr}					@Salvar o LR

	blls ALARM_HANDLER

	ldmfd sp!, {lr}	

	skip_alarm_handler:

	@De meio em meio segundo, testar os sonares que tem callbacks registrados:
	ldr r0, =SYSTEM_TIME
	ldr r0, [r0]

	ldr r2, =LAST_SONAR_CHECK
	ldr r1, [r2]
	add r1, r1, #15

	cmp r0, r1
	blo skip_sonar_check				

	ldr r0, =PROXIMITY_COUNTER	@Para nao dar erro quando nao houverem callbacks
	ldr r0, [r0]
	cmp r0, #0
	beq will_end_sonar_check

	mov r4, #0
	ldr r3, =PROXIMITY_STACK		@Carregar o inicio da lista de callbacks


	check_proximity_sonars:

		ldrb r0, [r3]				@Carregar o ID do sonar e ler seu valor

		stmfd sp!, {r1-r3,lr}


		bl READ_SONAR

		ldmfd sp!, {r1-r3,lr}

		add r3, r3, #4				@Carregar a distancia desejada
		ldr r1, [r3]

		add r3, r3, #4				@Carrega o endereco do callback
		ldr r2, [r3]

		cmp r0, r1					@Se a distancia lida for menor que a distancia desejada, pular para o callback
		bhi check_for_more_sonars

		@Caso tenha atingido a distancia:
		stmfd sp!, {r0-r3,lr}

		msr CPSR_c, #0x10			@Muda para modo usuario para executar o callnack
		blx r2						@Pular para o callback
		mov r7, #8					@syscall para sair do modo usuario
		svc #0
			PROXIMITY_COMEBACK_IRQ:		@Após a syscall para voltsr ao modo de usuario voltar aqui

		ldmfd sp!, {r0-r3,lr}

		check_for_more_sonars:
			add r3, r3, #4				@Pular para o proximo elemento da lista de callbacks
			add r4, r4, #1				@Contagem de sonares checados eh incrementada
			ldr r1, =PROXIMITY_COUNTER	@Carregar o numero de elementos da lista de callbacks
			ldr r1, [r1]
			cmp r4, r1					@Se ainda nao foram checados todos os callbacks, continua no loop:
			blt check_proximity_sonars


	will_end_sonar_check:
		ldr r0, =SYSTEM_TIME		@Guardar o tempo da ultima vez que os sonares foram checados
		ldr r0, [r0]
		ldr r1, =LAST_SONAR_CHECK
		str r0, [r1]		

	skip_sonar_check:

	ldmfd sp!, {r0-r11}

	sub lr, lr, #4						@Termina interrupcao
	movs pc, lr

.include "gpt.s"
.include "sonares.s"
.include "motors.s"

.data
SYSTEM_TIME:
	.word 0
ALARM_COUNTER:
	.word 0
ALARM_STACK:
	.fill 64
PROXIMITY_COUNTER:
	.word 0
PROXIMITY_STACK:
	.fill 96
LAST_SONAR_CHECK:
	.word 0
