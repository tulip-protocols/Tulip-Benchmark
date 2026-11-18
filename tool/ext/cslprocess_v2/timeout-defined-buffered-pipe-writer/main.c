#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>

void usage(char* program_name)
{
    if (strcmp(program_name, "timeout_defined_buffered_pipe_writer") == 0)
    {
        printf("./timeout_defined_buffered_pipe_writer <input> <program invocation...>\n");
        printf("For example, <program invocation...> can be \"cat toto\"\n");
    }
    else if (strcmp(program_name, "timeout_defined_buffered_pipe_writer_strace") == 0)
    {
        printf("./timeout_defined_buffered_pipe_writer <input> <strace options...> -- <program invocation...>\n");
        printf("For example, <program invocation...> can be \"cat toto\"\n");
    }
}

int main(int argc, char** argv)
{
    FILE *input_fd;
    FILE *strace_proc_pipe;
    char line[4096];
    char command[4096];
    struct timespec time_spec = { .tv_sec = 0, .tv_nsec = 40000000 };
    char program_invocation[2048];
    char strace_args[1024];
    int i;
    char* ld_preload_content;
    int double_dash_position;

    if (argc >= 3)
    {
        input_fd = fopen(argv[1], "r");

        if (input_fd != NULL)
        {
            ld_preload_content = getenv("_LD_PRELOAD");

            if (strcmp(argv[0], "timeout_defined_buffered_pipe_writer") == 0)
            {
                if (ld_preload_content != NULL)
                {
                    sprintf(command, "/bin/bash -c \"LD_PRELOAD=%s %s\"", getenv("_LD_PRELOAD"), program_invocation);
                }
                else
                {
                    sprintf(command, "/bin/bash -c \"%s\"", program_invocation);
                }

                for (i = 2; i < argc; ++i)
                {
                    if (i == 2)
                    {
                        strcpy(program_invocation, argv[2]);
                    }
                    else
                    {
                        strcat(program_invocation, " ");
                        strcat(program_invocation, argv[i]);
                    }
                }
            }
            else if (strcmp(argv[0], "timeout_defined_buffered_pipe_writer_strace") == 0)
            {
                i = 2;

                while ((i < argc) && (strcmp(argv[i], "--") != 0))
                {
                    if (i == 2)
                    {
                        strcpy(strace_args, argv[i]);
                    }
                    else
                    {
                        strcat(strace_args, " ");
                        strcat(strace_args, argv[i]);
                    }

                    ++i;
                }

                i++; // To skip the "--"
                double_dash_position = i;

                while (i < argc)
                {
                    if (i == double_dash_position)
                    {
                        strcpy(program_invocation, argv[i]);
                    }
                    else
                    {
                        strcat(program_invocation, " ");
                        strcat(program_invocation, argv[i]);
                    }

                    ++i;
                }

                sprintf(command, "/bin/bash -c \"strace %s -- %s\"", strace_args, program_invocation);
            }

            strace_proc_pipe = popen(command, "w");

            if (strace_proc_pipe != NULL)
            {
                while (fgets(line, sizeof(line), input_fd))
                {
                    fputs(line, strace_proc_pipe);
                    fflush(strace_proc_pipe);
                    nanosleep(&time_spec, 0);
                }

                fclose(input_fd);
                pclose(strace_proc_pipe);
            }
            else
            {
                printf("Unable to spawn bash with strace\n");
            }
        }
        else
        {
            printf("Unable to open %s\n", argv[1]);
        }
    }
    else
    {
        usage(argv[0]);
    }

    return 0;
}