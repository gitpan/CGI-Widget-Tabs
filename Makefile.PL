use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	     => 'CGI::Widget::Tabs',
    'VERSION_FROM'   => 'Tabs.pm', # finds $VERSION
    'PREREQ_PM'	     => {URI::Escape => 0, HTML::Entities => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?  ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Tabs.pm', # retrieve abstract from module
       AUTHOR        => 'Koos Pol <koos_pol@raketnet.nl>') : ()),
);
