# $Id: Tabs.pm,v 1.27 2002/12/02 20:19:37 koos Exp $

package CGI::Widget::Tabs;

use 5.006;
use strict;
use warnings;
use Carp;
use CGI::Widget::Tabs::Heading;
use URI::Escape();
use HTML::Entities();

our $VERSION = '1.05';



# ----------------------------------------------
sub new {
# ----------------------------------------------
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    return $self;
}



# ----------------------------------------------
sub headings {
# ----------------------------------------------
    #
    #  1. ( "Software", "Hardware, ...)
    #  2. ( -sw => "Software", -hw => "Hardware", ... )
    #
    my $self = shift;
    if ( @_ ) {
        $self->{headings} = [ @_ ];
    }
    return @{ $self->{headings} || [] };
}



# ----------------------------------------------
sub heading {
# ----------------------------------------------
    #
    # Create, add, and return a new heading object
    #
    my $self = shift;
    my $heading = CGI::Widget::Tabs::Heading->new;
    push @{ $self->{headings} }, $heading;
    return $heading;
}



# ----------------------------------------------
sub default {
# ----------------------------------------------
    #
    # The default active heading
    #
    my $self = shift;
    if ( @_ ) {
        $self->{default} = shift;
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
    my $self = shift;
    my $cgi = shift;
    if ( $cgi ) {
        if ( ref $cgi ne "CGI" and ref $cgi ne "CGI::Minimal") {
            my $pkg = __PACKAGE__;
            croak "[$pkg] Warning: Expected CGI or CGI::Minimal object.\n";
        }
        $self->{cgi_object} = $cgi;
    }
    return $self->{cgi_object};
}



# ----------------------------------------------
sub cgi_param {
# ----------------------------------------------
    #
    # CGI parameter specifing the tab. Defaults to "tab".
    #
    my $self = shift;
    if ( @_ ) {
        $self->{cgi_param} = shift;
    }
    return $self->{cgi_param}||'tab';
}



# ----------------------------------------------
sub active {
# ----------------------------------------------
    #
    # The active heading:
    # In order of precendence:
    # 1. The heading clicked by the user
    # 2. The default heading
    # 3. The first heading in the list
    #
    my $self = shift;

    # 1. Heading clicked
    my $clicked = $self->cgi_object->param($self->cgi_param);
    return $clicked if defined $clicked;  # that was easy :-)

    # -- Plain or k/v list
    # 2./3. Default or first
    if ( !ref ( ($self->headings)[0] ) ) {
        return $self->default || ($self->headings)[0];
    }

    # -- List of OO headings
    # 2. Default
    return $self->default if defined $self->default;  # that was again very easy
    # 3. First
    my $first_heading = ($self->headings)[0];
    return $first_heading->key || $first_heading->raw_text || $first_heading->text;
}



# ----------------------------------------------
sub class {
# ----------------------------------------------
    #
    # The CSS class for display of the tabs
    # Defaults to 'tab'.
    #
    my $self = shift;
    if ( @_ ) {
        $self->{class} = shift;
    }
    return $self->{class} || 'tab';
}



# ----------------------------------------------
sub wrap {
# ----------------------------------------------
    #
    # wrap to next row after this num of headings
    #
    my $self = shift;
    if ( @_ ) {
        $self->{wrap} = shift;
    }
    return $self->{wrap};
}



# ----------------------------------------------
sub indent {
# ----------------------------------------------
    #
    # Indentation after wrapping to next line?
    # Evaluates to 1 or 0;
    #
    my $self = shift;
    my $arg = shift;
    my $indent = 1;  # defaults to 1

    if ( defined $arg ) {
        # set
        $indent = 0 if !$arg;
    } else {
        # get
        $indent = 0 if defined $self->{indent} && !$self->{indent};
    }
    $self->{indent} = $indent;
    return $indent;
}



# ----------------------------------------------
sub display {
# ----------------------------------------------
    #
    # save a few keystrokes
    #
    my $self = shift;
    print $self->render;
}



# ----------------------------------------------
sub render {
# ----------------------------------------------
    #
    # Process the lot and display it.
    #
    my $self        = shift;
    my $cgi         = $self->cgi_object;
    my @headings    = $self->headings; # plain list, k/v list or object list
    my $class       = $self->class;
    my $cgi_param   = $self->cgi_param;
    my $active      = $self->active;
    my $wrap        = $self->wrap;
    my $indent      = $self->indent;
    my $spacer      = '<td class="'.$class.'_spc"><img height="1" width="1"></td>';  # dummy image
    my $indentation = '<td class="'.$class.'_ind"><img height="1" width="1"></td>'."\n";  # dummy image
    my @html;
    my $all_query_params_but_one = _all_query_params_but_one($cgi, $cgi_param);
    my $url;

    if ( @headings ) {

        @html = ();
        push @html, "<!-- Generated by CGI::Widget::Tabs v$VERSION -->\n";

        # --- OO headings
        if ( ref($headings[0] ) ) {
            my $heading_nr = 1;  # first heading
            my $row_nr     = 1;  # first row
            my $param_value;

            foreach my $heading ( @headings ) {
                if ( $heading_nr == 1 ) {   # first one in the row?
                    push @html, _start_of_row($class, $spacer, $indent, $row_nr, $indentation);
                }

                # -- actual headings
                $param_value = $heading->key || $heading->raw_text || $heading->text;
                push @html, '<td class="',$class;
                push @html, '_actv' if $param_value eq $active;
                push @html, '">';
                my $url = $heading->url || ( '?'.$all_query_params_but_one.$cgi_param.'='.URI::Escape::uri_escape($param_value) );
                push @html, &_link( ( $heading->raw_text || HTML::Entities::encode_entities($heading->text) ) , $url );
                push @html, "</td>";
                push @html, $spacer,"\n";
                # -- end of row
                if ( $wrap && ( $heading_nr == $wrap ) ) {  # last one on the line?
                    push @html,  "</tr>\n";     # | yes, end this row
                    push @html,  "</table>\n";  # |
                    $heading_nr = 0;
                    $row_nr++;
                }
                $heading_nr++;
            }

            # --- all headings printed
            if ( $heading_nr != 1 )  {     # | Did we just get wrapped to
                push @html, "</tr>\n";     # | the next line? In that case
                push @html, "</table>\n";  # | we don't need an end-of-row.
            }
        }

        # --- simple list headings
        else {  # the first element is a scalar -> ("Heading") or ( -h => "Heading" );
            # --- Did we get the -h => "Heading" version?
            if ( substr($headings[0],0,1) eq '-' ) {
                my $heading_nr = 1;  # first heading
                my $row_nr     = 1;  # first row
                my $heading_key;
                my $heading_text;
                while ( @headings ) {

                    if ( $heading_nr == 1 ) {   # first one in the row?
                        push @html, _start_of_row($class, $spacer, $indent, $row_nr, $indentation);
                    }

                    # -- actual headings
                    $heading_key  = shift @headings;
                    $heading_text = shift @headings;
                    push @html, '<td class="',$class;
                    push @html, '_actv' if $heading_key eq $active;
                    push @html, '">';
                    push @html, &_link($heading_text,'?'.$all_query_params_but_one.$cgi_param.'='.URI::Escape::uri_escape($heading_key));
                    push @html, "</td>";
                    push @html, $spacer,"\n";

                    # -- end of row
                    if ( $wrap && ( $heading_nr == $wrap ) ) {  # last one on this row?
                        push @html,  "</tr>\n";     # | yes, end this row
                        push @html,  "</table>\n";  # |
                        $heading_nr = 0;
                        $row_nr++;
                    }
                    $heading_nr++;
                }

                # --- all headings printed
                if ( $heading_nr != 1 )  {     # | Did we just get wrapped to
                    push @html, "</tr>\n";     # | the next row? In that case
                    push @html, "</table>\n";  # | we don't need an end-of-row.
                }

            } else {
                # --- No, we got the ("Heading1", "Heading2", ...)  version.
                my $heading_nr = 1;  # first heading
                my $row_nr     = 1;  # first row
                foreach my $heading ( @headings ) {

                    if ( $heading_nr == 1 ) {   # first one in the row?
                        push @html, _start_of_row( $class, $spacer, $indent, $row_nr, $indentation );
                    }

                    # -- actual headings
                    push @html, '<td class="',$class;
                    push @html, '_actv' if $heading eq $active;
                    push @html, '">';
                    push @html, &_link($heading,'?'.$all_query_params_but_one.$cgi_param.'='.URI::Escape::uri_escape($heading));
                    push @html, "</td>";
                    push @html, $spacer,"\n";

                    # -- end of row
                    if ( $wrap && ( $heading_nr == $wrap ) ) {  # last one on the row?
                        push @html,  "</tr>\n";     # | yes, end this row
                        push @html,  "</table>\n";  # |
                        $heading_nr = 0;
                        $row_nr++;
                    }
                    $heading_nr++;
                }

                # --- all headings printed
                if ( $heading_nr != 1 )  {     # | Did we just get wrapped to
                    push @html, "</tr>\n";     # | the next row? In that case
                    push @html, "</table>\n";  # | we don't need an end-of-row.
                }
            }
        }
    }

    push @html, "<!-- End CGI::Widget::Tabs v$VERSION -->\n";
    return join("",@html);
}



# ----------------------------------------------
sub _start_of_row {
# ----------------------------------------------
    my ( $class, $spacer, $indent, $row_nr, $indentation ) = @_;
    my @html = ();
    push @html, "<table class=\"",$class,'">',"\n";
    push @html,  "<tr>\n";
    if ( $indent && $row_nr > 1 ) {                     # = print indents if
        push @html, ( $indentation x ($row_nr - 1));    # = necessary
    }                                                   # =
    push @html, $spacer,"\n";                           # each row starts with a spacer
    return @html;
}



# ----------------------------------------------
sub _link {
# ----------------------------------------------
    #
    # Internal. Create a link for some text to a URI
    # Expects = (<text>,<url>) pair.
    #
    return '<a href="'.$_[1].'">'.($_[0]).'</a>';
}



# ----------------------------------------------
sub _all_query_params_but_one {
# ----------------------------------------------
    # reproduce the URL incl all CGI params, _except_ the varying tab
    my ( $cgi, $cgi_param ) = @_;

    my $all_query_params_but_one = "";
    foreach ( $cgi->param() ) {
        next if $_ eq $cgi_param;
        $all_query_params_but_one .= $_.'='.URI::Escape::uri_escape($cgi->param($_)||"").'&';
    }
    return $all_query_params_but_one;
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
    $tab->wrap(4);               # wrap after 4 headings...
    $tab->indent(1);             # ...and add indentation
    $tab->render;                # the resulting HTML code
    $tab->display;               # same as `print $tab->render'


    $h = $tab->heading;               # new OO heading for this tab
    $h->text("TV Listings");          # heading text. HTML escaped
    $h->raw_text("TV&nbsp;Listings"); # similar. But passed as is
    $h->key("tv");                    # key identifying this heading
    $h->url("whatsontonight.com");    # redirect URL for this heading

    # See the EXAMPLE section for a complete example

=head1 DESCRIPTION

=head2 Introduction

CGI::Widget::Tabs lets you simulate tab widgets in HTML. You could benefit
from a tab widget if you want to serve only one page. Depending on the tab
selected you fetch and display the underlying data. There are two main
reasons for taking this approach:

1. For the end user not to be directed to YAL or YAP (yet another link / yet
another page), but keep it all together: The single point of entry paradigm.

2. As a consequence the end user deals with a more consistent and integrated
GUI. This will give a better "situational awareness" within the application.

3. For the Perl hacker to handle multiple related data sources within the
same script environment.


As an example the following tabs could be used on a web page for someone's
spotting hobby:

      __________      __________      __________
     /  Planes  \    /  Trains  \    / Classics \
------------------------------------------------------
         _________
        /  Bikes  \
------------------------

As you can see, the headings wrap at three and a small indentation is added
to the start of the next row. The nice thing about CGI::Widget::Tabs is that
the tabs know their internal state. So you can ask a tab for instance which
heading has been clicked by the user. This way you get instant feedback.

=head2 "Hey Gorgeous!"

Of course tabs are useless if you can't "see" them. Without proper make up
they print as ordinary text. So you really need to fancy them up with some
eye candy. The designed way is that you provide a CSS style sheet and have
CGI::Widget::Tabs use that. See the class() method for how to do this.



=head2 Simple Headings vs. OO Headings

Tab headings are the things that identify a tab page. Observe the spotting
example above. Here the different tab pages are identified by the strings
"Planes", "Trains", "Classics" and "Bikes". They form the heading of each
page. These tab headings come in two flavors: simple headings and object
oriented (OO) headings. Simple headings are the most easy and convenient ones
to use. For instance in the spotting example the four tabs headings are
easily created by feeding these words as a list to a CGI::Widget::Tabs
object. And then you are almost done: the headings can be displayed and each
heading gets it's own self referencing URL. The corresponding statements are:

    my $tab = CGI::Widget::Tabs->new;
    $tab->headings( qw/Planes Trains Classics Bikes/ );
    $tab->wrap(3);

This fast and easy to use mechanism has it's downside nonetheless. For
instance the URL is always a self referencing URL. Also future extensions
--like support for thumbnail images-- is almost impossible. To allow for this
extensibility headings can be defined in OO fashion. The OO statements to
produce the headings would be something like:

    my $tab = CGI::Widget::Tabs->new;
    foreach $ht ( qw/Planes Trains Classics Bikes/ ) {
        $h = $tab->heading();  # create and add a heading object
        $h->text($ht);         # display $ht as heading text
    }
    $tab->wrap(3);


Here the text() method makes the heading object display the text given by
$ht. Look at the heading() method elsewhere in this document to see which
other methods are available to define the properties and behaviour of OO
headings. Did you see that in both accounts the indent() method was not used?
That is because indentation is automatic. You get that for free. Actually,
you must explicitely turn if off if you don't want it! Note that you can not
mix simple headings with OO headings. If you already defined simple headings
you can't go adding OO headings or vice versa. You need to stick with one
type.




=head1 COMMON METHODS FOR TAB OBJECTS

Common methods deal with tab objects in general. They describe or define the
global widget properties and it's behaviour.



=over 4

=item B<new()>

Creates and returns a new CGI::Widget::Tabs object. Example:

    use CGI::Widget::Tabs;
    my $tab = CGI::Widget::Tabs->new;



=item B<active()>

Returns the current active tab heading. This is (in order of precedence) the
heading being clicked on, the default heading, or the first in the list.
Example:

    if ( $tab->active eq "Trains" ) {  # display the train tables
         ....

    if ( $tab->active eq "-t" ) {      # the key i.s.o. full string
         ....

Note how it does not matter if you configured simple headings or OO headings.
Whichever you have chosen, active() will return the proper value: a value
from the headings() method if you have configured simple headings or a value of
one of the text(), raw_text() or key() methods if you have configured OO
headings.



=item B<cgi_object(OBJECT)>

Sets/retrieves the CGI or CGI::Minimal object. If the optional argument
OBJECT is given, the CGI object is set, otherwise it is retrieved.
CGI::Widget::Tabs uses this object internally to process the CGI query
parameters. If you want you can use some other CGI object handler. However
such an object handler must provide a param() method with corresponding
behaviour as do CGI or CGI::Minimal. Note that currently only CGI and
CGI::Minimal have been tested. Example:

    # set
    my $cgi = CGI::Minimal->new;
    $tab->cgi_object($cgi);

    # get
    my $cgi = $tab->cgi_object;



=item B<cgi_param(STRING)>

Sets/retrieves the CGI query parameter. This parameter identifies the tab in
the CGI query string (the funny part of the URL with the ? = & # characters).
If the optional argument STRING is given, the query parameter is set.
Otherwise it is retrieved. Usually you can leave this untouched. In that case
the default parameter "tab" is used. You will need to set this if you have
more CGI query parameters on the URL with "tab" already being taken. Another
situation is if you use multiple tabs widgets on one page. They both would
use "tab" by default causing conflicts. Example:

   # Lets paint a fruit tab and a vegetable tab
   my $fruits_tab = CGI::Widget::Tabs->new;
   my $vegies_tab = CGI::Widget::Tabs->new;

   # this is our link with the outside world
   my $cgi = CGI::Minimal->new;
   $fruits_tab->cgi_object($cgi);
   $vegies_tab->cgi_object($cgi);

   # In the CGI params collection the first is
   # identified by 'ft' and the second by 'vt'
   $fruits_tab->cgi_param("ft");
   $vegies_tab->cgi_param("vt");




=item B<class(STRING)>

Sets/retrieves the name of the CSS class used for the tabs markup. If the
optional argument STRING is given the class is set, otherwise it is
retrieved. In the accompanying style sheet, there are five class elements you
need to provide:

=over 4

=item 1. A table element for containment of the entire tab widget

=item 2. A td element for a normal tab

=item 3. A td element for the active tab

=item 4. A td element for the spacers

=item 5. A td element for the indentation (if needed)

=back

The class names of these elements are directly borrowed from the class()
method. The td elements for the active tab, the spacers and the indentations
are suffixed with "_actv", "_spc" and "_ind" respectively. For instance, if
you'd run

    $tab->class("my_tab");

then the elements look like:

    <table class="my_tab">    # the entire table
    <td class="my_tab">       # normal tab
    <td class="my_tab_actv">  # highlighted tab
    <td class="my_tab_spc">   # spacer
    <td class="my_tab_ind">   # indentation

If you don't wrap headings, then ofcourse you won't need to specify the
indentation td's. By the way, the indentation will usually look most natural
if it has the same width as the spacers or a multiple. Look at the example in
the EXAMPLE section to see how this all works out.



=item B<wrap(NUMBER)>

Sets or retrieves the wrap setting. Without arguments the current wrap
setting is returned. If the argument NUMBER is given the headings will wrap
to the next row after NUMBER headings. By default headings are not wrapped.



=item B<indent(LVAL)>

Sets/retrieves the indentation setting. Without arguments the current setting
is returned. indent() specifies if indentation should be added to the
next row if the headings get wrapped. By default indent() is set to
TRUE. You must explicitaly switch off indentation for the desired effect.
indent() is a toggle. The optional argument LVAL can be any argument
evaluating to a logical value.

The purpose of swithing off indentation is to simulate a vertical menu. In
the spotting example, running

    $tab->wrap(1);
    $tab->indent(0);

could result in something like:

      __________
     |  Planes  |
    --------------
      __________
     |  Trains  |
    --------------
      __________
     | Classics |
    --------------
      __________
     |  Bikes   |
    --------------


You probably need to tweak your style sheet to have it look nicely.



=item B<display()>

Prints the tab widget to the default file handle (usually STDOUT). Example:


    $tab->display;       # this is the same as...

    print $tab->render;  # ...but saves a few keystrokes




=item B<render()>

Renders the tab widget and returns the resulting HTML code. This is useful if
you need to print the tab to a different file handle. Another use is if you
want to manipulate the HTML. For instance to insert session id's or the like.
See the class() method and the EXAMPLE section somewhere else in this
document to see how you can influence the markup of the tab widget. Example:

    my $html = $tab->render;
    print HTML $html;  # there's a session id filter behind HTML


=back




=head1 METHODS FOR SIMPLE HEADINGS

These methods define the properties of simple headings. As the simple
headings are indeed very simple the wording "headings" doesn't fit. There is
actually only one method :-)


=over 4

=item B<headings(LIST)>

Sets or retrieves simple tab headings. Without arguments the currently
defined headings are retrieved. If the optional argument LIST is given the
headings are set. You can specify LIST in two ways:

=over 4

=item * a plain list

=item * a keyword/value list

=back

The keyword/value list comes in handy if you don't want to check the value
returned by active() against very long words. Moreover, if you change the tab
headings (upper/lower case, typo's) but use the same keys you don't need to
change your code. So it is less  error prone. As a pleasant side effect, the
URL's get significantly shorter. Do notice that the keys want to be unique.
Example:

    # plain list
    $tab->headings( qw/Hardware Software Mobiles/ );

    # k/v list
    $tab->headings( -h => "Hardware",
                    -s => "Software",
                    -m => "Mobiles" );

    # what have we got sofar?
    my @h = $tab->headings;


Keys in a k/v list are not at all magical. You can choose any string you like
with the provision that it starts with the '-' (minus) sign. The starting '-'
of the list entries are what triggers CGI::Widget::Tabs to decide this list
is a k/v list. So don't go and use plain list entries with a starting '-'.
That won't work.

=back




=head1 METHODS FOR OO HEADINGS

These methods define the properties and behaviour of the object oriented
headings. Each OO heading can be tailored to specific requirements.

=over 4

=item B<heading()>

Creates and returns a new heading object. The heading object is automatically
added to the CGI::Widget::Tab widget. Example:

    my $h = $tab->heading();

The properties and behaviour of an OO heading can be set with the following
methods:

=over 4



=item B<text(STRING)>

Sets/retrieves the heading text for the OO heading. If the optional argument
STRING is given, the text will be set otherwise it will be retrieved.
On actual display STRING will be HTML escaped. Examples:

    # set heading text
    $h1->text("Names A > L");
    $h2->text("Names M < Z");

    # get the text of the 4th heading
    my $text = ($tab->headings)[3]->text;



=item B<raw_text(STRING)>

Sets/retrieves the heading text for the OO heading. If the optionals argument
STRING is given, the text will be set otherwise it will be retrieved. On
actual display STRING will not be HTML escaped but passed as is. This is
useful if you have some HTML preformatted text to display. Example:

    # set heading text
    $h1->raw_text("Names&nbsp;A&nbsp;&gt;&nbsp;L");
    $h2->raw_text("Names&nbsp;M&nbsp;&lt;&nbsp;Z");

    # text of the 4th heading
    my $text = ($tab->headings)[3]->raw_text;



=item B<key(STRING)>

Sets/retrieves the value to use for this heading in the CGI query param
list. This is similar to the use of keys in key/value lists of simple
headings. The goal is to simplify programming logic and shorten default
URL's. (See the headings() method for simple headings elsewhere in this
document for further explanation). Note that using keys is only useful if you
chose to use the default self referencing URL. Example:

    # display the full heading...
    # ...but use a small key as query param value
    $h->text("Remote Configurations");
    $h->key("rc");

In contrast to the use of keys in simple headings, CGI::Widget::Tabs knows
that this is a key and not a value. You are using the key() method, right?
Consequently you don't need the prepend the key with a '-'. You may consider
using a '-' for your keys nevertheless. It will lead to more transparent
code. When prepending the key from the snippet above with a '-' it would
later on result in the following check:

    if ( $tab->active eq '-rc' ) {  # clearly we are using keys
        ....

Consider this a mild suggestion.



=item B<url(STRING)>

Sets/retrieves the redirect URL for this heading. If the optional argument
STRING is given the URL is set otherwise it is retrieved. The URL is used
exactly as given. This means that any query params and values need to be added
explicitely. If a URL is not set for a heading, the default self referencing
URL is used. Example:

      $h->url("www.someremotesite.com");  # go somewhere else

      my $url = $h->url;                  # retrieve the URL



=back



=item B<headings()>

Returns the list of currently defined OO headings. headings() does not take
any arguments. Example:

    @h = $tab->headings;

Note that this method can also be used for simple headings.


=back


=head1 EXAMPLE

As an example probably is the most explanatory, here is something to work
with. The following code is a simple but complete example. It uses only
simple headings. Copy it and run it through the webservers CGI engine. (For a
even more complete and useful demo with multiple tabs, see the file
tabs-demo.pl in the CGI::Widget::Tabs installation directory.)

    # !/usr/bin/perl -w

    use CGI::Widget::Tabs;
    use CGI;

    print <<EOT;
    Content-Type: text/html;

    <head>
    <style type="text/css">
    table.my_tab   { border-bottom: solid thin black; text-align: center }
    td.my_tab      { padding: 2 12 2 12; width: 80; background-color: #FAFAD2 }
    td.my_tab_actv { padding: 2 12 2 12; width: 80; background-color: #C0D4E6 }
    td.my_tab_spc  { width: 5 }
    td.my_tab_ind  { width: 15 }
    </style></head>
    <body>
    EOT

    my $cgi = CGI->new;
    my $tab = CGI::Widget::Tabs->new;
    $tab->cgi_object($cgi);
    $tab->class("my_tab");
    $tab->headings( "Hardware", "Software", "Lease Cars", "Xerox", "Mobiles");
    $tab->wrap(3);
    # $tab->wrap(1);    # |uncomment to see the effect of
    # $tab->indent(0);  # |wrapping at 1 without indentation
    $tab->default("Software");
    $tab->display;
    print "<br>We now should run some intelligent code ";
    print "to process <strong>", $tab->active, "</strong><br>";
    print "</body></html>";




=head1 BUGS

As a side effect, the CGI query parameter to identify the tab (see the
cgi_param() method) is always moved to the end of the query string.

With OO headings text() is completely isolated from raw_text(). They are
both seperate properties. Consequently the value set with text() can not be
overwritten with a value set with raw_text() or vice-versa. Neither can you
retrieve the current heading text unless you B<know> which one of the two you
used to set the heading text. text() and raw_text() should probably use the
same container. This will be fixed in a future release.


=head1 CONTRIBUTIONS

I would appreciate receiving your CSS style sheets used for the tabs markup.
Especially if you happened to be professionally concerned with markup and
layout. For techies like us it is not always easy to see what goes and what
doesn't. If you send in a nice one, I will gladly bundle it with the next
release.



=head1 ACKNOWLEDGEMENTS

=over 4

=item Bodo Eing <eingb@uni-muenster.de>

=item Sagar Shah <sagarshah@softhome.net>

=back



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
