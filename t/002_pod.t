use strict;
use warnings;
use Test::More;

my @pm_files;

my $Has_File_Find_Rule = eval 'use File::Find::Rule; 1';
my $Has_Test_Pod       = eval 'use Test::Pod 0.95; 1';

if ($Has_File_Find_Rule and $Has_Test_Pod) {
	@pm_files = File::Find::Rule->file()->name('*.pm')->in('lib');
	plan tests => scalar @pm_files;
}
else {
	plan skip_all => 'Need File::Find::Rule and Test::Pod>=0.95 installed to run these tests';
}

foreach my $file (@pm_files) {
	pod_file_ok($file);
}
