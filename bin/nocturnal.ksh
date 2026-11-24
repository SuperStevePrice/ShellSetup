#!/bin/ksh
#-------------------------------------------------------------------------------
# File:
#   nocturnal.ksh
#
# PURPOSE:
#   Old name kept so existing habits and older copied command lines keep
#   working after the Nocturnal Log -> Urine Log rename. Hands everything
#   to urine.ksh in the same directory.
#-------------------------------------------------------------------------------
here=${0%/*}
[[ "$here" == "$0" ]] && here=.
exec ksh "$here/urine.ksh" "$@"
