use strict;
use warnings;
use Test::More;

my $Has_Test_Signature = eval "use Test::Signature; 1";

if($Has_Test_Signature) {
	plan tests =>1;
	signature_ok();
}
else {
	plan skip_all => 'Need Test::Signature installed to run these tests';
}
