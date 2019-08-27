#!/bin/sh

## git-log-self - simple, author-specific changeset review utility

set -e

SELF=$(git config user.email)

GIT_FORMAT=${GIT_FORMAT:-"----------%n\
Changeset: %h (Parents: %p)%n\
Refs: %d%n\
Date: %ai%n\
Author: %aN <%aE>%n\
Log: %s%n\
%b"}

GIT_STATUS=${GIT_STATUS:---name-status}

exec git log --author="${SELF}" ${GIT_STATUS} \
    --pretty="tformat:${GIT_FORMAT}" "$@"
