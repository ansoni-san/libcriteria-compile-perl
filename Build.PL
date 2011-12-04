#!/bin/perl
#===========================================
#    Script:  Build.PL
#===========================================


use strict;
use Module::Build;


my $build = Module::Build->new(
    module_name => 'Criteria::Compile',
    dist_abstract => 'Describe wanted objects/data using grammar',
    license => 'perl',
    dist_author => 'A. J. Lucas <kaoyoriketsu@ansoni.com>',
    build_requires => {
        'Test::More' => 0
    },
    requires => {
        'Tie::IxHash' => 0,
        'DateTime' => 0,
        'Data::Dump::Streamer' => 0
    },
    create_makefile_pl => 'traditional'
);
$build->create_build_script();



