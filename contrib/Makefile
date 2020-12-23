BASE=../../ZestSC1

LDFLAGS = -m32 -L $(BASE)/linux/Lib -m32 -L $(BASE)/linux/Lib/ -lZestSC1 /usr/lib32/libusb-0.1.so.4.4.4
OBJS = program_my_precious.o
CFLAGS = -g -I $(BASE)/Inc -m32 -Wall -Wextra

CROSS_BASE:=/opt/sparc-elf-3.4.4
CROSS_PREFIX:=${CROSS_BASE}/bin/sparc-elf

# Skip over building the FPGA reprogram utility if the ZestSC1 folder is missing
ZESTSC1:=$(shell sh -c "[ -d ${BASE} ] && echo 1")
ifeq (${ZESTSC1},1)
all:	program_my_precious example_program dhrystone
else
all:	example_program dhrystone
endif

# The Dhrystone code performs a 64-bit division in the end
# Extract the relevant object files from libc, and link with JUST them.
_udivdi3.o:
	{ ar xv ${CROSS_BASE}/lib/gcc/sparc-elf/3.4.4*/v8/libgcc.a _udivdi3.o _clz.o ; } || exit 0

program_my_precious:	program_my_precious.o
	${CC} -o $@ $< ${LDFLAGS}

dhrystone-common:	dhrystone
	${CROSS_PREFIX}-strip $<
	${CROSS_PREFIX}-size $<

dhrystone:	dhrystone.c my_printf.c
	${CROSS_PREFIX}-gcc -mv8 -O2 -DMAIN=main -o $@ $^ -lsmall
	$(MAKE) dhrystone-common

dhrystone-small:	dhrystone.c my_printf.c | _udivdi3.o
	${CROSS_PREFIX}-gcc -nostdlib -mcpu=v8 -O2 -DMAIN=start -o $@ $^ _udivdi3.o _clz.o
	mv $@ dhrystone
	$(MAKE) dhrystone-common

dhrystone-run:	dhrystone
	bash -c '/opt/grmon-eval-3.2.10/linux/bin64/grmon -u -xilusb -c <(echo -e "load dhrystone\nrun\nquit\n")'

example_program:	example_program.c my_printf.c
	${CROSS_PREFIX}-gcc -mv8 -Os -DMAIN=main -o $@ $^ -lsmall
	# ${CROSS_PREFIX}-gcc -nostdlib -mcpu=v8 -O2 -DMAIN=start -o $@ $^
	${CROSS_PREFIX}-strip $@
	${CROSS_PREFIX}-size $@

mand:	mand.c
	${CROSS_PREFIX}-gcc -mv8 -O2 -msoft-float -o $@ $^ -lsmall
	${CROSS_PREFIX}-strip $@
	${CROSS_PREFIX}-size $@

mand-run:	mand
	bash -c '/opt/grmon-eval-3.2.10/linux/bin64/grmon -u -xilusb -c <(echo -e "load mand\nrun\nquit\n")'

%.o:	%.c
	${CC} -c ${CFLAGS} -o $@ $<

clean:
	rm -f program_my_precious program_my_precious.o example_program dhrystone _clz.o _udivdi3.o mand
