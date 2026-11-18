all: desock.so

desock.so: desock.c
	$(CC) $(CFLAGS) -shared -fPIC $< -o $@ $(LDFLAGS) -ldl

clean:
	rm -f desock.so


PHONY: all clean
