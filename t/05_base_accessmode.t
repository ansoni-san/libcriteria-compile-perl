#!/bin/perl


use strict;
use warnings;

use Test::More tests => 4;
use Carp;



use constant CC_CLASS => 'Criteria::Compile';
use_ok(CC_CLASS());


#create test data

our %test_data;
BEGIN {
    %test_data = (
        name => 'name',
        ten => 10,
        hundred => 100
    );
}

my %test_crit = ();
foreach (keys(%test_data)) {
    $test_crit{"${_}_is"} = $test_data{$_};
}


#create test criteria

my $crit = CC_CLASS()->new(%test_crit);
ok( $crit, 'create test criteria');


#test object access mode

ok( ($crit->access_mode(CC_CLASS()->ACC_OBJECT())
    and $crit->exec(bless({}, 'TestPackage'))),
    'match using object access mode' );


#test hash access mode

ok( ($crit->access_mode(CC_CLASS()->ACC_HASH())
    and $crit->exec(\%test_data)),
    'match using hash access mode' );


done_testing();




package TestPackage;

BEGIN {
    no strict 'refs';
    foreach (keys %main::test_data) {
        *{"TestPackage\::$_"} = eval("sub { \$::test_data{$_} }");
    }
}

