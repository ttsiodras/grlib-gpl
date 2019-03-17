BASE=../../ZestSC1

LDFLAGS = -m32 -L $(BASE)/linux/Lib -m32 -L $(BASE)/linux/Lib/ -lZestSC1 /usr/lib32/libusb-0.1.so.4.4.4
OBJS = program_my_precious.o
CFLAGS = -g -I $(BASE)/Inc -m32 -Wall -Wextra

all:	program_my_precious example_program

program_my_precious:	program_my_precious.o
	${CC} -o $@ $< ${LDFLAGS}

example_program:	example_program.c my_printf.c
	/opt/sparc-elf-3.4.4/bin/sparc-elf-gcc -mv8 -Os -o $@ $^ -lsmall
	/opt/sparc-elf-3.4.4/bin/sparc-elf-strip $@
	/opt/sparc-elf-3.4.4/bin/sparc-elf-size $@

%.o:	%.c
	${CC} -c ${CFLAGS} -o $@ $<

clean:
	rm -f program_my_precious program_my_precious.o example_program
