#include <bits/types/sigset_t.h>
#include <bits/types/struct_timeval.h>
#include <time.h>
#include <poll.h>

#define UNUSED __attribute__((unused))

int poll(UNUSED struct pollfd *fds, UNUSED nfds_t nfds, UNUSED int timeout)
{
    return 1;
}

int ppoll(UNUSED struct pollfd* fds, UNUSED nfds_t nfds, UNUSED const struct timespec* tmo_p, UNUSED const sigset_t* sigmask)
{
    return 1;
}