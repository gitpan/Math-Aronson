#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of Time-Duration-Locale.
#
# Time-Duration-Locale is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Time-Duration-Locale is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Time-Duration-Locale.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Math::Aronson;
use Test::More;

# uncomment this to run the ### lines
#use Smart::Comments;

use Config;
$Config{useithreads}
  or plan skip_all => 'No ithreads in this Perl';

eval { require threads } # new in perl 5.8, maybe
  or plan skip_all => "threads.pm not available: $@";

plan tests => 2;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }


# This is only meant to check that any CLONE() done by threads works with
# the fields in the iterator object.  Being all-perl it's going to be fine.

my $it = Math::Aronson->new;
$it->next;

my $thr = threads->create(\&foo);
sub foo {
  return [ $it->next, $it->next, $it->next, $it->next ];
}

my $thread_aref = $thr->join;
### $thread_aref
is_deeply ($thread_aref, [4, 11, 16, 24], 'same in thread as main');

my @main = ($it->next, $it->next, $it->next, $it->next);
### @main
is_deeply (\@main, [4, 11, 16, 24], "thread doesn't upset main");

exit 0;
