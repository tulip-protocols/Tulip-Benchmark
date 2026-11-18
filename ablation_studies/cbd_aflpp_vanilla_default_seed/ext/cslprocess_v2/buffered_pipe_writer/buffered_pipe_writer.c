#include <unistd.h>
#include <fcntl.h>
#include <time.h>
#include <sys/wait.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <signal.h>
#include <sys/stat.h>

int continueWriting = 0;

int argvGetPositionOfEndOfStraceOptions(int argc, char** argv)
{
    int i = 2; // We assume that argv[1] : input

    while ((i < argc) && (strcmp(argv[i], "--") != 0))
    {
        ++i;
    }

    return i;
}

char** straceArgvBuilder(int argc, char** argv, char* ldPreloadEnvVarDefinition)
{
    int positionOfDoubleDashesInArgv;
    char** straceArgv;
    int i;
    pid_t ppid = getppid(); // PPID because here we have forked

    positionOfDoubleDashesInArgv = argvGetPositionOfEndOfStraceOptions(argc, argv);
    straceArgv = malloc((argc + 3) * sizeof(char*));

    straceArgv[0] = "/bin/strace";

    for (i = 2; i < positionOfDoubleDashesInArgv; ++i) // We assume that argv[1] : input
    {
        straceArgv[i - 1] = argv[i];
    }

    straceArgv[i - 1] = "-E";
    straceArgv[i] = ldPreloadEnvVarDefinition;

    straceArgv[i + 1] = "-E";
    straceArgv[i + 2] = malloc(128 * sizeof(char));

    snprintf(straceArgv[i + 2], 128, "BUFFERED_PIPE_WRITER_PID=%d", (int)ppid);

    for (i = (positionOfDoubleDashesInArgv + 1); i < argc; ++i)
    {
        straceArgv[i + 2] = argv[i];
    }

    straceArgv[i + 2] = NULL;

    return straceArgv;
}

void sigcontHandler()
{
    continueWriting = 1;
}

void sigchldHandler()
{
    wait(NULL);
}

