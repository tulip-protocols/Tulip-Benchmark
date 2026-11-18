/*
 * This is desock_dup.c from the amazing preeny project
 * https://github.com/zardus/preeny
 *
 * It is packaged in afl++ to have it at hand if needed
 *
 */

#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>   //
#include <sys/socket.h>  //
#include <sys/stat.h>    //
#include <fcntl.h>       //
#include <netinet/in.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <signal.h>
#include <dlfcn.h>
#include <errno.h>
#include <stdio.h>
#include <poll.h>
// #include "logging.h" // switched from preeny_info() to fprintf(stderr, "Info:
// "

//
// originals
//
int (*original_close)(int);
int (*original_dup2)(int, int);
FILE* (*original_fdopen)(int, const char*);
__attribute__((constructor)) void preeny_desock_dup_orig() {

  original_close = dlsym(RTLD_NEXT, "close");
  original_dup2 = dlsym(RTLD_NEXT, "dup2");
  original_fdopen = dlsym(RTLD_NEXT, "fdopen");

}

int close(int sockfd) {

  if (sockfd <= 2) {

    fprintf(stderr, "Info: Disabling close on %d\n", sockfd);
    return 0;

  } else {

    return original_close(sockfd);

  }

}

int dup2(int old, int new) {

  if (new <= 2) {

    fprintf(stderr, "Info: Disabling dup from %d to %d\n", old, new);
    return 0;

  } else {

    return original_dup2(old, new);

  }

}

int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen) {

  (void)sockfd;
  (void)addr;
  (void)addrlen;

  // For the PHP server.
  if (addr != NULL) {

    addr->sa_family = AF_INET;

  }

  fprintf(stderr, "Info: Emulating accept on %d\n", sockfd);
  return 0;

}

int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen) {

  (void)sockfd;
  (void)addr;
  (void)addrlen;
  fprintf(stderr, "Info: Emulating bind on port %d\n",
          ntohs(((struct sockaddr_in *)addr)->sin_port));
  return 0;

}

int listen(int sockfd, int backlog) {

  (void)sockfd;
  (void)backlog;
  return 0;

}

int setsockopt(int sockfd, int level, int optid, const void *optdata,
               socklen_t optdatalen) {

  (void)sockfd;
  (void)level;
  (void)optid;
  (void)optdata;
  (void)optdatalen;
  return 0;

}

int getsockname(int sockfd, struct sockaddr *addr, socklen_t *addrlen) {
  (void)sockfd;
  (void)addr;
  (void)addrlen;

  if (addr != NULL) {

    fprintf(stderr, "info: Emulating getsockname\n");
    // Taken from preeny.
    struct sockaddr_in target;
    socklen_t copylen = sizeof(target);

    if (*addrlen < sizeof(target)) {

      copylen = *addrlen;

    }

    target.sin_family = AF_INET;
    target.sin_addr.s_addr = inet_addr("127.0.0.1");
    target.sin_port = htons(8000);

    memcpy(addr, &target, copylen);
    *addrlen = copylen;

  }

  return 0;
}

ssize_t recv(int sockfd, void *buf, size_t len, int flags) {
  (void)sockfd;
  (void)flags;

  fprintf(stderr, "info: Emulating recv\n");
  return read(0, buf, len);
}

ssize_t recvfrom(
    int sockfd,
    void *buf,
    size_t len,
    int flags,
    struct sockaddr *src_addr,
    socklen_t *addrlen
)
{
    (void)src_addr;
    (void)addrlen;

    fprintf(stderr, "info: Emulating recvfrom\n");
    return recv(sockfd, buf, len, flags);
}

ssize_t recvmsg(int sockfd, struct msghdr *msg, int flags) {
  (void)sockfd;
  (void)flags;

  fprintf(stderr, "info: Emulating recvmsg\n");
  return recv(sockfd, msg->msg_iov->iov_base, msg->msg_iov->iov_len, flags);
}

int getpeername(int sockfd, struct sockaddr *addr, socklen_t *addrlen) {
  (void)sockfd;
  (void)addr;
  (void)addrlen;

  fprintf(stderr, "info: Emulating getpeername\n");
  return 0;
}

FILE *fdopen(int fd, const char *mode)
{
    fprintf(stderr, "info: Emulating fdopen\n");
    switch (fd) {
        case 0: return stdin;
        case 1: return stdout;
        case 2: return stderr;
        default: return original_fdopen(fd, mode);
    }
}
