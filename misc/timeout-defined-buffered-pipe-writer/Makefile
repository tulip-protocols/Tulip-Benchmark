CC=gcc
LD=gcc
CC_OPTIONS_BASE=-D_GNU_SOURCE -Wall -Wextra -Wno-unknown-pragmas -Werror
LD_OPTIONS=
SRC=$(wildcard *.c)
OBJ=$(SRC:.c=.o)

ifeq ($(DEBUG), 1)
	CC_OPTIONS=-DDEBUG -g $(CC_OPTIONS_BASE)
else
	CC_OPTIONS=$(CC_OPTIONS_BASE)
endif

.PHONY: all clean install

%.o: %.c
	${CC} -c $^ -o $@ ${CC_OPTIONS}

timeout_defined_buffered_pipe_writer: main.o
	${LD} ${LD_OPTIONS} $^ -o timeout_defined_buffered_pipe_writer

timeout_defined_buffered_pipe_writer_strace: timeout_defined_buffered_pipe_writer
	ln -sf ./timeout_defined_buffered_pipe_writer ./timeout_defined_buffered_pipe_writer_strace

all: timeout_defined_buffered_pipe_writer timeout_defined_buffered_pipe_writer_strace

clean:
	rm -f *.o timeout_defined_buffered_pipe_writer

install:
	install ./timeout_defined_buffered_pipe_writer /usr/local/bin
	cp -d ./timeout_defined_buffered_pipe_writer_strace /usr/local/bin