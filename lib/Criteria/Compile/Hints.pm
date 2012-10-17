#!/bin/perl
#===================================================================================================================
#    Script:            Criteria/Compile/Hints.pm
#    purpose:           Set lexical hints for the Criteria::Compile(::*) family
#    date created:      09/03/2012
#    author:            Anthony (J) Lucas - anthony_lucas@discovery-europe.com
#    copyright:         Code and methodology copyright 2012 Discovery Networks Europe
#===================================================================================================================



package Criteria::Compile::Hints;
use parent qw(Exporter);


use strict;
use warnings;



use Criteria::Compile ( );
use Criteria::Compile::DateTime ( );



#CLASS VARS / CONFIG


my $CLS_HINTS_UNSET = {};
my $CLS_SHORTHAND = {
    OBJECT => q(Criteria::Compile::OBJECT),
    HASH => q(Criteria::Compile::HASH),
    DateTime => q(Criteria::Compile::DateTime),
};


use constant HPREFIX => 'criteria';
use constant HINT_USE_CLASS => HPREFIX().'/use_class';



#PRAGMA / EXPORTER INTERFACE


sub import {

    my $class = shift;
    #nothin' to do
    return unless @_;

    #handle both long and shorthand calls
    my %opts = (@_ > 1) ? @_ : (use_class => $_[0]); 
    #attempt shorthand expansions
    if (my $cls = $opts{use_class}) {
        $opts{use_class} = ($CLS_SHORTHAND->{$cls} || $cls);
    }

    #update hints
    foreach (keys(%opts)) {
        my $hkey = HPREFIX()."/$_";
        $^H{$hkey} = $opts{$_};
        $CLS_HINTS_UNSET->{$hkey} = 1;
    }
}


sub unimport {
    delete $^H{$_} foreach (keys(%$CLS_HINTS_UNSET))
}


sub class_in_effect {
    (caller(($_[0]//0)+1))[10]->{HINT_USE_CLASS};
}





1;