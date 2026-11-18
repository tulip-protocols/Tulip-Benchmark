#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "config.h"
#include "utils.h"
#include "wrapper_internals.h"

void usage()
{
    printf("Usage : ./concretize_wildcard <wildcard_file> <concrete_data>\n");
}

int main(int argc, char** argv)
{
    char* wildcardPath;
    char* concreteData;
    char* wildcardContent;
    struct wildcard* parsedWildcard;
    char result[MAX_STRING_SIZE];
    size_t i = 0;

    if (argc == 3)
    {
        wildcardPath = argv[1];
        concreteData = argv[2];

        wildcardContent = readWildcard(wildcardPath, read);

        if (strlen(wildcardContent) != 0)
        {
            parsedWildcard = parseWildcard(wildcardContent, wildcardPath);

            strReset(result, MAX_STRING_SIZE);

            for (i = 0; i < getNumberOfWildcardsInWildcard(parsedWildcard); ++i)
            {
                strConcat(result, concreteData, MAX_STRING_SIZE);
                strConcat(result, "\n", MAX_STRING_SIZE);
            }

            fillWildcard(result, MAX_STRING_SIZE, parsedWildcard, NULL);

            printf("%s", result);
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