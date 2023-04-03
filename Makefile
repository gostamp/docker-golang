.DEFAULT_GOAL := help
SHELL := /bin/bash

# Lazily create and "source" the .env file
# See: https://unix.stackexchange.com/a/235254
ifeq (,$(wildcard .env))
    $(shell cp .env.example .env)
endif
include .env
export $(shell sed 's/=.*//' .env)

ifeq ($(CI),true)
    # Customize user so FS permissions are correct.
    export APP_USER := ci:ci
    export APP_HOME := /home/ci
else
    # Uncomment if token is needed in the container.
    # export GITHUB_TOKEN := $(shell gh auth token)
endif

# Support running make commands from both host and container.
ifneq ($(RUNNING_IN_CONTAINER),1)
    # Always use buildkit.
    export DOCKER_BUILDKIT := 1
    # Set the env var used in the compose file for the SSH forwarding socket.
    # The path must exist or compose will exit with an error.
    docker_os := $(shell docker info | grep 'Operating System:' | cut -d ':' -f 2 | xargs)
    ifeq ($(docker_os),Docker Desktop)
        # Use the magic Docker Desktop path that forwards the host's SSH auth socket.
        export DOCKER_DESKTOP_SOCK := /run/host-services/ssh-auth.sock
    else
        # Reusing .env as a dummy file.
        export DOCKER_DESKTOP_SOCK := $(shell echo "$$(pwd)/.env")
    endif
    # Docker compose runs interactively by default, but git hooks run non-interactively.
    # Docker will error if there's a mismatch.
    # `-t 0` returns true if file descriptor 0 is a terminal (https://stackoverflow.com/a/911213/1582608).
    run_tty := $(shell [ ! -t 0 ] && echo '--no-TTY ')
    run = docker compose run --rm $(run_tty)app
else ifneq ($(RUNNING_IN_ENTRYPOINT),1)
    run = /app/bin/entrypoint.sh
else
    run =
endif


# The actual tasks are in ./make (broken out into files per-section).
include ./make/*.mk
