use strict;
use warnings;
use Test::More;

my (@pm_files, @classes);

my $Has_File_Find_Rule = eval 'use File::Find::Rule; 1';
my $Has_Test_Pod       = eval 'use Test::Pod 0.95; 1';
my $Has_Pod_Coverage   = eval 'use Pod::Coverage; 1';

if ($Has_File_Find_Rule and ($Has_Pod_Coverage or $Has_Test_Pod)) {
	@pm_files = File::Find::Rule->file()->name('*.pm')->in('blib/lib');
	@classes = map { my $x = $_;
			 $x =~ s|^blib/lib/||;
			 $x =~ s|/|::|g;
			 $x =~ s|\.pm$||;
			 $x;
		 } @pm_files;

	if($Has_Test_Pod and $Has_Pod_Coverage) {
		plan tests => 2 * scalar @pm_files;
	}
	else {
		plan tests => scalar @pm_files;
	}
}
else {
	plan skip_all => 'Need File::Find::Rule, Test::Pod>=0.95, Pod::Coverage installed to run these tests';
}

foreach my $file (@pm_files) {
	pod_file_ok($file);
}

foreach my $class (@classes) {
	 my $pc = Pod::Coverage->new(package => $class);
	 ok( ( $pc->coverage || 1 ) == 1, "Pod::Coverage test for $class");  # If there are no exported methods coverage will be unrated/undefined rather than 0 let this pass
 }
