#!/usr/bin/perl -w

# $Id: tabs-demo.pl,v 1.7 2002/08/17 12:00:21 koos Exp $

use strict;
use warnings;
use CGI::Widget::Tabs;
use CGI;

print <<EOT;
Content-Type: text/html;

<head>
<style type="text/css">
table.my_tab     { border-bottom: solid thin black }
td.my_tab        { padding: 2 12 1 12; background-color: #FAFAD2; border: solid thin #BABAA2 }
td.my_tab_actv   { padding: 2 12 1 12; background-color: #C0D4E6; font-weight: bold; border: solid thin black }
td.my_tab_spc    { width: 15 }
</style></head>
<body><center>
<h1>F1 - Team Simulation - 2002</h1>
EOT

my $cgi = CGI->new;
my $main_tab = CGI::Widget::Tabs->new;  # first set up the main tab
$main_tab->cgi_object($cgi);    # access to the "outside world"
$main_tab->headings( -d => "Drivers", -t => "Courses", -c => "Cars" ); # -t = track
$main_tab->class("my_tab");     # CSS base style to use
$main_tab->display;
print "<br>";

# predefine the possible details tabs.
# note how none of the headings are visisble in the URL query params!
my $details_tabs = {
    # Drivers tab: selected if from the main tab -d is returned
    -d => { headings   => [ -jpm => "J.P. Montoya",
                            -rs  => "R. Shumacher",
                            -ms  => "M. Shumacher",
                            -rb  => "R. Barichello",
                            -dc  => "D. Coulthard",
                            -ms  => "M. Salo" ],
            cgi_param  => "dd"  },  # _details _drivers

    # Course tab: selected if from the main tab -t is returned
    -t => { headings   => [ -mc => "Monte Carlo",
                            -s  => "Silverstone",
                            -n  => "Nurburgring",
                            -m  => "Monza" ],
            cgi_param  => "dt"  },  # _details _tracks

    # Cars tab: selected if from the main tab -c is returned
    -c => { headings   => [ -f   => "Ferrari",
                            -bmw => "BMW Williams",
                            -mm  => "McLaren Mercedes" ],
            cgi_param  => "dc" }  # _details _cars
};

# details triggered by the main tab
my $selected_details = $details_tabs->{$main_tab->active};

# set up a details tab
my $details = CGI::Widget::Tabs->new;

# comm link with the outside world
$details->cgi_object($cgi);

# this details tab is identified by it's own cgi_param
$details->cgi_param($selected_details->{cgi_param});

# likewise, it's heading are also hand-picked
$details->headings( @{ $selected_details->{headings} } );

# we'll use the same style sheet for now
$details->class("my_tab");

# run the lot
$details->display;

print "<br>We now should run some intelligent code ";
print "to process <strong>", $details->active,"</strong><br>";
if ( $details->active eq '-ms' ) {
    print <<EOT;
    <br><font color="red">
    WHOAA!  There are two driver details tabs identified by the same
    value &quot;-ms;&quot;</font>
EOT
}
print "</center></body></html>";

