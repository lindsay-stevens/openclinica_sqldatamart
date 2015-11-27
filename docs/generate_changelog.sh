#!/bin/bash

# Git log processing script to generate a changelog formatted as markdown.
# - Requires git and perl (included in Git for Windows).
# - Intended to act as a quick reference or index to full commit messages.
# - Groups by commit tags, which presumably have some meaning or are releases.
# - Short commit hash for each commit is shown for lookup and github linking.
# - The first 80 characters of the commit subject is displayed.
#
# Explanation of steps
# - git log: format as: LF tag LF short-hash space commit-subject-to-80-chars.
# - perl re: find tags (chars in brackets); prefix with "##" (md header 2).
# - perl re: remove double LF before a short-hash.
# - perl re: remove LF at start of document, add "# Changelog" (md header 1).
# - perl re: find commits (starts with alnum not #); prefix with "-" (md list).
# - perl re: remove sequences of 2 or more spaces (from git log trunc padding).
# - perl re: remove any NUL chars added during LF processing steps.

git log --pretty=format:"%+d%+h %<(80,trunc)%s" |
 perl -lpe's/( \(.*\))/##$1/g' |
 perl -0 -lpe's/\n(\n[a-z0-9])/$1/g' |
 perl -0 -lpe's/^\n/# Changelog\n\n/g' |
 perl -lpe's/^([^#][[:alnum:]])/- $1/g' |
 perl -lpe's/[[:space:]][[:space:]]+//g' |
 perl -lpe's/\0//g' > changelog.md