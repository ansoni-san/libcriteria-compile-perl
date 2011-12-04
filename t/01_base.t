use Test::More tests => 2;

use_ok('Criteria::Compile');

ok( Criteria::Compile->new({})->exec({}),
    'basic instance compilable');
