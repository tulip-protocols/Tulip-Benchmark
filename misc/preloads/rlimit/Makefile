all: rlimit.so

rlimit.so: rlimit.c
	$(CC) $(CFLAGS) -shared -fPIC $< -o $@ $(LDFLAGS)

clean:
	rm -f rlimit.so


PHONY: all clean
