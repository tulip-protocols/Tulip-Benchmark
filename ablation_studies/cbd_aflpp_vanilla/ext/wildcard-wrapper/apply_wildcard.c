#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "wrapper_internals.h"

void readGeneratedData(char* generatedDataPath, char* destination, size_t sizeOfDestination)
{
    int generatedDataFd = open(generatedDataPath, O_RDONLY);

    read(generatedDataFd, destination, sizeOfDestination);

    close(generatedDataFd);
}

void usage()
{
    printf("Usage : ./apply_wildcard <wildcard_file> <afl++_generated_data>\n");
}

int main(int argc, char** argv)
{
    char* wildcardPath;
    char* generatedDataPath;
    char* wildcardContent;
    struct wildcard* parsedWildcard;
    char result[MAX_STRING_SIZE];
    char generatedData[MAX_STRING_SIZE];

    if (argc == 3)
    {
        wildcardPath = argv[1];
        generatedDataPath = argv[2];

        wildcardContent = readWildcard(wildcardPath, read);

        if (strlen(wildcardContent) != 0)
        {
            readGeneratedData(generatedDataPath, generatedData, MAX_STRING_SIZE);

            if (strlen(generatedData) != 0)
            {
                parsedWildcard = parseWildcard(wildcardContent, wildcardPath);

                strReset(result, MAX_STRING_SIZE);
                strncpy(result, generatedData, MAX_STRING_SIZE);

                fillWildcard(result, MAX_STRING_SIZE, parsedWildcard, NULL);

                printf("%s", result);
            }
            else
            {
                printf("\n");

                fprintf(stderr, "Erreur dans la lecture du fichier %s.\n", generatedDataPath);
            }
        }
        else
        {
            printf("Erreur dans la lecture du fichier %s.\n", wildcardPath);
        }

        free(wildcardContent);
    }
    else
    {
        usage();
    }

    return EXIT_SUCCESS;
}