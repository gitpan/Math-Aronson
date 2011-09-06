# Copyright 2010, 2011 Kevin Ryde

# This file is part of Math-Aronson.
#
# Math-Aronson is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Aronson is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Aronson.  If not, see <http://www.gnu.org/licenses/>.

package Math::Aronson;
use 5.004;
use strict;
use Carp;

# uncomment this to run the ### lines
#use Devel::Comments;

use vars '$VERSION';
$VERSION = 7;

# maybe a hi=>$limit option to stop the ret or queue building up beyond a
# desired point


my $unaccent;
BEGIN {
  if (eval "use Unicode::Normalize 'normalize'; 1") {
    $unaccent = sub {
      ### unaccent: $_[0]
      # uncombine the latin-1 etc equivs then strip the zero-width marks
      ($_[0] = normalize('D',$_[0])) =~ s/\pM+//g;
      };
  } else {
    $unaccent = sub {
      # latin-1, generated by devel/unaccent.pl
      $_[0] =~ tr/\300\301\302\303\304\305\307\310\311\312\313\314\315\316\317\321\322\323\324\325\326\331\332\333\334\335\340\341\342\343\344\345\347\350\351\352\353\354\355\356\357\361\362\363\364\365\366\371\372\373\374\375\377/AAAAAACEEEEIIIINOOOOOUUUUYaaaaaaceeeeiiiinooooouuuuyy/;
    };
  }
}

my %default_letter = ('en' => 'T',
                      'fr' => 'E');
my %default_initial_string = ('en' => 'is the',
                              'fr' => 'est la');
