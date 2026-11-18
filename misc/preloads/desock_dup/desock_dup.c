#define _GNU_SOURCE

#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>
#include <dlfcn.h>
#include <errno.h>
#include <stdio.h>
#include <poll.h>

#define PEEK_BUF_SIZE 16000


char* peek_buf = NULL;
size_t peek_buffer_index = 0;
//
// originals
//
int (*original_close)(int);
int (*original_dup2)(int, int);
ssize_t (*original_read)(int, void*, size_t);
__attribute__((constructor)) void preeny_desock_dup_orig()
{
	original_close = dlsym(RTLD_NEXT, "close");
	original_dup2 = dlsym(RTLD_NEXT, "dup2");
	original_read = dlsym(RTLD_NEXT, "read");

	peek_buf = malloc(sizeof(char) * PEEK_BUF_SIZE);
	for (size_t i = 0; i < PEEK_BUF_SIZE; i++)
		peek_buf[i] = 0;
}

int close(int sockfd)
{
    return sockfd <= 2 ? 0 : original_close(sockfd);
}

int dup2(int old, int new)
{
	if (new <= 2)
	{
		fprintf(stderr, "Disabling dup from %d to %d\n", old, new);
		return new;
	}
	else
	{
		return original_dup2(old, new);
	}
}

int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen)
{
	fprintf(stderr, "Emulating accept on %d\n", sockfd);
  if (addr != NULL) {
	  addr->sa_family = AF_INET;
  }
	return 0;
}

int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen)
{
	fprintf(stderr, "Emulating bind on port %d\n", ntohs(((struct sockaddr_in*)addr)->sin_port));
	return 0;
}

int listen(int sockfd, int backlog)
{
	return 0;
}

int getpeername(int sockfd, struct sockaddr *addr, socklen_t *addrlen) {
  (void)sockfd;
  (void)addr;
  (void)addrlen;

  if (addr != NULL) {
	  addr->sa_family = AF_INET;
  }

  fprintf(stderr, "info: Emulating getpeername\n");
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

int setsockopt(int sockfd, int level, int optid, const void *optdata,
               socklen_t optdatalen) {

  (void)sockfd;
  (void)level;
  (void)optid;
  (void)optdata;
  (void)optdatalen;
  return 0;

}


ssize_t recv(int sockfd, void *buf, size_t len, int flags) {
  (void)sockfd;
  fprintf(stderr, "info: Emulating recv (len=%lu)\n", len);
  int res = 0;

  if (flags & MSG_PEEK) {
	size_t new_read = 0;
	memcpy(buf, peek_buf, peek_buffer_index);
	new_read = original_read(0, buf + peek_buffer_index, len - peek_buffer_index);
	memcpy(peek_buf + peek_buffer_index, buf + peek_buffer_index, new_read);
	peek_buffer_index += new_read;
	res = peek_buffer_index;
  } else {
	  res = original_read(0, buf, len);
  }
  
  return res;
}


ssize_t read(int fd, void *buf, size_t count)
{
	fprintf(stderr, "info: Emulating read(%d)\n", fd);

	if (fd <= 2) {
        if (peek_buffer_index <= 0) {
            return original_read(0, buf, count);
        }

		ssize_t res = 0;
		size_t max_copy_size = peek_buffer_index > count ? count : count - peek_buffer_index;
		fprintf(stderr, "  %lu chars are buffered (out of %lu total) and ready to be copied over\n", max_copy_size, peek_buffer_index);
		memcpy(buf, peek_buf, max_copy_size);
		res = max_copy_size;

		/* Restore peek buffer. */
		if (max_copy_size <= peek_buffer_index) {
			fprintf(stderr, "Shifting peek buffer back since part of it was consumed\n");
			fprintf(stderr, "peek_buf was: '%s'\n", peek_buf);
			for (size_t i = max_copy_size; i < peek_buffer_index; i++)
				peek_buf[i - max_copy_size] = peek_buf[i];
			for (size_t i = peek_buffer_index - max_copy_size; i < peek_buffer_index; i++)
				peek_buf[i] = 0;
			peek_buffer_index -= max_copy_size;
			fprintf(stderr, "peek_buf is now: '%s'\n", peek_buf);

		} else {
			fprintf(stderr, "Peek buffer was completely consumed\n");
			for (size_t i = 0; i < peek_buffer_index; i++)
				peek_buf[i] = 0;
			peek_buffer_index = 0;
		}

		return res;
	}

	return original_read(fd, buf, count);
}
