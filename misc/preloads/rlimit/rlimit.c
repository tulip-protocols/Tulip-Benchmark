#define _GNU_SOURCE

#include <dlfcn.h>
#include <sys/time.h>
#include <sys/resource.h>


#define FAKE_MAX_FDS 11


// Original getrlimit().
int (*original_getrlimit)(__rlimit_resource_t resource, struct rlimit *rlim);

__attribute__((constructor)) void rlimit_shim_constructor(void) {
    original_getrlimit = dlsym(RTLD_NEXT, "getrlimit");
}


int getdtablesize(void) {
    return FAKE_MAX_FDS;
}


int getrlimit(__rlimit_resource_t resource, struct rlimit *rlim) {
    if (resource == RLIMIT_NOFILE)
        return FAKE_MAX_FDS;

    return getrlimit(resource, rlim);
}
