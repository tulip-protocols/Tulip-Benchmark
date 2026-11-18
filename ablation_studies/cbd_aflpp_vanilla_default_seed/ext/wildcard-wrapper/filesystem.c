#include <assert.h>
#include <string.h>
#include <sys/types.h>
#include <dirent.h>

#include "filesystem.h"
#include "config.h"
#include "string_list.h"
#include "utils.h"

struct stringListNode* getDirectoryContent(char* directoryPath)
{
    struct stringListNode* result = stringList_init();
    DIR* directoryFD;
    struct dirent* directoryEntry;
    char* currentFilePath;

    directoryFD = opendir(directoryPath);

    assert(directoryFD != NULL);

    directoryEntry = readdir(directoryFD);

    while (directoryEntry != NULL)
    {
        if ((strcmp(directoryEntry->d_name, ".") != 0) && (strcmp(directoryEntry->d_name, "..") != 0))
        {
            currentFilePath = malloc(sizeof(char) * MAX_STRING_SIZE);

            strncpy(currentFilePath, directoryPath, MAX_STRING_SIZE);
            strConcat(currentFilePath, "/", MAX_STRING_SIZE);
            strConcat(currentFilePath, directoryEntry->d_name, MAX_STRING_SIZE);

            stringList_add(&result, currentFilePath);
        }

        directoryEntry = readdir(directoryFD);
    }

    closedir(directoryFD);

    return result;
}