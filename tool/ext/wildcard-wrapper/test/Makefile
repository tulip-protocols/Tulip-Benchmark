CC=gcc
CC_OPTIONS_BASE=-Wall -Wno-unknown-pragmas
SRC=$(wildcard *.c)
OBJ=$(SRC:.c=.o)
OBJ_i386=$(SRC:.c=-i386.o)

ifeq ($(DEBUG), 1)
	CC_OPTIONS=-g $(CC_OPTIONS_BASE)
else
	CC_OPTIONS=$(CC_OPTIONS_BASE)
endif

%.o: %.c
	${CC} -c $^ ${CC_OPTIONS}

%-i386.o: %.c
	${CC} -c -m32 $^ ${CC_OPTIONS} -o $@

main: $(OBJ)
	${CC} $^ ${CC_OPTIONS} -o main

main-wrapper: $(OBJ)
	${CC} ../wrapper_final.o $(OBJ) ${CC_OPTIONS} -o main

main-wrapper-i386: $(OBJ_i386)
	${CC} -m32 ../wrapper_final.o $(OBJ_i386) ${CC_OPTIONS} -o main-i386

clean:
	rm -f main main-i386 *.o
