#! /bin/sh

# Copyright (C) 2001 by Martin Pool <mbp@samba.org>

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version
# 2 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.


# rsync top-level test script -- this invokes all the other more
# detailed tests in order.  This script can either be called by `make
# check' or `make installcheck'.  `check' runs against the copies of
# the program and other files in the build directory, and
# `installcheck' against the installed copy of the program.  

# In either case we need to also be able to find the source directory,
# since we read test scripts and possibly other information from
# there.

# Whenever possible, informational messages are written to stdout and
# error messages to stderr.  They're separated out by the build farm
# display scripts.

# According to the GNU autoconf manual, the only valid place to set up
# directory locations is through Make, since users are allowed to (try
# to) change their mind on the Make command line.  So, Make has to
# pass in all the values we need.

# For other configured settings we read ./config.sh, which tells us
# about shell commands on this machine and similar things.

# rsync_bin gives the location of the rsync binary.  This is either
# builddir/rsync if we're testing an uninstalled copy, or
# install_prefix/bin/rsync if we're testing an installed copy.  On the
# build farm rsync will be installed, but into a scratch /usr.

# srcdir gives the location of the source tree, which lets us find the
# build scripts.  At the moment we assume we are invoked from the
# source directory.

# This script must be invoked from the build directory.  

# A scratch directory, 'testtmp', is created in the build directory to
# hold working files.

# This script also uses the $loglevel environment variable.  1 is the
# default value, and 10 the most verbose.  You can set this from the
# Make command line.  It's also set by the build farm to give more
# detail for failing builds.


# NOTES FOR TEST CASES:

# Each test case runs in its own shell. 

# Exit codes from tests:

#    1  tests failed
#    2  error in starting tests
#   77  this test skipped (random value unlikely to happen by chance, same as
#       automake)

# HOWEVER, the overall exit code to the farm is different: we return
# the *number of tests that failed*, so that it will show up nicely in
# the overall summary.

# rsync.fns contains some general setup functions and definitions.


# NOTES ON PORTABILITY:

# Both this script and the Makefile have to be pretty conservative
# about which Unix features they use.

# We cannot count on Make exporting variables to commands, unless
# they're explicitly given on the command line.

# Also, we can't count on 'cp -a' or 'mkdir -p', although they're
# pretty handy.

# I think some of the GNU documentation suggests that we shouldn't
# rely on shell functions.  However, the Bash manual seems to say that
# they're in POSIX 1003.2, and since the build farm relies on them
# they're probably working on most machines we really care about.

# You cannot use "function foo {" syntax, but must instead say "foo()
# {", or it breaks on FreeBSD.



# STILL TO DO:

# We need a good protection against tests that hang indefinitely.
# Perhaps some combination of starting them in the background, wait,
# and kill?

# Perhaps we need a common way to cleanup tests.  At the moment just
# clobbering the directory when we're done should be enough.


set -e

. "./shconfig"

RUNSHFLAGS='-e'

if [ -n "$loglevel" ] && [ "$loglevel" -gt 8 ]
then
    if set -x
    then
	# If it doesn't work the first time, don't keep trying.
	RUNSHFLAGS="$RUNSHFLAGS -x"
    fi
fi

echo "============================================================"
echo "$0 running in `pwd`"
echo "    rsync_bin=$rsync_bin"
echo "    srcdir=$srcdir"

if test ! -f $rsync_bin
then
    echo "rsync_bin $rsync_bin is not a file" >&2
    exit 2
fi

if test ! -d $srcdir
then
    echo "srcdir $srcdir is not a directory" >&2
    exit 2
fi

RSYNC="$rsync_bin"

export rsync_bin RSYNC

skipped=0
missing=0
passed=0
failed=0

scratchdir=./testtmp
[ -d "$scratchdir" ] && rm -r "$scratchdir"
mkdir "$scratchdir"
scratchdir=`cd $scratchdir && pwd`
echo "    scratchdir=$scratchdir"

suitedir="$srcdir/testsuite"

export scratchdir suitedir

if [ "x$whichtests" = x ]
then
    whichtests="*.test"
fi

for testscript in $suitedir/$whichtests
do
    testbase=`echo $testscript | sed 's!.*/!!'`

    echo "----- $testbase starting"

    if sh $RUNSHFLAGS "$testscript"
    then
	echo "----- $testbase completed succesfully"
	passed=`expr $passed + 1`
    else 
	case $? in
	77)
	    echo "----- $testbase skipped"
	    skipped=`expr $skipped + 1`
	    ;;
	*)
	    echo "----- $testbase failed!"
	    failed=`expr $failed + 1`
	    if [ "x$nopersist" = "xyes" ]
	    then
		exit 1
	    fi
	esac
    fi
done

echo '------------------------------------------------------------'
echo "----- overall results:"
echo "      $passed passed"
[ "$failed" -gt 0 ]  && echo "      $failed failed"
[ "$skipped" -gt 0 ] && echo "      $skipped skipped"
[ "$missing" -gt 0 ] && echo "      $missing missing"
echo '------------------------------------------------------------'

exit `expr $failed + $missing`
