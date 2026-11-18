#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

pid_t (*real_fork)(void);

__attribute__((constructor)) void __defork_init(void)
{
    real_fork = dlsym(RTLD_NEXT, "fork");
}

pid_t fork(void)
{
    if (getenv("AFL_I_AM_THE_FORKSERVER") == NULL)
    {
        fprintf(stderr, "AFL_I_AM_THE_FORKSERVER=false\n");
        fprintf(stderr, "Fork blocked\n");

        return 0;
    }
    else
    {
        fprintf(stderr, "AFL_I_AM_THE_FORKSERVER=true\n");

        return real_fork();
    }
}