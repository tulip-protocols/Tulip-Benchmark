/*
 * Based on [preeny](https://github.com/zardus/preeny/blob/master/src/desock.c).
 */

#define _GNU_SOURCE


#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <pthread.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>
#include <dlfcn.h>
#include <errno.h>
#include <stdio.h>
#include <poll.h>
#include <sys/poll.h>

#define FAKE_PORT 9000
#define DUP_STDIN 3

#ifdef ROSA_PRELOAD_DEBUG
    #define debug(message, ...) fprintf(stderr, "[preloads:desock]  " message "\n", ##__VA_ARGS__)
#else
    #define debug(message, ...)
#endif


int duped_stdin = 0;
int already_accepted = 0;


int (*original_socket)(int, int, int);
int (*original_bind)(int, const struct sockaddr *, socklen_t);
int (*original_listen)(int, int);
int (*original_accept)(int, struct sockaddr *, socklen_t *);
int (*original_connect)(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
int (*original_close)(int fd);
int (*original_shutdown)(int sockfd, int how);
int (*original_getsockname)(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
ssize_t (*original_read)(int fd, void *buf, size_t count);
ssize_t (*original_write)(int fd, const void *buf, size_t count);

__attribute__((constructor)) void setup()
{
	original_socket = dlsym(RTLD_NEXT, "socket");
	original_listen = dlsym(RTLD_NEXT, "listen");
	original_accept = dlsym(RTLD_NEXT, "accept");
	original_bind = dlsym(RTLD_NEXT, "bind");
	original_connect = dlsym(RTLD_NEXT, "connect");
	original_close = dlsym(RTLD_NEXT, "close");
	original_shutdown = dlsym(RTLD_NEXT, "shutdown");
	original_getsockname = dlsym(RTLD_NEXT, "getsockname");
	original_read = dlsym(RTLD_NEXT, "read");
	original_write = dlsym(RTLD_NEXT, "write");

	duped_stdin = dup2(0, DUP_STDIN);
}

int socket(int domain, int type, int protocol)
{
    debug("Fake socket");
    return 0;
}

int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen)
{
    // Setup a real socket address that will fool the target server.
    struct sockaddr_in peer_addr;
    memset(&peer_addr, '0', sizeof(struct sockaddr_in));
    peer_addr.sin_family = AF_INET;
    peer_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    peer_addr.sin_port = htons(FAKE_PORT);
    if (addr) memcpy(addr, &peer_addr, sizeof(struct sockaddr_in));

    if (!already_accepted) {
        debug("First accept, letting it through to dup2'd stdin (fd=%d)", duped_stdin);
        already_accepted = 1;
        return duped_stdin;
    } else {
        debug("Already accepted 1 connection, blocking accept");
        return -1;
    }
}

int accept4(int sockfd, struct sockaddr *addr, socklen_t *addrlen, int flags)
{
	return accept(sockfd, addr, addrlen);
}

int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen)
{
	debug("Fake bind");
	return 0;
}

int listen(int sockfd, int backlog)
{
	debug("Fake listen");
	return 0;
}

int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen)
{
	debug("Fake connect");
	return 0;
}

int close(int fd) {
    if ((fd == 0 || fd == duped_stdin) && already_accepted) {
        debug("Transaction of fake socket is done, forcing exit(0)");
        exit(0);
    } else {
        debug("Letting close() through");
        original_close(fd);
    }
}

int shutdown(int sockfd, int how) {
    if ((sockfd == 0 || sockfd == duped_stdin) && already_accepted) {
        debug("Transaction of fake socket is done, forcing exit(0)");
        exit(0);
    } else {
        debug("Letting close() through");
        original_shutdown(sockfd, how);
    }
}

int getsockname(int sockfd, struct sockaddr *addr, socklen_t *addrlen) {
    debug("Fake getsockname");

    // Spoof socket name.
    struct sockaddr_in target;
    socklen_t copylen = sizeof(target);

    if (!addr || !addrlen)
        return -1;

    if (*addrlen < sizeof(target))
        copylen = *addrlen;

    target.sin_family = AF_INET;
    target.sin_addr.s_addr = htonl(INADDR_ANY);
    target.sin_port = htons(FAKE_PORT);

    memcpy(addr, &target, copylen);
    *addrlen = copylen;

    return 0;
}

int __poll_chk(struct pollfd *fds, nfds_t nfds, int timeout, size_t fdslen)
{
	debug("Fake poll (nfds=%ld)", nfds);
	for (int i = 0; i < nfds; i++)
        fds[i].revents = POLLIN;

	return nfds;
}

ssize_t read(int fd, void *buf, size_t count) {
	debug("Fake read");
	return original_read(0, buf, count);
}

ssize_t write(int fd, const void *buf, size_t count)
{
	debug("Fake write");
	return original_write(1, buf, count);
}
