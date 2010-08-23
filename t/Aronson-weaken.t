#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Math-Aronson.
#
# Math-Aronson is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Aronson is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Aronson.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
use Test::Weaken::ExtraBits;
MyTestHelpers::nowarnings();

require Math::Aronson;

# version 2.002 for "ignore"
eval "use Test::Weaken 2.002; 1"
  or plan skip_all => "due to Test::Weaken 2.002 not available -- $@";
plan tests => 5;

sub my_ordinal {
  return 'foo';
}

foreach my $options ([],
                     [ conjunctions => 0 ],
                     [ lang => 'fr' ],
                     [ lang => 'fr', conjunctions => 0 ],
                     [ ordinal_func => \&my_ordinal ],
                    ) {
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         return Math::Aronson->new (@$options);
       },
       ignore => \&Test::Weaken::ExtraBits::ignore_global_function,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection');
  if ($leaks) {
    eval { diag "Test-Weaken ", explain $leaks }; # explain in Test::More 0.82

    my $unfreed = $leaks->unfreed_proberefs;
    foreach my $proberef (@$unfreed) {
      diag "  unfreed $proberef";
    }
    foreach my $proberef (@$unfreed) {
      diag "  search $proberef";
      MyTestHelpers::findrefs($proberef);
    }
  }
}

exit 0;
