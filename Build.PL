use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new(
		   license     => 'perl',
		   module_name => 'CGI::Widget::Tabs',
		   requires    => {
				   'Carp'          => 0,
				   'HTML::Entities'=> 0,
				   'Test::More'	   => 0,
				   'URI::Escape'   => 0,
				  },
		   sign        => 1,
		  )->create_build_script;
