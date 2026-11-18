all: desock_dup.so

desock_dup.so: desock_dup.c
	$(CC) $(CFLAGS) -shared -fPIC $< -o $@ $(LDFLAGS) -ldl

clean:
	rm -f desock_dup.so


PHONY: all clean
