#!/bin/sh

## git-log-self - simple, author-specific changeset review utility

set -e

SELF=$(git config user.email)

PRETTY_FORMAT="----------%n\
Changeset: %h (Parents: %p)%n\
Refs: %d%n\
Date: %ai%n\
Author: %aN <%aE>%n\
Log: %s%n\
%b"

exec git log --author="${SELF}" --name-status \
    --pretty="tformat:${PRETTY_FORMAT}" "$@"
