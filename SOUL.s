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

@ Constante para os alarmes
.set MAX_ALARMS, 			0x00000008

@ Constantes para as regioes de memoria
.set SYSTEM_STACK,			0x77801000
.set SUPERVISOR_STACK,		0x77801200
.set IRQ_STACK,				0x77801400
.set USER_STACK,			0x77801600

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

	ldr r2, =SYSTEM_TIME
	mov r0, #0
	str r0, [r2]

RESET_HANDLER:

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
	mov r1, #100
	str r1, [r0]

	ldr r0, =GPT_IR
	mov r1, #1
	str r1, [r0]

SET_STACKS:

	msr CPSR_c, #0b1111					@ poe o processador no modo system
	ldr r0, = SYSTEM_STACK				@ inicializa a pilha deste modo
	mov sp, r0

	msr CPSR_c, #0b10011				@ poe o processador no modo supervisor
	ldr r0, = SUPERVISOR_STACK			@ inicializa a pilha deste modo
	mov sp, r0

	msr CPSR_c, #0b10010				@ poe o processador no modo IRQ
	ldr r0, = IRQ_STACK					@ inicializa a pilha deste modo
	mov sp, r0

	msr CPSR_c, #0b10000				@ poe o processador no modo user
	ldr r0, = USER_STACK				@ inicializa a pilha deste modo
	mov sp, r0

SVC_HANDLER:

	cmp r7, #16
	bleq READ_SONAR
	movs pc, lr

	cmp r7, #17
	bleq REGISTER_PROXIMITY_CALLBACK
	movs pc, lr

	cmp r7, #18
	bleq SET_MOTOR_SPEED
	movs pc, lr

	cmp r7, #19
	bleq SET_MOTORS_SPEED
	movs pc, lr

	cmp r7, #20
	bleq GET_TIME
	movs pc, lr

	cmp r7, #21
	bleq SET_TIME
	movs pc, lr

	cmp r7, #22
	bleq SET_ALARM
	movs pc, lr
	
	
IRQ_HANDLER:

	stmfd sp!, {r4-r11}

	ldr r0, =GPT_SR
	mov r1, #1
	str r1, [r0]

	ldr r0, =SYSTEM_TIME
	ldr r1, [r0]			@ r1 contem o valor de SYSTEM_TIME
	add r1, r1, #1			@ incrementando o tempo
	str r1, [r0]

	ldr r2, =ALARM_STACK	@ carrega em r2 o inicio da pilha
	ldr r3, =ALARM_COUNTER	@ carrega em r3 o valor de ALARM_COUNTER
	ldr r3, [r3]
	mov r4, #8				
	mul r4, r4, r3
	add r2, r2, r4			@ poe em r2 o valor do final da pilha
	sub r2, r2, #8			@ poe em r2 o endereco de salto
	ldr r2, [r2]

	cmp r2, r1
	ble ALARM_HANDLER

	ldmfd sp!, {r4-r11}

	sub lr, lr, #4
	mov pc, lr

.include "gpt.s"
.include "sonares.s"
.include "motors.s"

.data
SYSTEM_FLAGS:
	.word 0x0
SYSTEM_TIME: 
	.word 0
ALARM_COUNTER:
	.word 0
ALARM_STACK:
	.fill 64
PROXIMITY_COUNTER:
	.word 0
PROXIMITY_STACK:
	.fill 56
