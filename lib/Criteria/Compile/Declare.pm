#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  Copyright (C) 2011 - Anthony J. Lucas - kaoyoriketsu@ansoni.com



package Criteria::Compile::Declare;
use base qw( Exporter );
use parent qw( Criteria::Compile );



use strict;
use warnings;



require 5.14.0;
our $VERSION = '0.04__7';



#INIT CONFIG / VARS


my @EXPORT_SUBS = qw( criteria criteria_sub );
my @EXPORT_CONSTS = qw( ACC_OBJECT ACC_HASH );
our @EXPORT = ( @EXPORT_SUBS, @EXPORT_CONSTS );


*ACC_OBJECT = \&Criteria::Compile::ACC_OBJECT;
*ACC_HASH = \&Criteria::Compile::ACC_HASH;



use constant DIE_MALFORMED_CRITERIA_ARGS =>
    q/Malformed Criteria. It looks like you intended to supply criteria/
    .q/but we couldn't read it. Perhaps check its contents?/;



#INITIALISATION ROUTINES


sub new {

    my ($class, @args) = @_;
    Criteria::Compile->new(@args);
}



#PROTOTYPE-BASED HELPER INTERFACE


sub criteria_sub (+@) {
    (&criteria)->export_sub;
}


sub criteria (+@) {

    my ($mode, @crit) = _extract_crit(@_);

    #die if it looks like we should have something,
    #to stop users blindly using blank criteria (which will always match)
    die DIE_MALFORMED_CRITERIA_ARGS unless (!@_||@crit);

    #create default instance
    return __PACKAGE__->new(@crit) unless ($mode);

    #or, create instance with custom access mode
    my $inst = __PACKAGE__->new;
    $inst->add_criteria(@crit);
    $inst->access_mode($mode) or die DIE_MALFORMED_CRITERIA_ARGS;
    return $inst;
}



#UTIL ROUTINES


sub _extract_crit {

    my $first_ref = ref($_[0]);

    #handle odd numbered list as mode prefixed
    unless ($first_ref) {
        return (@_ % 2 && @_ > 1) ? (pop, @_) : (undef, @_);
    }
    #handle standard refs
    return ($_[1], %{$_[0]}) if ($first_ref eq 'HASH');
    return ($_[1], @{$_[0]}) if ($first_ref eq 'ARRAY');
    return undef;
}





1;
