#define _XOPEN_SOURCE 700
#include <signal.h>
#include <unistd.h>
#include <sys/wait.h>

int main()
{
	sigset_t set;
	int status, i;

	for (i = 0; i < 1024; i++)
		close(i);

	if (getpid() != 1) return 1;

	sigfillset(&set);
	sigprocmask(SIG_BLOCK, &set, 0);

	for (;;) wait(&status);
}

