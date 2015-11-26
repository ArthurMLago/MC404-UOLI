# ----------------------------------------
# Disciplina: MC404 - 1o semestre de 2015
# Professor: Edson Borin
#
# Descrição: Makefile para o segundo trabalho 
# ----------------------------------------

# ----------------------------------
# SOUL object files -- Add your SOUL object files here 
SOUL_OBJS=SOUL.o 

# ----------------------------------
# Compiling/Assembling/Linking Tools and flags
AS=arm-eabi-as
AS_FLAGS=-g

CC=arm-eabi-gcc
CC_FLAGS=-g

LD=arm-eabi-ld
LD_FLAGS=-g

# ----------------------------------
# Default rule
all: disk.img

# ----------------------------------
# Generic Rules
%.o: %.s motors.s sonares.s gpt.s								
#Mudei aki porque tem varios arquivos, depois faco uma solucao melhor que colocar um *
	$(AS) $(AS_FLAGS) $< -o $@

%.o: %.c
	$(CC) $(CC_FLAGS) -c $< -o $@

# ----------------------------------
# Specific Rules
SOUL.x: $(SOUL_OBJS)
	$(LD) $^ -o $@ $(LD_FLAGS) --section-start=.iv=0x778005e0 -Ttext=0x77800700 -Tdata=0x77801800 -e 0x778005e0

LOCO.x: LOCO.o bico.o
	$(LD) $^ -o $@ $(LD_FLAGS) -Ttext=0x77802000

disk.img: SOUL.x LOCO.x
	mksd.sh --so SOUL.x --user LOCO.x

clean:
	rm -f SOUL.x LOCO.x disk.img *.o