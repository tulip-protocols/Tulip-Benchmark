#define _GNU_SOURCE

#include <dlfcn.h>
#include <sys/types.h>
#include <sys/stat.h>


#define FAKE_MAX_FDS 11


int (*original_fstat64)(int, struct stat64*);

__attribute__((constructor)) void fstat_shim_constructor(void) {
    original_fstat64 = dlsym(RTLD_NEXT, "fstat64");
}

int fstat64(int fd, struct stat64* statbuf)
{
	if (fd <= 2) {
		statbuf->st_mode |= S_IFSOCK;
		return 0;
	}

	return original_fstat64(fd, statbuf);
}
