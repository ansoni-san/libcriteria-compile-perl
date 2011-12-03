#!/bin/perl
#===========================================
#    Script:  Build.PL
#===========================================


use strict;
use Module::Build;


my $build = Module::Build->new(
    module_name => 'Criteria::Compile'
    dist_abstract => 'Describe wanted objects/data using grammar',
    license => 'perl',
    dist_author => 'A. J. Lucas <kaoyoriketsu@ansoni.com>',
    requires => {
        'Tie::IxHash' => 0,
        'DateTime' => 0,
        'Data::Dump::Streamer' => 0
    },
    create_makefile_pl => 'passthrough'
);
$build->create_build_script();



