#!/usr/bin/perl
#!/usr/bin/speedy

# $Id: tabs-demo.pl,v 1.17 2002/12/02 20:19:37 koos Exp $

use strict;
use warnings;
use CGI::Widget::Tabs;
use CGI::Widget::Tabs::Style;

my @styles = css_styles();
my $cgi = create_cgi_object();
exit if ! defined $cgi;

my $style_nr = $cgi->param("style") || 1;
$style_nr--;  # humans start with 1, lists at 0
print <<EOT;
Content-Type: text/html;

<head>
<title>CGI::Widget::Tabs - Demo</title>
<style type="text/css">
EOT
print $styles[$style_nr]->{style};
print <<EOT;
</style>
</head>
<body>
<h1>F1 - Team Simulation - 2002</h1>
EOT

my $main_tab = CGI::Widget::Tabs->new;  # first set up the main tab
$main_tab->cgi_object($cgi);            # access to the outside world
$main_tab->cgi_param("t");              # |comment this line out to see it will
                                        # |use the default value "tab"
$main_tab->headings( "Drivers", "Courses", "Cars", "Style sheets" ); # |The headings list is a plain list.
                                                 # |This means the actual words
                                                 # |are used in the URL.
$main_tab->class("my_tab");  # CSS base style to use

print "<p>This is the main tab</p>\n";
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


    ( $main_tab->active eq "Style sheets" ) && do {

        # -- We need to know how we got here. So we recreate the
        # -- query string, modify the style param, and feed it back
        # -- to the script. The script should then end up in the same
        # -- state as on the last mouse click.
        my $query_string = "";
        # why do we do this by hand ? $tab->active knows this
        # already. We should be able to access this info.
        foreach ( $cgi->param() ) {
            next if ( $_ eq "style" );
            $query_string .= "$_=".$cgi->param($_)."&";
        };
        chop $query_string;

        print <<EOT;
<p>Are you graphically enabled?
<a style="color:blue" href="mailto:koos_pol\@raketnet.nl?Subject=CGI::Widget::Tabs style sheet">
Send me</a> your own styles. I will gladly add them to this list!</p>
<table>
<tr style="font-weight: bold">
<td>Description</td>
</tr>
EOT
       my $style_num = 1 ;
       foreach my $style ( @styles ) {
           print "<tr>\n";
           print "<td>$style_num <a style=\"color:#000000\" href=\"?$query_string&style=$style_num\">".$style->{descr}."</a></td>\n";
           print "</tr>\n";
           $style_num++;
       }
       print "</table>\n";
   };
}



# run the selected details tab
if ( $main_tab->active ne "Style sheets" ) {
    print "<p>These are the details tabs.</p>\n";
    $details->wrap(4);   # after 4 headings we wrap to the next row
    $details->display ;  # there is no details for this one

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
}
print "</body>\n</html>";




# ---------------------------
sub create_cgi_object {
# ---------------------------
    if  ( ( eval {require CGI::Minimal; &CGI::Minimal::reset_globals; $cgi = CGI::Minimal->new} )
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