int main(int argc, char** argv)
{
    char* buffer;
    int fd;
    ssize_t readBytes;
    ssize_t i = 0;
    pid_t pid;
    int pipeFds[2];
    int pipeResult;
    int pipeFds1Clone;
    char** straceArgv;
    struct sigaction sigcontSigaction = { 0 };
    struct sigaction sigchldSigaction = { 0 }; // A children can quit before the end of the consumption of the file (Eg : QUIT\nsecret)
    struct stat inputFileStat;
    size_t bufferSize;
    char* posLineFeed;
    size_t sizeOfCurrentLine;
    char* ldPreloadEnvVarDefinition = calloc(512, sizeof(char));
    char* underscoreLdPreloadEnv;

    if (argc >= 2)
    {
        fd = open(argv[1], O_RDONLY);

        if (fd != 0)
        {
            fstat(fd, &inputFileStat);

            bufferSize = (inputFileStat.st_size * sizeof(char)) + 1;

            buffer = malloc(bufferSize);
            buffer[bufferSize - 1] = '\0';

            readBytes = read(fd, buffer, bufferSize);
            pipeResult = pipe(pipeFds);

            if (pipeResult != -1)
            {
                pid = fork();

                if (pid == 0) // Children
                {
                    close(pipeFds[1]);
                    dup2(pipeFds[0], 0);

                    underscoreLdPreloadEnv = getenv("_LD_PRELOAD");

                    if (strcmp(argv[0], "buffered_pipe_writer_strace") == 0)
                    {
                        if (underscoreLdPreloadEnv == NULL)
                        {
                            strcpy(ldPreloadEnvVarDefinition, "LD_PRELOAD=/usr/local/lib/buffered_pipe_writer_read_wrapper.so");
                        }
                        else
                        {
                            snprintf(ldPreloadEnvVarDefinition, 512, "LD_PRELOAD=/usr/local/lib/buffered_pipe_writer_read_wrapper.so:%s", underscoreLdPreloadEnv);
                        }

                        straceArgv = straceArgvBuilder(argc, argv, ldPreloadEnvVarDefinition);

                        #ifdef DEBUG

                        for (int p = 0; p < argc + 3; ++p)
                        {
                            printf("%d : %s\n", p, straceArgv[p]);
                        }

                        #endif

                        execvp("/bin/strace", straceArgv);
                    }
                    else if (strcmp(argv[0], "buffered_pipe_writer_strace_i686") == 0)
                    {
                        if (underscoreLdPreloadEnv == NULL)
                        {
                            strcpy(ldPreloadEnvVarDefinition, "LD_PRELOAD=/usr/local/lib/buffered_pipe_writer_read_wrapper_i686.so");
                        }
                        else
                        {
                            snprintf(ldPreloadEnvVarDefinition, 512, "LD_PRELOAD=/usr/local/lib/buffered_pipe_writer_read_wrapper_i686.so:%s", underscoreLdPreloadEnv);
                        }

                        straceArgv = straceArgvBuilder(argc, argv, ldPreloadEnvVarDefinition);

                        #ifdef DEBUG

                        for (int p = 0; p < argc + 3; ++p)
                        {
                            printf("%d : %s\n", p, straceArgv[p]);
                        }

                        #endif

                        execvp("/bin/strace", straceArgv);
                    }
                    else if (strcmp(argv[0], "buffered_pipe_writer_i686") == 0)
                    {
                        if (underscoreLdPreloadEnv == NULL)
                        {
                            strcpy(ldPreloadEnvVarDefinition, "/usr/local/lib/buffered_pipe_writer_read_wrapper_i686.so");
                        }
                        else
                        {
                            snprintf(ldPreloadEnvVarDefinition, 512, "/usr/local/lib/buffered_pipe_writer_read_wrapper_i686.so:%s", underscoreLdPreloadEnv);
                        }

                        setenv("LD_PRELOAD", ldPreloadEnvVarDefinition, 1);
                        execvp(argv[2], argv + 2);
                    }
                    else
                    {
                        if (underscoreLdPreloadEnv == NULL)
                        {
                            strcpy(ldPreloadEnvVarDefinition, "/usr/local/lib/buffered_pipe_writer_read_wrapper.so");
                        }
                        else
                        {
                            snprintf(ldPreloadEnvVarDefinition, 512, "/usr/local/lib/buffered_pipe_writer_read_wrapper.so:%s", underscoreLdPreloadEnv);
                        }

                        setenv("LD_PRELOAD", ldPreloadEnvVarDefinition, 1);
                        execvp(argv[2], argv + 2);
                    }
                }
                else if (pid != -1) // Father
                {
                    sigcontSigaction.sa_handler = sigcontHandler;

                    sigchldSigaction.sa_handler = sigchldHandler;

                    sigaction(SIGCONT, &sigcontSigaction, NULL);
                    sigaction(SIGCHLD, &sigchldSigaction, NULL);

                    close(pipeFds[0]);
                    pipeFds1Clone = dup(pipeFds[1]);

                    while (i < readBytes)
                    {
                        posLineFeed = strchr(buffer, '\n');

                        if (posLineFeed != NULL) // If it is NULL, then this is the end of the input file
                        {
                            *posLineFeed = '\0';
                        }

                        sizeOfCurrentLine = strlen(buffer);

                        write(pipeFds[1], buffer, sizeOfCurrentLine);

                        if (posLineFeed != NULL) // If it is not null, there is a '\n' at the end of the current line
                        {
                            write(pipeFds[1], "\n", 1);

                            ++i;
                        }

                        i += sizeOfCurrentLine;
                        buffer += sizeOfCurrentLine + 1;

                        close(pipeFds[1]);

                        if (continueWriting == 0)
                        {
                            pause();
                        }

                        continueWriting = 0;

                        dup2(pipeFds1Clone, pipeFds[1]);
                    }

                    close(pipeFds[1]);
                    close(pipeFds1Clone);

                    wait(NULL);
                }
            }

            close(fd);
        }
    }

    return 0;
}
