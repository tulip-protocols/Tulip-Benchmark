#include <stdbool.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>

#define UNUSED               __attribute__((unused))
#define ENV_UID              "DECHANGEUSER_EMULATED_UID"
#define ENV_GID              "DECHANGEUSER_EMULATED_GID"
#define ENV_BLOCK_SETUID     "DECHANGEUSER_EMULATE_SETUID_DENIED"

bool fixedUID;
uid_t emulatedUID;
bool fixedGID;
gid_t emulatedGID;
bool blockSetuid;

__attribute__((constructor)) void dechangeuser_init()
{
    char* envUID = getenv(ENV_UID);
    char* envGID = getenv(ENV_GID);
    char* envEmulateSetuidDenied = getenv(ENV_BLOCK_SETUID);

    if (envUID == NULL)
    {
        fixedUID = false;
        emulatedUID = 0;
    }
    else
    {
        fixedUID = true;
        emulatedUID = atoi(envUID);
    }

    if (envGID == NULL)
    {
        fixedGID = false;
        emulatedGID = 0;
    }
    else
    {
        fixedGID = true;
        emulatedGID = atoi(envGID);
    }

    envEmulateSetuidDenied = getenv(ENV_BLOCK_SETUID);

    if ((envEmulateSetuidDenied != NULL) && (atoi(envEmulateSetuidDenied) == 1))
    {
        blockSetuid = true;
    }
    else
    {
        blockSetuid = false;
    }
}

int setuid(uid_t uid)
{
    int result;

    if ((blockSetuid == false) || (uid == emulatedUID))
    {
        result = 0;
    }
    else
    {
        result = -1;
    }

    if ((result == 0) && (fixedUID == false))
    {
        emulatedUID = uid;
    }

    return result;
}

uid_t getuid()
{
    return emulatedUID;
}

int setgid(gid_t gid)
{
    if (fixedGID == false)
    {
        emulatedGID = gid;
    }

    return 0;
}

gid_t getgid()
{
    return emulatedGID;
}

int seteuid(uid_t uid)
{
    int result;

    if ((blockSetuid == false) || (uid == emulatedUID))
    {
        result = 0;
    }
    else
    {
        result = -1;
    }

    if ((result == 0) && (fixedUID == false))
    {
        emulatedUID = uid;
    }

    return result;
}

uid_t geteuid()
{
    return emulatedUID;
}

int setegid(gid_t gid)
{
    if (fixedGID == false)
    {
        emulatedGID = gid;
    }

    return 0;
}