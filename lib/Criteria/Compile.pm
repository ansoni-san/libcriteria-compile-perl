#!/bin/perl
#===================================================================================================================
#    Script:            Compile.pm
#    purpose:           N/A
#    date created:      11/26/2011
#    author:            Anthony (J) Lucas
#===================================================================================================================



package Criteria::Compile;



use strict;
use warnings;



use UNIVERSAL ( );
use Tie::IxHash ( ); 
use DateTime ( );



#INIT CONFIG / VARS


use constant DATETIME_CLASS => 'DateTime';


use constant {
    TYPE_STATIC => 10,
    TYPE_CHAINED => 20,
    TYPE_DYNAMIC => 30
};

my $DEFAULT_CRITERIA_DISPATCH_TBL = {
    TYPE_STATIC() => {},
    TYPE_CHAINED() => {},
    TYPE_DYNAMIC() => {
        qw/^(.*)_like$/ => qw/_gen_like_sub/,
        qw/^(.*)_matches$/ => qw/_gen_matches_sub/,
        qw/^(.*)_is$/ => qw/_gen_is_sub/,
        qw/^(.*)_less_than$/ => qw/_gen_less_than_sub/,
        qw/^(.*)_greater_than$/ => qw/_gen_greater_than_sub/,
        qw/^(.*)_sooner_than$/ => qw/_gen_sooner_than_sub/,
        qw/^(.*)_later_than$/ => qw/_gen_later_than_sub/
    }
};



#INITIALISATION ROUTINES


sub new {

    my ($class, $crit) = @_;
    my $self = bless(
        {dispatch_tbl => {}, exec_sub => sub { 1 }},
        $class);

    $self->_init($crit);
    return $self;
}

sub _init {

    my ($self, $crit) = @_;

    #initialise default criteria dispatch tbls
    my $ordered_dt = ($self->{dispatch_tbl} = {});
    foreach (keys($DEFAULT_CRITERIA_DISPATCH_TBL)) {
        #perserve order
        tie(my %dt, 'Tie::IxHash')
            ->Push(%{$DEFAULT_CRITERIA_DISPATCH_TBL->{$_}});
        $ordered_dt->{$_} = \%dt;
    }
    #validate any criteria supplied
    if ($crit) {
        $self->add_criteria(%$crit);
        die('Error: Failed to compile criteria.')
            unless ($self->compile());
    } else {
        $self->compile(0);
    }
    return 1;
}



#CRTIERIA COMPILATION ROUTINES


sub export_sub {
    my $self = $_[0];
    $self->{exec_sub} ||= $self->compile();
}


sub add_criteria {
    my $self = shift;
    return 0 unless (@_ > 2);

    $_[2] ||= TYPE_STATIC;
    !(!push(
        @{$self->{criteria}->{$_[3]}},
        {@_[0,1]}));
}


sub define_criteria {
    my $self = $_[0];
    (scalar(@_) > 2) and 
        ($self->{dispatch_tbl}->{$_[2]}
            = $self->_bless_handler($_[3]));
}


sub compile {
	
    my ($self, $crit) = @_;
    my @action_list = ();

    my @crit_list = @{$self->{criteria}};
    push(@crit_list, $crit) if $crit;

    #attempt to build subs for criterid
    #SIDE-STEP FAILURE CONDItion compexity with blanket eval
    my $last_crit = '';
    eval {
        my ($sub, @args);
        foreach (keys(%$crit)) {
            $last_crit = $_;
            #lookup handler generator
            ($sub, @args) = $self->resolve_dispatch($_);
            next unless ($sub);
            #execute and store sub from generator
            push(@action_list,
                ((ref($sub) eq '')
                    ? $self->$sub($crit->{$_}, @args)
                    : $sub->($self, $crit->{$_}, @args)));
        }
        #compile all action subs into single sub
        ($self->{exec_sub} = $self
            ->_compile_exec_sub(\@action_list))
    };
    if ($@) {
        chomp($@);
        print("Error: Check if `$last_crit` is valid. ($@)\n");
    }
    return $@ ? 0 : 1;
}


