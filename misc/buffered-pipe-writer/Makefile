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

.PHONY: buffered_pipe_writer buffered_pipe_writer_read_wrapper clean

%.o: %.c
	${CC} -c $^ -o $@ ${CC_OPTIONS}

buffered_pipe_writer_read_wrapper.o: buffered_pipe_writer_read_wrapper.c
	${CC} -fPIC -c $^ -o $@ ${CC_OPTIONS}

buffered_pipe_writer_read_wrapper_i686.o: buffered_pipe_writer_read_wrapper.c
	${CC} -m32 -fPIC -c $^ -o $@ ${CC_OPTIONS}

buffered_pipe_writer: buffered_pipe_writer.o
	${LD} ${LD_OPTIONS} $^ -o buffered_pipe_writer

buffered_pipe_writer_read_wrapper.so: buffered_pipe_writer_read_wrapper.o
	${LD} ${LD_OPTIONS} -shared $^ -o buffered_pipe_writer_read_wrapper.so

buffered_pipe_writer_read_wrapper_i686.so: buffered_pipe_writer_read_wrapper_i686.o
	${LD} ${LD_OPTIONS} -m32 -shared $^ -o buffered_pipe_writer_read_wrapper_i686.so

buffered_pipe_writer_strace: buffered_pipe_writer
	ln -sf ./buffered_pipe_writer ./buffered_pipe_writer_strace

buffered_pipe_writer_strace_i686: buffered_pipe_writer
	ln -sf ./buffered_pipe_writer ./buffered_pipe_writer_strace_i686

buffered_pipe_writer_i686: buffered_pipe_writer
	ln -sf ./buffered_pipe_writer ./buffered_pipe_writer_i686

clean:
	rm -f *.o *.so buffered_pipe_writer buffered_pipe_writer_strace buffered_pipe_writer_strace_i686 buffered_pipe_writer_i686

all: buffered_pipe_writer buffered_pipe_writer_read_wrapper.so buffered_pipe_writer_read_wrapper_i686.so buffered_pipe_writer_strace buffered_pipe_writer_strace_i686 buffered_pipe_writer_i686

install: all
	install ./buffered_pipe_writer /usr/local/bin
	install ./buffered_pipe_writer_read_wrapper.so /usr/local/lib
	cp -d ./buffered_pipe_writer_read_wrapper_i686.so /usr/local/lib
	cp -d ./buffered_pipe_writer_strace /usr/local/bin
	cp -d ./buffered_pipe_writer_strace_i686 /usr/local/bin
	cp -d ./buffered_pipe_writer_i686 /usr/local/bin
