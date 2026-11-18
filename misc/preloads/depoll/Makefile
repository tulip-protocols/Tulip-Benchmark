.PHONY: all clean

all: depoll.so

depoll.so: depoll.c
	$(CC) $(CFLAGS) -D_GNU_SOURCE -shared -fPIC $< -o $@ $(LDFLAGS) -ldl

clean:
	rm -f depoll.so