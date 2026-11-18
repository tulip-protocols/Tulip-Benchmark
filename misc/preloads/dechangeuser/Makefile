.PHONY: all clean

all: dechangeuser.so

dechangeuser.so: dechangeuser.c
	$(CC) $(CFLAGS) -D_GNU_SOURCE -shared -fPIC $< -o $@ $(LDFLAGS) -ldl

clean:
	rm -f dechangeuser.so