#!/bin/sh

## git-log-simple - simple changeset review utility

PRETTY_FORMAT=${GIT_FORMAT:-"----------%n\
Changeset: %h (Parents: %p)%n\
Refs: %d%n\
Date: %ai%n\
Author: %aN <%aE>%n\
Log: %s%n\
%b"}

GIT_STATUS=${GIT_STATUS:---name-status}

exec git log --abbrev-commit ${GIT_STATUS} \
  --pretty="tformat:${GIT_FORMAT}" "$@"
