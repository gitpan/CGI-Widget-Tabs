package CGI::Widget::Tabs;

use 5.006;
use strict;
use warnings;

use URI::Escape();
use HTML::Entities();

our $VERSION = '1.2';

use vars qw/$self @headings $heading $heading_key $heading_text
            $really_active $active $cgi $cgi_param $params
            $class $spacer @html/;

# ----------------------------------------------
sub new {
# ----------------------------------------------
    my $proto = shift;
    my $class = ref($proto) || $proto;
    $self = {};
    bless ($self, $class);
    return $self;
}



# ----------------------------------------------
sub headings {
# ----------------------------------------------
    #
    #  ( "Software", "Hardware, ...) or ( -sw=>"Software", -hw=>"Hardware", ... );
    #
    $self = shift;
    if ( @_ ) {
        $self->{headings} = [ @_ ];
        return;
    };
    return @{ $self->{headings} || [] };
}



# ----------------------------------------------
sub cgi_param {
# ----------------------------------------------
    #
    # CGI parameter specifing the tab. Defaults to "tab".
    #
    $self = shift;
    if ( @_ ) {
        $self->{cgi_param} = shift;
        return;
    }
    return $self->{cgi_param}||'tab';
}



# ----------------------------------------------
sub default {
# ----------------------------------------------
    #
    # The default active tab
    #
    $self = shift;
    if ( @_ ) {
        $self->{default} = shift;
        return;
    }
    return $self->{default}
}



# ----------------------------------------------
sub cgi_object {
# ----------------------------------------------
    #
    # The cgi object to retrieve the parameters from.
    # Could be a CGI object or a CGI::Minimal object.
    #
    $self = shift;
    if ( @_ ) {
        $self->{cgi_object} = shift;
        return;
    }
    return $self->{cgi_object};
}



# ----------------------------------------------
sub class {
# ----------------------------------------------
    #
    # The CSS class for display of the tabs
    # Defaults to 'tab'.
    #
    $self = shift;
    if ( @_ ) {
        $self->{class} = shift;
    }
    return $self->{class} || 'tab';
}



# ----------------------------------------------
sub active {
# ----------------------------------------------
    #
    # The active pab page
    # In order of precendence:
    # 1. The tab clicked by the user
    # 2. The default tab
    # 3. The first tab in the list
    #
    $self = shift;
    $really_active = $self->cgi_object->param($self->cgi_param);

    if ( $really_active ) {  # tab has been clicked
        return $really_active;
    }
    return $self->default || ($self->headings)[0]; # the default tab or the first
}



# ----------------------------------------------
sub display {
# ----------------------------------------------
    #
    # save a few keystrokes
    #
    print $self->render;
}



# ----------------------------------------------
sub render {
# ----------------------------------------------
    #
    # Process the lot and display it.
    #
    $self        = shift;
    $cgi         = $self->cgi_object;
    @headings    = $self->headings;  # we either get ( "Tab1", "Tab2", ... ) or ( -t1=>"Tab1", -t2=>"Tab2", ... );
    $class       = $self->class;
    $cgi_param   = $self->cgi_param;
    $active      = $self->active;
    $spacer      = '<td class="'.$class.'_spc"></td>';
    @html = ();

    push @html, '<table class="',$class,'">',"\n<tr>\n";
    push @html, $spacer,"\n";

    # reproduce the URL incl all CGI params, _except_ the varying tab
    $params = "";
    foreach ( $cgi->param() ) {
        next if $_ eq $cgi_param;
        $params .= $_.'='.URI::Escape::uri_escape($cgi->param($_)).'&';
    }  # now we only have to add the tab cgi_param + value

    if ( @headings ) {
        # --- Did we get the -t=>"Tab" version?
        if ( substr($headings[0],0,1) eq '-' ) {
            while ( @headings ) {
                $heading_key  = shift @headings;
                $heading_text = shift @headings;
                push @html, '<td class="',$class;
                push @html, '_actv' if $heading_key eq $active;
                push @html, '">';
                push @html, &_link($heading_text,'?'.$params.$cgi_param.'='.URI::Escape::uri_escape($heading_key));
                push @html, "</td>";
                push @html, $spacer,"\n";
            }
        } else {
            # --- No, we got the ("Tab1", "Tab2", ...)  version.
            foreach $heading ( @headings ) {
                push @html, '<td class="',$class;
                push @html, '_actv' if $heading eq $active;
                push @html, '">';
                push @html, &_link($heading,'?'.$params.$cgi_param.'='.URI::Escape::uri_escape($heading));
                push @html, "</td>";
                push @html, $spacer,"\n";
            }
        }
    }
    push @html, "</tr>\n</table>\n";
    return join("",@html);
}