sub resolve_dispatch {

    my ($self, $crit) = @_;
    my $dispatch_tbl = $self->{dispatch_tbl};

    #attempt quick static lookup
    my $sub = $dispatch_tbl->{TYPE_STATIC()}->{$crit};
    return $sub if ($sub);

    #attempt more expensive lookups
    my ($dtype_tbl, @matches, @args);
    RESOLVE_CRIT: foreach (TYPE_CHAINED, TYPE_DYNAMIC) {
        $dtype_tbl = $dispatch_tbl->{$_};
        @matches = reverse(keys(%$dtype_tbl));
        foreach (@matches) {

            next unless ($crit =~ /$_/);
            $sub = $dtype_tbl->{$_};
            if ($sub) {
                #attempt to retrieve subref if not a method
                $sub = ((exists &$sub) ? \&$sub : $sub)
                    unless (UNIVERSAL::can($self, $sub));
                #prepare args for generator    
                @args = map {  $+[$_]
                    ? substr($crit, $-[$_], $+[$_] - $-[$_])
                    : undef } 1..$#-;
                last RESOLVE_CRIT;
            }
        }
    };
    return ($sub, @args);
}


sub _export_getter {
    return sub {
        my ($ob, $op) = @_;
        return &UNIVERSAL::can($ob, $op)
            ? $ob->$op()
            : undef;
    };
}


sub _compile_exec_sub {
    
    my ($self, $actions) = @_;
    #create single multi-action execution sub
    my $sub = sub {
	    my @args = @_;
        foreach (@$actions) {
            return 0 unless ($_->(@args));
        }
        return 1;
    };
    #return sub or experimental flat sub
    return $self->{COMPILE_EXPERIMENTAL}
        ? $self->_expr_flatten_sub($sub)
        : $sub;
}

#EXPERIMENTAL
{
    #private vars
    my $ret_stmt = 'return 1;';
    my $ret_repl = 'return 0 unless';

    #public subs
    sub _expr_flatten_sub {

        my @frags = Data::Dump::Streamer::Dump(@_);
        my @matches;
        foreach (@frags) {
            #NOTE : SUPER FRAGILE, NOT VERY USEFUL
            #       FIND A BETTER WAY!!
            if (@matches = ($_ =~ /^(.*[\^w])return([^\w].*)$/)) {
                $_ = join('', $matches[0], $ret_repl, $matches[1]);
            }
        }
        push(@frags, $ret_stmt);
        return eval(join('',
            'sub { ', @frags, ' }'));
    }
}


#CRITERIA FACTORY ROUTINES


sub _gen_is_sub {

    my ($context, $val, $op) = @_;
    my $get = $context->export_getter();
    return unless ($op);
    return sub {
        (ref($_[0])
            and (local($_) = $get->($_[0], $op)))
            ? ($_ eq $val)
            : 0;
    };
}


sub _gen_like_sub {

    my ($context, $val, $op) = @_;
    my $get = $context->export_getter();
    return unless ($op);
    return sub {
        (ref($_[0])
            and (local($_) = $get->($_[0], $op)))
            ? scalar($_ =~ qr/$val/)
            : 0;
    };
}


sub _gen_matches_sub {

    my ($context, $val, $op) = @_;
    my $get = $context->export_getter();
    return unless ($op);
    return sub {
        (ref($_[0])
            and (local($_) = $get->($_[0], $op)))
            ? ($_ ~~ $val)
            : 0;
    };
}


sub _gen_less_than_sub {

    my ($context, $val, $op) = @_;
    my $get = $context->export_getter();
    return unless ($op);
    return sub {
        (ref($_[0])
            and (local($_) = $get->($_[0], $op)))
            ? ($_ lt $val)
            : 0;
    };
}


sub _gen_greater_than_sub {

    my ($context, $val, $op) = @_;
    my $get = $context->export_getter();
    return unless ($op);
    return sub {
        (ref($_[0])
            and (local($_) = $get->($_[0], $op)))
            ? ($_ gt $val)
            : 0;
    };
}


sub _gen_sooner_than_sub {

    my ($context, $val, $op) = @_;
    my $get = $context->export_getter();
    return unless ($op);
    return unless (ref($val) eq 'HASH');
    return unless ($val = DATETIME_CLASS()
        ->now()->add_duration(%$val));
    return sub {
        (ref($_[0])
            and (local($_) = $get->($_[0], $op)))
            ? ($_->subtract($val)->is_negative())
            : 0;
    };
}


sub _gen_later_than_sub {

    my ($context, $val, $op) = @_;
    my $get = $context->export_getter();

    return unless ($op);
    return unless (ref($val) eq 'HASH');
    return unless ($val = DATETIME_CLASS()
        ->now()->add_duration(%$val));
    return sub {
        (ref($_[0])
            and (local($_) = $get->($_[0], $op)))
            ? ($_->subtract($val)->is_positive())
            : 0;
    };
}




1;



