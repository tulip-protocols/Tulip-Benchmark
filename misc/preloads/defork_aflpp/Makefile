.PHONY: all clean

all: defork.so

defork.so: defork.c
	$(CC) $(CFLAGS) -D_GNU_SOURCE -shared -fPIC $< -o $@ $(LDFLAGS) -ldl

clean:
	rm -f defork.so