# ----------------------------------------------
sub _link {
# ----------------------------------------------
    #
    # Internal. Create a link for some text to a URI
    # Expects = (<text>,<url>) pair.
    #
    return '<a href="'.$_[1].'">'.HTML::Entities::encode_entities($_[0]).'</a>';
}

1;
__END__

=head1 NAME

CGI::Widget::Tabs - Create tab widgets in HTML

=head1 SYNOPSIS

    use CGI::Widget::Tabs;
    my $tab = CGI::Widget::Tabs->new;

    use CGI;
    my $cgi = CGI->new;          # interface to the query params
    $tab->headings(@titles);     # e.g. qw/Drivers Cars Courses/
    $tab->default("Courses");    # the default active tab
    $tab->active;                # the currently active tab
    $tab->class("my_tab");       # the CSS class to use for markup
    $tab->cgi_object($cgi);      # the object holding the query params
    $tab->cgi_param("t");        # the CGI query parameter to use
    $tab->render;                # the resulting HTML code
    $tab->display;               # same as `print $tab->render'

    # See the EXAMPLE section for a complete example

=head1 DESCRIPTION

CGI::Widget::Tabs lets you simulate tab widgets in HTML. You could benefit
from tabs if you want to serve only one page. Depending on the tab selected
you fetch and display the underlying data. There are two main reasons for
taking this approach:

1. For the end user not to be directed to YAL or YAP (yet another link / yet
another page), but keep it all together: The single point of entry paradigm.

2. For the Perl hacker to generate and display multiple data sources within
the same script environment.

The nice thing about CGI::Widget::Tabs is that the tabs now their internal
state. So you can ask a tab for instance which tab page is highlighted. This
way you get direct feedback on what the user clicked.

=head2 "Hey Gorgeous!"

Ofcourse tabs are useless if you can't "see" them. Without proper make up
they print as ordinary text. So you really need to fancy them up with some
eye candy. The designed way is that you provide a CSS style sheet and have
CGI::Widget::Tabs use that. See the class() method for how to do this.



=head1 METHODS OVERVIEW

=over 4

=item B<new()>

Returns a new CGI::Widget::Tabs object



=item B<headings(LIST)>

LIST are the headings to be displayed on the tabs. You can specify LIST in
two ways:

=over 4

=item * a plain list

=item * a keyword/value list

=back

