all: rlimit desock socket_fuzzing socket_fuzzing-belkin desock_dup defstat defork_aflpp depselect socket_fuzzing-cyrus dechangeuser depoll

rlimit:
	$(MAKE) -C rlimit all

desock:
	$(MAKE) -C desock all

socket_fuzzing:
	$(MAKE) -C socket_fuzzing all

socket_fuzzing-belkin:
	$(MAKE) -C socket_fuzzing-belkin all

desock_dup:
	$(MAKE) -C desock_dup

defstat:
	$(MAKE) -C defstat

defork_aflpp:
	$(MAKE) -C defork_aflpp

depselect:
	$(MAKE) -C depselect

socket_fuzzing-cyrus:
	$(MAKE) -C socket_fuzzing-cyrus all

dechangeuser:
	$(MAKE) -C dechangeuser

depoll:
	$(MAKE) -C depoll

clean:
	$(MAKE) -C rlimit clean
	$(MAKE) -C desock clean
	$(MAKE) -C socket_fuzzing clean
	$(MAKE) -C socket_fuzzing-belkin clean
	$(MAKE) -C desock_dup clean
	$(MAKE) -C defstat clean
	$(MAKE) -C defork_aflpp clean
	$(MAKE) -C depselect clean
	$(MAKE) -C socket_fuzzing-cyrus clean
	$(MAKE) -C dechangeuser clean
	$(MAKE) -C depoll clean

.PHONY: all clean rlimit desock socket_fuzzing socket_fuzzing-belkin desock_dup defstat defork_aflpp depselect socket_fuzzing-cyrus dechangeuser depoll
