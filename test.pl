# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
BEGIN { plan tests => 9 };
use CGI::Widget::Tabs;

if ( cgi_available() ) {
    ok(1); # If we made it this far, we're ok.

    ok("Tab 1", active( { headings => ["Tab 1", "Tab 2"] } ) );

    ok("Tab 2", active( { headings => ["Tab 1", "Tab 2"],
                          default  => "Tab 2" } ) );

    ok("Tab 2", active( { headings => ["Tab 1", "Tab 2"],
                          query    => "Tab 2" } ) );

    ok("Tab 3", active( { headings => ["Tab 1", "Tab 2", "Tab 2"],
                          default  => "Tab 2",
                          query    => "Tab 3"} ) );

    ok("-t1", active( { headings => [ "-t1" => "Tab 1", "-t2" => "Tab 2"] } ) );

    ok("-t2", active( { headings => [ "-t1" => "Tab 1", "-t2" => "Tab 2"],
                        default  => "-t2" } ) );

    ok("-t2", active( { headings => ["-t1" => "Tab 1", "-t2" => "Tab 2"],
                        query    => "-t2" } ) );

    ok("-t3", active( { headings => ["-t1" => "Tab 1", "-t2" => "Tab 2", "-t3" => "Tab 3"],
                        default  => "-t2" ,
                        query    => "-t3"} ) );
}

#########################

sub active {
    my $args = shift;
    @headings = @{ $args->{headings} };
    $default  = $args->{default};
    $query    = $args->{query};

    if ( $cgi = cgi_available() ) {
        my $tab = CGI::Widget::Tabs->new;
        $tab->cgi_object($cgi);
        $tab->headings(@headings);
        $tab->default($default) if $default;
        $tab->cgi_param('tab');
        $cgi->param('tab'=>$query);
        return $tab->active();
    }
}


sub cgi_available {
    if  ( (eval {require CGI; $cgi = CGI->new} ) or
          (eval {require CGI::Minimal; $cgi = CGI::Minimal->new} ) ) {
        return $cgi;
    } else {
        warn "##\n";
        warn "## Unable to load CGI or CGI::Minimal. Skipping tests...\n";
        warn "## Note that eventually you do need CGI or CGI::Minimal.\n";
        warn "##\n";
        return 0;
    }
}
