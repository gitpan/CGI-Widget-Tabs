#!/usr/bin/perl

# $Id: tabs-demo.pl,v 1.12 2002/11/03 19:38:32 koos Exp $

use strict;
use warnings;
use CGI::Widget::Tabs;

my $cgi = create_cgi_object();
exit if ! defined $cgi;

print <<EOT;
Content-Type: text/html;

<head>
<title>CGI::Widget::Tabs - Demo</title>
<style type="text/css">
table.my_tab     { border-bottom: solid thin black }
td.my_tab        { padding: 2 12 1 12; background-color: #FAFAD2; border: solid thin #BABAA2 }
td.my_tab_actv   { padding: 2 12 1 12; background-color: #C0D4E6; font-weight: bold; border: solid thin black }
td.my_tab_spc    { width: 10 }
</style></head>
<body><center>
<h1>F1 - Team Simulation - 2002</h1>
EOT

my $main_tab = CGI::Widget::Tabs->new;  # first set up the main tab
$main_tab->cgi_object($cgi);            # access to the outside world
$main_tab->cgi_param("t");              # |comment this line out to see it will
                                        # |use the default value "tab"
$main_tab->headings( qw/Drivers Courses Cars/ ); # |The headings list is a plain list.
                                                 # |This means the actual words
                                                 # |are used in the URL.
$main_tab->class("my_tab");  # CSS base style to use
$main_tab->display;  # paint the tab

print "<br>";  # I could probably use some CSS bottom margin too.

# --- Predefine the possible details tabs.
# --- Notice how the details tabs are a mix of simple headings and
# --- OO headings. Various configuration methods are used to illustate
# --- possible uses.
# ---
# --- Usually multiple tabs can be configured much cleaner and more efficient
# --- For instance a hash containing a complete menu structure plus options
# --- can be made in a flash. The reason things look a bit chaotic,
# --- it is to allow all options being demonstrated.

# Set up the details tab. The first few methods are common methods:
my $details = CGI::Widget::Tabs->new;
$details->cgi_object($cgi); # access to the outside world
$details->class("my_tab");  # we'll use the same style sheet as the main tab

# --- Differentiate based on the active heading from the main tab

HEADINGS: {
    # - This tab uses simple headings:
    ( $main_tab->active eq "Courses" ) && do {
        $details->headings( "Monte Carlo", "Silverstone", "Nurburgring", "Monza" );
        $details->cgi_param("dt");  # _details _tracks
        last HEADINGS;
    };

    # - This tab uses simple headings too, but k/v pairs:
    ( $main_tab->active eq "Drivers" ) && do {
        $details->headings( -jpm => "J.P. Montoya",
                            -rs  => "R. Shumacher",
                            -ms  => "M. Shumacher",
                            -rb  => "R. Barichello",
                            -dc  => "D. Coulthard",
                            -ms  => "M. Salo" );
        $details->cgi_param("dd"); # _details _drivers
        last HEADINGS;
    };


    # - This tab goes for the OO approach
    ( $main_tab->active eq "Cars" ) && do {
        my $h;

        $h = $details->heading;   # add a heading
        $h->text("Ferrari");      # text to display

        $h = $details->heading;   # add another heading
        $h->raw_text("McLaren&nbsp;Mercedes");  # preformatted text to display

        $h = $details->heading;   # add another heading
        $h->text("BMW Williams"); # text to display...
        $h->key("bmw");           # ...but key to use

        $h = $details->heading;   # add another heading
        $h->text("Chrysler");     # |we don't have F1 records on Chrysler
                                  # |redirect to Chrysler homepage instead
        $h->url("http://www.chrysler.com");
        $h->key("chr");           # this statement is useless. we don't use
                                  # the default self refer. URL but a tailored one

        $details->cgi_param("dc");  # _details _cars
        last HEADINGS;
    };
}

# run the selected details tab
$details->display;

print "<br>We now should run some intelligent code ";
print "to process <strong>", $details->active,"</strong><br>\n";
if ( $details->active eq '-ms' ) {
    print <<EOT;
<br>
<font color="red">
WHOAA!  There are two tab headings identified by the same
value &quot;-ms;&quot;</font>
EOT
}
print "</center>\n</body>\n</html>";


# ---------------------------
sub create_cgi_object {
# ---------------------------
    if  ( ( eval {require CGI::Minimal; $cgi = CGI::Minimal->new} )
          or
          ( eval {require CGI; $cgi = CGI->new} )
        ) {
        return $cgi;
    }
    # - This is error handling. As such, it should be taken care
    # - of by the caller. But I didn't wanted to clutter the main code.
    print <<EOT;
Content-Type: text/html;

<head>
<title>ERROR</title>
<body>CGI not found and CGI::Minimal not found.</body></html>
EOT
    return undef
}