Example:

    $self->headings( qw/Planes Traines Automobiles/ );

    $self->headings( -p=>"Planes", -t=>"Traines, -a=>"Autombiles" );

The keyword/value list comes in handy if you don't want to check the value
returned by active() against very long words. Moreover, if you change the tab
headings but use the same keys you don need to change your code. So it is
less  error prone. As a pleasant side effect, the URL's get significantly
shorter. Do notice that the keys want to be unique.



=item B<default(STRING)>

STRING is the default tab to be active. Example:

    $tab->default("Traines");  # normal list

    $tab->default("-t");       # key/value list



=item B<active()>

Returns the current active tab. This is (in order of precedence) the tab
being clicked on, the default tab, or the first in the list. Example:

    if ( $tab->active eq "Traines" ) {  # display the train tables
         ....



=item B<class(STRING)>

STRING is the CSS class name used to mark up the tabs. There are four class
elements you need to provide:

=over 4

=item 1. A table element for containment of the entire tab widget

=item 2. A td element for a normal tab

=item 3. A td element for the active tab

=item 4. A td element for the spacers

=back

The elements for table and td get their name directly from the class()
method. The element for an active tab gets "_actv" added to the class name.
The spacer element gets "_spc" added. For instance, if you'd run

    $tab->class("my_tab")

then the four elements look like:

    <table class="my_tab">    # the entire table
    <td class="my_tab">       # normal tab
    <td class="my_tab_actv">  # highlighted tab
    <td class="my_tab_spc">   # spacer


Look at the example in the EXAMPLE section for more info.



=item B<cgi_object(OBJECT)>

OBJECT is a CGI or CGI::Minimal object. CGI::Widget::Tabs uses this object to
communicate about the CGI query parameters. Although ideally all CGI object
handlers should work, only CGI and CGI::Minimal have been tested. Example:

    my $cgi = CGI::Minimal->new;
    $tab->cgi_object($cgi);



=item B<cgi_param(STRING)>

cgi_param() specifies which CGI parameter is used for the tabs. Usually you
can leave this untouched. In that case the default parameter "tab" is used.
You will need to set this if you happen to have more CGI query parameters on
the URL with "tab" already being taken. Another situation is if you use
multiple tabs widgets on one page. They both would use "tab" by default
causing conflicts. Example:

   my $fruits_tab = CGI::Widget::Tabs->new;  #| We'll use a tab to display
   my $vegies_tab = CGI::Widget::Tabs->new;  #| fruits and another to display
   my $cgi = CGI::Minimal->new;              #| vegetables.
                                             #| In the CGI params collection
   $fruits_tab->cgi_object($cgi);            #| the first is identified by
   $vegies_tab->cgi_object($cgi);            #| 'ft' and the second by 'vt'
                                             #|
   $fruits_tab->cgi_param("ft");             #|
   $vegies_tab->cgi_param("vt");             #|




=item B<display()>

Prints the tab widget. Example:


    $tab->display;       # this is the same as...

    print $tab->render;  # ... but saves you a few keystrokes




=item B<render()>

Renders the tab widget and returns the resulting HTML code. This is useful if
you need to print the tab to a different filehandle. Another use is if you
want to manipulate the HTML. For instance to insert session id's or the like.
See the class() method and the EXAMPLE section somewhere else in this
document to see how you can influence the markup of the tab widget. Example:

    my $html = $tab->render;
    print HTML $html;  # there's a session id filter behind HTML


=back




=head1 EXAMPLE

As an example probably is the most explanatory, here is something to work
with. The following code is a simple but complete example. Copy it and run it
through the webservers CGI engine. (For a even more complete and useful demo
with multiple tabs, see the file tabs-demo.pl in the CGI::Widget::Tabs
installation directory.)

    #!/usr/bin/perl -w

    use CGI::Widget::Tabs;
    use CGI;

    print <<EOT;
    Content-Type: text/html;

    <head>
    <style type="text/css">
    table.my_tab   { border-bottom: solid thin black }
    td.my_tab      { padding: 2 12 2 12; background-color: #FAFAD2 }
    td.my_tab_actv { padding: 2 12 2 12; background-color: #C0D4E6 }
    td.my_tab_spc  { width: 15 }
    </style></head>
    <body>
    EOT

    my $cgi = CGI->new;
    my $tab = CGI::Widget::Tabs->new;
    $tab->cgi_object($cgi);
    $tab->class("my_tab");
    $tab->headings( "Hardware", "Lease Cars", "Xerox", "Mobiles");
    $tab->default("Lease Cars");
    $tab->display;
    print "<br>We now should run some intelligent code ";
    print "to process <strong>", $tab->active, "</strong><br>";
    print "</body></html>";




=head1 BUGS

As a side effect, the CGI query parameter to identify the tab is always moved
to the end of the query string.



=head1 CREDITS

Bodo Eing E<lt>eingb@uni-muenster.deE<gt>


=head1 AUTHOR

Koos Pol E<lt>koos_pol@raketnet.nlE<gt>


=head1 DOWNLOAD

The latest version of CGI::Widget::Tabs is available from
CPAN (http://cpan.perl.org) or the CGI::Widget::Tabs homepage
(http://users.raketnet.nl/koos_pol/en/Tabs/index.html)


=head1 SEE ALSO

the manpages for CGI or CGI::Minimal, the CSS1 specs from the World Wide Web
consortium (http://www.w3.org/TR/REC-CSS1)

=cut
