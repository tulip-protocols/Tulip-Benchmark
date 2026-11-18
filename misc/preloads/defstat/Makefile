all: defstat.so

defstat.so: defstat.c
	$(CC) $(CFLAGS) -shared -fPIC $< -o $@ $(LDFLAGS)

clean:
	rm -f defstat.so


PHONY: all clean
