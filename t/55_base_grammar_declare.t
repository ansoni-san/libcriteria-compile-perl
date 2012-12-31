#!/bin/perl


use strict;
use warnings;

use Test::More tests => 4;
use Carp;


BEGIN {
    use constant CC_CLASS => 'Criteria::Compile::Declare';
    use_ok(CC_CLASS());
    CC_CLASS->import();
}



#create test criteria

our %test_data;
BEGIN {
    %test_data = (
        key_map => { 1000..1049 },
        name => 'name',
        number => rand(10)**rand(5),
        ten => 10,
        hundred => 100
    );
    my @keys = keys(%{$test_data{key_map}});
    $test_data{key} = $keys[rand(scalar(@keys)-1)];
}


my %criteria = (
    name_is => $test_data{name},
    number_like => qr/^[\d\.]+$/,
    ten_greater_than => 9,
    hundred_less_than => 200,
    key_in => [keys(%{$test_data{key_map}})],
    key_matches => $test_data{key_map}
);


#create test object

my $criteria;
my $test_obj = bless({%test_data}, 'TestPackage');


#basic criteria test

$criteria = criteria undef_like => undef; #always-match trick
ok( $criteria->exec({}),
    'base criteria checking works, no grammar');

#basic grammar test via &criteria

$criteria = criteria %criteria;
ok( $criteria->exec($test_obj), 
    'base grammar works via &criteria' );


#basic grammar test via &criteria_sub

$criteria = criteria_sub %criteria;
ok( $criteria->($test_obj), 
    'base grammar works via &criteria_sub' );





#test compelted
done_testing();





package TestPackage;

BEGIN {
    no strict 'refs';
    foreach (keys %main::test_data) {
        *{"TestPackage\::$_"} = eval("sub { \$::test_data{$_} }");
    }
}


