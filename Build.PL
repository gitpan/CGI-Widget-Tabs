use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new(
		   license     => 'perl',
		   module_name => 'CGI::Widget::Tabs',
		   build_requires => {
				      'Test::Distribution'  => 1.14,
				      'Test::More'	    => 0,
				     },
		   requires    => {
				   'Carp'          => 0,
				   'HTML::Entities'=> 0,
				   'URI::Escape'   => 0,
				  },
		   sign        => 1,
		  )->create_build_script;
