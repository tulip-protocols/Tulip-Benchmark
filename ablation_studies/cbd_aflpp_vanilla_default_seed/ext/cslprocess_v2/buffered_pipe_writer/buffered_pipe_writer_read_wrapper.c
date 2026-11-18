#include <stdio.h>
#include <unistd.h>
#include <dlfcn.h>
#include <signal.h>
#include <stdlib.h>

typedef enum wrapped_functions
{
    WRAPPED_FUNCTIONS_NONE = 0b00,
    WRAPPED_FUNCTIONS_READ = 0b01,
    WRAPPED_FUNCTIONS_FGETS = 0b10
} wrapped_functions_t;

wrapped_functions_t wrapped_functions = WRAPPED_FUNCTIONS_NONE;

__attribute__((constructor)) void __init__(void)
{
    char* bufferedPipeWriterWrappedFunctionsEnvContent = getenv("BUFFERED_PIPE_WRITER_WRAPPED_FUNCTIONS");

    if (bufferedPipeWriterWrappedFunctionsEnvContent == NULL)
    {
        wrapped_functions = WRAPPED_FUNCTIONS_READ;
    }
    else
    {
        // TODO
    }
}

ssize_t read(int fd, void* buf, size_t count)
{
    static ssize_t (*realRead)(int, void*, size_t) = NULL;
    static pid_t ppid = -1;
    static char* ppidEnvVar;

    ssize_t result;

    if (realRead == NULL)
    {
        realRead = dlsym(RTLD_NEXT, "read");
    }

    if ((wrapped_functions & WRAPPED_FUNCTIONS_READ) != 0)
    {
        if (ppid == -1)
        {
            ppidEnvVar = getenv("BUFFERED_PIPE_WRITER_PID");

            if (ppidEnvVar != NULL)
            {
                ppid = atoi(ppidEnvVar);
            }
            else
            {
                ppid = getppid();
            }
        }

        result = realRead(fd, buf, count);

        kill(ppid, SIGCONT);
    }
    else
    {
        result = realRead(fd, buf, count);
    }

    return result;
}

char* fgets(char* s, int size, FILE* stream)
{
    static char* (*realFgets)(char*, int, FILE*) = NULL;
    static pid_t ppid = -1;
    static char* ppidEnvVar;
    int killResult;

    char* result;

    if (realFgets == NULL)
    {
        realFgets = dlsym(RTLD_NEXT, "fgets");
    }

    if ((wrapped_functions & WRAPPED_FUNCTIONS_FGETS) != 0)
    {
        if (ppid == -1)
        {
            ppidEnvVar = getenv("BUFFERED_PIPE_WRITER_PID");

            if (ppidEnvVar != NULL)
            {
                ppid = atoi(ppidEnvVar);
            }
            else
            {
                ppid = getppid();
            }
        }

        result = realFgets(s, size, stream);

        killResult = kill(ppid, SIGCONT);

        if (killResult == -1)
        {
            exit(0);
        }
    }
    else
    {
        result = realFgets(s, size, stream);
    }

    return result;
}