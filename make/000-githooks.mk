# These tasks are called by the "wrapper" scripts in `.git/hooks/`.
# Git calls the wrappers, which delegate to the make tasks, which run
# the "real" hook scripts inside the docker container.
#
# This indirection is needed so the user doesn't have worry about where
# they're running git. They can commit from the host, or from inside the
# container and it will just work due to the $(run) macro in the Makefile.
#
# The tasks are intentionally missing the comments needed to show up
# in the help UI since they aren't intended to be run by users.

.PHONY: pre-commit
pre-commit:
	$(run) ./bin/githooks/pre-commit.sh

.PHONY: prepare-commit-msg
prepare-commit-msg:
	$(run) ./bin/githooks/prepare-commit-msg.sh $(MSG_FILE)

.PHONY: commit-msg
commit-msg:
	$(run) ./bin/githooks/commit-msg.sh $(MSG_FILE)
