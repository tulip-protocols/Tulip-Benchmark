.PHONY: all clean

all: depselect.so

depselect.so: depselect.c
	$(CC) $(CFLAGS) -D_GNU_SOURCE -shared -fPIC $< -o $@ $(LDFLAGS) -ldl

clean:
	rm -f depselect.so