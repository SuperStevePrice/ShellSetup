#!/usr/bin/env bash
#
# speak.sh — thin wrapper. All real logic lives in _speak_impl.sh, shared
# with speak.ksh, so a fix only ever needs to happen once. Sourcing (not
# exec) keeps $0 set to THIS wrapper, so Usage/help text correctly shows
# "speak.sh" (or "speak", run via the symlink) rather than the impl file's
# own name.
#
. "$(dirname "$0")/_speak_impl.sh"