sub new {
  my $class = shift;
  ### Aronson new(): @_

  my @ret;
  my $self = bless { ret   => \@ret,
                     queue => [ ],
                     @_
                   }, $class;

  # 1 or '' for use with xor
  $self->{'lying'} = !! $self->{'lying'};

  my $lang = ($self->{'lang'} ||= 'en');  # default
  if ($lang eq 'en') {
    %$self = (conjunctions_word => 'and',
              %$self);
  } elsif ($lang eq 'fr') {
    %$self = (conjunctions_word => 'et',
              %$self);
  }
  # for oeis_anum()
  $self->{'lang'} = ($self->{'ordinal_func'} ? 'func' : lc($lang));

  my $without_conjunctions = delete $self->{'without_conjunctions'};
  my $conjunctions_word    = delete $self->{'conjunctions_word'};

  $self->{'conjunctions'}
    = (($lang eq 'en' && $conjunctions_word ne 'and')
       && ($lang eq 'fr' && $conjunctions_word ne 'et')
       ? 'x'
       : ($without_conjunctions ? 0 : 1));

  $self->{'ordinal_func'} ||=
    ($lang eq 'en' ? do {
      require Lingua::EN::Numbers;
      Lingua::EN::Numbers->VERSION(1.01);  # 1.01 rewrite
      \&Lingua::EN::Numbers::num2en_ordinal
    }
     : $lang eq 'fr' ? do {
       require Lingua::FR::Numbers;
       \&_fr_ordinal
     }
     : do {
       require Lingua::Any::Numbers;
       sub {
         return Lingua::Any::Numbers::to_ordinal($_[0], $lang);
       }
     });

  my $without_conjunctions_func
    = $self->{'without_conjunctions_func'}
      = ($without_conjunctions && defined $conjunctions_word
         ? do {
           $conjunctions_word = lc($conjunctions_word);
           sub { $_[0] =~ s/\b\Q$conjunctions_word\E\b// }
         }
         : \&_conjunctions_noop);  # no change to strings

  my $initial_string = delete $self->{'initial_string'};
  my $letter = $self->{'letter'};

  if (! defined $initial_string) {
    if (! $letter) {
      # default 'T' for en or 'E' for fr
      $letter = $default_letter{$lang};
    }
    if (! defined ($initial_string = $default_initial_string{$lang})) {
      croak 'No default initial_string for language \'',$lang,'\'';
    }
    $initial_string = $letter . $initial_string;
  }

  &$unaccent ($initial_string);
  $initial_string = lc ($initial_string);

  &$without_conjunctions_func ($initial_string);
  $initial_string =~ s/(\W|_)+//g;  # strip non alphas
  ### initial: $initial_string

  if (! defined $letter) {
    if (defined $initial_string) {
      # initial_string but no letter, take letter as first alphabetical
      $letter = substr($initial_string,0,1);
    } else {
    }
  }

  unless (length($letter)) {
    # empty letter string no good as will match endlessly, change to a space
    # which will never match
    $letter = ' ';
  }
  $self->{'letter'} = $letter = lc($letter);

  # my $upto = 1;
  push @ret,
    grep {(substr($initial_string,$_-1,1) eq $letter) ^ $self->{'lying'}}
      1 .. (1 + length($initial_string)-1);
  $self->{'upto'} = 1 + length($initial_string);
  ### initial: $self
  return $self;
}

sub _conjunctions_noop {
}

sub _fr_ordinal {
  my $str = Lingua::FR::Numbers::ordinate_to_fr($_[0]);
  # Feminine "E est la premiere lettre ..."
  if ($str eq 'premier') { $str = 'premiere'; }
  return $str;
}


sub next {
  my ($self) = @_;
  my $ret = $self->{'ret'};
  for (;;) {
    if (my $n = shift @$ret) {
      push @{$self->{'queue'}}, $n;
      return $n;
    }

    my $k = shift @{$self->{'queue'}}
      || return;  # end of sequence

    my $str = &{$self->{'ordinal_func'}}($k);
    ### orig str: $str
    &{$self->{'without_conjunctions_func'}}($str);
    &$unaccent ($str);
    $str = lc ($str);

    # could be s/[[:punct:][:space:]]+//g, but [::] new in 5.005 or something
    $str =~ s/(\W|_)+//g;  # strip non alphas
    ### munged str: $str

    my $upto = $self->{'upto'};
    my $letter = $self->{'letter'};
    push @$ret,
      grep {(substr($str,$_-$upto,1) eq $letter) ^ $self->{'lying'}}
        $upto .. ($upto + length($str)-1);

    $self->{'upto'} += length($str);
    ### now upto: $self->{'upto'}
    ### ret: $ret
    ### queue: $self->{'queue'}
  }
}

1;
__END__

=for stopwords Ryde Aronson Aronson's proven et OEIS Lingua Aronson

=head1 NAME

Math::Aronson -- generate values of Aronson's sequence

=head1 SYNOPSIS

 use Math::Aronson;
 my $aronson = Math::Aronson->new;
 print $aronson->next,"\n";  # 1
 print $aronson->next,"\n";  # 4
 print $aronson->next,"\n";  # 11

=head1 DESCRIPTION

This is a bit of fun generating Aronson's sequence of numbers formed by
self-referential occurrences of the letter T in numbers written out in
words.

    T is the first, fourth, eleventh, sixteenth, ...
    ^    ^       ^      ^         ^      ^   ^
    1    4      11     16        24     29  33  <-- sequence

In the initial string "T is the", the letter T is the first and fourth
letters, so those words are appended to make "T is the first, fourth".
Those words have further Ts at 11 and 16, so those numbers are appended, and
so on.

Spaces and punctuation are ignored.  Accents like acutes are stripped for
letter matching.  The C<without_conjunctions> option can ignore "and" or
"et" too.

=head2 Termination

It's possible for the English sequence to end since there's no T in some
numbers, but there doesn't seem enough of those, or the sequence doesn't
fall on enough of them.  (Is that proven?)

But for example using letter "F" instead gives a finite sequence,

    $it = Math::Aronson->new (letter => 'F');  # 1, 7 only

This is "F is the first, seventh" giving 1, 7 but ends there as there's no
more "F"s in "seventh".  See F<examples/terminate.pl> in the sources to run
thorough which letters seem to terminate or not.

=head2 OEIS

Sloane's On-Line Encyclopedia of Integer Sequences has entries for Aronson's
sequence and some variations

    http://oeis.org/A005224

    A005224    without_conjunctions=>1
    A055508    letter=>'H', without_conjunctions=>1
    A049525    letter=>'I', without_conjunctions=>1
    A081023    lying=>1,    without_conjunctions=>1
    A072886    lying=>1, initial_string=>"S ain't the"

    A080520    lang=>'fr'

    A081024    complement of lying A081023
    A072887    complement of lying "S ain't" A072886
    A072421    Latin P
    A072422    Latin N
    A072423    Latin T

The English sequences are without conjunctions, hence for example

    # sequence A005224
    $it = Math::Aronson->new (without_conjunctions => 1);

The "lying" versions A081023 and A072886 are presumably the same, but the
sample values don't go far enough to see a difference.

=head1 FUNCTIONS

The sequence is an infinite recurrence (or may be) so is generated in
iterator style from an object created with various options.

=head2 Constructor

=over

=item C<< $it = Math::Aronson->new (key => value, ...) >>

Create and return a new Aronson sequence object.  The following optional
key/value parameters affect the sequence.

=over

=item C<< lang => $string >> (default "en")

The language to use for the sequence.  "en" and "fr" have defaults for the
options below.  Other languages can be used if you have the
C<Lingua::Any::Numbers> module.

=item C<< initial_string => $str >>

The initial string for the sequence.  The default is

    English    "T is the"
    French     "E est la"

For other languages there's no default yet and an C<initial_string> must be
given.

=item C<< letter => $str >>

The letter to look for in the words.  The default is the first letter of
C<initial_string>.

When a C<letter> is given the default C<initial_string> follows that, so "X
is the" or "X est la".

   $it = Math::Aronson->new (letter => 'H');
   # is 1, 5, 16, 25, ...
   # per "H is the first, fifth, ..."

C<letter> and C<initial_string> can be given together to use a letter not at
the start of the C<initial_string>.  For example,

   $it = Math::Aronson->new (letter => 'T',
                             initial_string => "I think T is");
   # is 2, 7, 21, 23, ...
   # per "I think T is second, seventh, twenty-first, ..."

=item C<< without_conjunctions => $boolean >> (default false)

Strip conjunctions, meaning "and"s, in the wording so for instance "one
hundred and four" becomes "one hundred four".  The default is leave
unchanged whatever conjunctions C<Lingua::Any::Numbers> (or C<ordinal_func>
below) gives.

=item C<< conjunctions_word => $string >> (default "and" or "et")

The conjunction word to exclude if C<without_conjunctions> is true.  The
default is "and" for English or "et" for French.  For other languages
there's no default.

=item C<< ordinal_func => $coderef >> (default Lingua modules)

A function to call to turn a number into words.  Each call is

    $str = &$ordinal_func ($n);

The default is a call C<to_ordinal($n,$lang)> of C<Lingua::Any::Numbers>, or
for English and French a direct call to C<Lingua::EN::Numbers> or
C<Lingua::FR::Numbers>.  The string returned can be wide chars.

An explicit C<ordinal_func> can be used if C<Lingua::Any::Numbers> doesn't
support a desired language, or perhaps for a bit of rewording.

    $it = Math::Aronson->new
             (ordinal_func => sub {
                my ($n) = @_;
                return something_made_from($n);
              });

There's nothing to select a gender from C<Lingua::Any::Numbers>, as of
version 0.30, so an C<ordinal_func> might be used for instance to get
feminine forms from C<Lingua::ES::Numbers>.

=item C<< lying => $bool >> (default false)

A "lying" version of the sequence, where the positions described and
returned are those without the target letter.  So for example

    T is   the   second,         third, fifth, ...
      ^^    ^^   ^^^^^^           ^
      2,3,  5,6  7,8,9,10,11,12, 14, ...      <-- sequence

Starting from "T is the", the first position is a T so "first" is not
appended, but the second position is not a T so lie by giving "second", and
similarly the third position, but the fourth is a T so it doesn't appear.

=back

=back

=head2 Operations

=over

=item C<< $n = $it->next >>

Return the next number in the sequence, being the next position of T (or
whatever letter) in the text.  The first position is 1.

If the end of the sequence has been reached then the return is an empty list
(which means C<undef> in scalar context).  Because positions begin at 1 a
loop can be simply

    while (my $n = $it->next) {
      ...
    }

=back

=head1 IMPLEMENTATION NOTES

Accents are stripped using C<Unicode::Normalize> if available (Perl 5.8.0
and up), or a built-in Latin-1 table as a fallback otherwise.  The Latin-1
suits C<Lingua::FR::Numbers> and probably most of the European numbers
modules.

The Lingua modules and string processing means C<next> probably isn't
particularly fast.  It'd be possible to go numbers-only with the usual rules
for ordinals as words but generating just the positions of the "T"s or
whatever desired letter, but that doesn't seem worth the effort.

=head1 SEE ALSO

L<Lingua::EN::Numbers>,
L<Lingua::FR::Numbers>,
L<Lingua::Any::Numbers>

=head1 HOME PAGE

http://user42.tuxfamily.org/math-aronson/index.html

=head1 LICENSE

Math-Aronson is Copyright 2010, 2011 Kevin Ryde

Math-Aronson is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-Aronson is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-Aronson.  If not, see <http://www.gnu.org/licenses/>.

=cut
