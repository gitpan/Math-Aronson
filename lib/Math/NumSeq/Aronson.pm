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

package Math::NumSeq::Aronson;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 6;

use Math::NumSeq;
@ISA = ('Math::NumSeq');

# use Math::NumSeq::Base::File;
# use Math::NumSeq::Base::FileWriter;

# uncomment this to run the ### lines
#use Devel::Comments;

# use constant name => 'Aronson\'s Sequence';
use constant description => ('Aronson\'s sequence of the positions of letter "T" in self-referential "T is the first, fourth, ...".  Or French "E est la premiere, deuxieme, ...".  See the Math::Aronson module for details.');
use constant values_min => 1;
use constant characteristic_monotonic => 1;
use constant parameter_info_array =>
  [
   {
    name      => 'lang',
    share_key => 'aronson_lang', # restricted en/fr
    display   => ('Language'),
    type      => 'enum',
    default   => '',
    # Can't offer all langs as there's no "initial_string" except en and fr
    # if (eval { require Lingua::Any::Numbers }) {
    #   push @langs, sort map {lc} Lingua::Any::Numbers::available();
    #   @langs = List::MoreUtils::uniq (@langs);
    # }
    choices => ['en','fr'],
    choices_display => [('EN'),('FR')],
    #        en => ('English'),
    #        fr => ('French'));
    # %Math::Gtk2::Drawing::aronson_lang::EnumBits_to_display
    #   = ((map {($_,uc($_))} @langs),
   },
   {
    name    => 'letter',
    display => ('Letter'),
    type    => 'enum',
    default => '',
    choices => ['', 'A' .. 'Z'],
   },
   {
    name      => 'conjunctions',
    display => ('Conjunctions'),
    type    => 'boolean',
    default => 1,
    description => ('Whether to include conjunctions "and" or "et" in the words of the sequence.'),
   },
   {
    name    => 'lying',
    display => ('Lying'),
    type    => 'boolean',
    default => 0,
    description => ('Whether to show the "lying" version of the sequence, being positions which are not "T" (or whatever requested letter).'),
   }
  ];

# cf A072886    lying=>1, initial_string=>"S ain't the"
#    A072887    complement of lying A081023
#    A081024    complement of lying "S ain't" A072886
#    A072421    Latin P
#    A072422    Latin N
#    A072423    Latin T
#
my %oeis_anum =
  ('en,t,0,0' => 'A005224',  # english T, no conjunctions
   # OEIS-Catalogue: A005224 conjunctions=0

   'en,h,0,0' => 'A055508',  # english H, no conjunctions
   # OEIS-Catalogue: A055508 letter=H conjunctions=0

   'en,i,0,0' => 'A049525',  # english I, no conjunctions
   # OEIS-Catalogue: A049525 letter=I conjunctions=0

   'en,t,0,1' => 'A081023',  # english T, lying
   # OEIS-Catalogue: A081023 lying=1 conjunctions=0

   'fr,i,0,1' => 'A080520',  # french E
   # OEIS-Catalogue: A080520 lang=fr
  );
sub oeis_anum {
  my ($self) = @_;
  my $aronson = $self->{'aronson'};
  ### oeis_anum key: join(',', map {$aronson->{$_}||0} 'lang','letter','conjunctions','lying') 
  return $oeis_anum{join(',',
                         map {$aronson->{$_}||0}
                         'lang','letter','conjunctions','lying')};
}

# sub new {
#   my ($class, %options) = @_;
# 
#   my $aronson 
# 
#   # my $vfw = Math::NumSeq::FileWriter->new
#   #   (package => __PACKAGE__,
#   #    hi      => $hi);
# 
#   return bless { aronson => $aronson,
#                  lang => $lang,
#                  letter => $aronson->{'letter'},
#                  # vfw     => $vfw,
#                }, $class;
# }
sub rewind {
  my ($self) = @_;

  require Math::Aronson;
  my $lang = ($self->{'lang'} || 'en');
  my $letter = $self->{'letter'};
  my $conjunctions = ($self->{'conjunctions'} ? 1 : 0);
  my $lying = ($self->{'lying'} ? 1 : 0);

  # my $letter_opt = (defined $letter ? $letter : '');
  # my $options = "$lang,$letter_opt,$conjunctions,$lying";
  # if (my $vf = Math::NumSeq::File->new (package => __PACKAGE__,
  #                                                 options => $options,
  #                                                 hi => $hi)) {
  #   ### use ValuesFile: $vf
  #   return $vf;
  # }
  # my $hi = $self->{'hi'};

  $self->{'i'} = 0;
  $self->{'aronson'} = Math::Aronson->new
    (# hi                   => $hi,
     lang                 => $lang,
     letter               => $letter,
     without_conjunctions => ! $conjunctions,
     lying                => $lying,
    );
}
sub next {
  my ($self) = @_;
  ### Aronson next(): $self->{'i'}
  return ($self->{'i'}++, $self->{'aronson'}->next);
}

1;
__END__
