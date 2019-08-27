#!/bin/sh

## git-log-simple - simple changeset review utility

PRETTY_FORMAT="----------%n\
Changeset: %h (Parents: %p)%n\
Refs: %d%n\
Date: %ai%n\
Author: %aN <%aE>%n\
Log: %s%n\
%b"

exec git log --abbrev-commit --name-status \
  --pretty="tformat:${PRETTY_FORMAT}" "$@"
