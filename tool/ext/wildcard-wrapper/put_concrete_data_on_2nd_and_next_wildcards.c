#include <stdlib.h>
#include <stdio.h>

#include "config.h"
#include "utils.h"
#include "wrapper_internals.h"

void putConcreteDataOn2ndAndNextWildcardsUsage()
{
    printf("Example :\n\twildcard : \"USER *-{milhouse};PASS *-{lisa}\"\n\tconcrete_data : \"aaaa\"\n\tResult => USER *-{milhouse};PASS aaaa\n");
    printf("Usage : ./put_concrete_data_on_2nd_and_next_wildcards <wildcard_file> <concrete_data>\n");
}

int main(int argc, char** argv)
{
    char* wildcardPath;
    char* placeholder;
    char* wildcardContent;
    struct wildcard* parsedWildcard;
    char result[MAX_STRING_SIZE];
    size_t numberOfWildcardedInputsToFill;
    size_t i;

    if (argc == 3)
    {
        wildcardPath = argv[1];
        placeholder = argv[2];

        wildcardContent = readWildcard(wildcardPath, read);

        if (strlen(wildcardContent) != 0)
        {
            parsedWildcard = parseWildcard(wildcardContent, wildcardPath);
            numberOfWildcardedInputsToFill = getNumberOfWildcardsInWildcard(parsedWildcard);

            strReset(result, MAX_STRING_SIZE);

            if (numberOfWildcardedInputsToFill > 0)
            {
                stringList2WildcardWithStringExclusions(result, MAX_STRING_SIZE, parsedWildcard->starExclusions->nodeContent);
                strConcat(result, "\n", MAX_STRING_SIZE);

                for (i = 1; i < numberOfWildcardedInputsToFill; ++i)
                {
                    strConcat(result, placeholder, MAX_STRING_SIZE);
                    strConcat(result, "\n", MAX_STRING_SIZE);
                }
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
        putConcreteDataOn2ndAndNextWildcardsUsage();
    }

    return EXIT_SUCCESS;
}
