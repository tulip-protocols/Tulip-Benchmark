#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>

#include "../wrapper_internals.h"
#include "../wildcard_list.h"
#include "../filesystem.h"

#define BUF_LENGTH  256

static struct wildcardListNode* parsedWildcards;
static size_t parsedWildcardsLength;
static int wildcardId = 0;

void loadWildcards()
{
    char* wildcardsPath = getenv(ENV_WILDCARD_PATH);
    char* wildcardContent;
    struct stringListNode* wildcardFiles;
    char* currentWildcardPath;
    char* showWildcardsEnvValue = getenv(ENV_SHOW_WILDCARDS);
    struct stringListNode* wildcardFilesContents;

    #ifdef NO_CRASH_WHEN_THERE_IS_NO_WILDCARD
        printf("NO_CRASH_WHEN_THERE_IS_NO_WILDCARD enabled. Maybe we are in debug mode.\n");
    #endif

    parsedWildcards = wildcardList_init();

    if (wildcardsPath == NULL)
    {
        fprintf(stderr, "Warning : There is no wildcard file passed through the " ENV_WILDCARD_PATH " environment variable.\n");

        #ifndef NO_CRASH_WHEN_THERE_IS_NO_WILDCARD
            kill(getpid(), SIGSEGV);
        #endif
    }

    wildcardFiles = getDirectoryContent(wildcardsPath);

    if (stringList_hasNext(wildcardFiles) == false)
    {
        fprintf(stderr, "Warning : There is no wildcard file passed through the " ENV_WILDCARD_PATH " environment variable.\n");

        #ifndef NO_CRASH_WHEN_THERE_IS_NO_WILDCARD
            kill(getpid(), SIGSEGV);
        #endif
    }

    if (showWildcardsEnvValue == NULL)
    {
        while (stringList_hasNext(wildcardFiles) == true)
        {
            currentWildcardPath = stringList_next(&wildcardFiles);
            wildcardContent = readWildcard(currentWildcardPath, read);

            if (strlen(wildcardContent) != 0)
            {
                wildcardList_add(&parsedWildcards, parseWildcard(wildcardContent));
            }
            else
            {
                printf("Failure in wildcard read, maybe the file \"%s\" does not exists.\n", currentWildcardPath);

                #ifndef NO_CRASH_WHEN_THERE_IS_NO_WILDCARD
                    kill(getpid(), SIGSEGV);
                #endif
            }
        }
    }
    else
    {
        wildcardFilesContents = stringList_init();

        while (stringList_hasNext(wildcardFiles) == true)
        {
            currentWildcardPath = stringList_next(&wildcardFiles);
            wildcardContent = readWildcard(currentWildcardPath, read);

            stringList_add(&wildcardFilesContents, wildcardContent);
        }

        stringList_iteri(wildcardFilesContents, printStrWithIdAndDelim);

        fprintf(stderr, "Segfault -> It's normal :) (Placed in %s, line %d)\n", __FILE_NAME__, __LINE__ + 1);
        kill(getpid(), SIGSEGV);
    }

    parsedWildcardsLength = wildcardList_length(parsedWildcards);
}

int main(int argc, char** argv)
{
    char buffer[BUF_LENGTH];
    char reverseWildcardBuffer[BUF_LENGTH];
    bool isGoodWildcard;
    struct wildcard* wildcard;

    loadWildcards();

    printf("Selected wildcard : %d\n", wildcardId);

    printf("Lancement du test !\n");

    strcpy(buffer, "USER totoro\nLIST tatate\n");

    printf("Buffer content : \"%s\"\n", buffer);

    reverseWildcard(buffer, reverseWildcardBuffer, BUF_LENGTH, wildcardList_at(parsedWildcards, wildcardId));

    printf("Reversing wildcard : \"%s\"\n", reverseWildcardBuffer);

    isGoodWildcard = isFromThisWildcard(buffer, wildcardList_at(parsedWildcards, wildcardId));

    if (isGoodWildcard == true)
    {
        printf("Bon Wildcard !\n");
    }
    else
    {
        printf("Mauvais Wildcard !\n");
    }

    wildcard = getAssociatedWildcard(buffer, parsedWildcards);

    printf("Wildcard addr : %p\n", wildcard);

    return EXIT_SUCCESS;
}