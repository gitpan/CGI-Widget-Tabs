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
    $h->text("TV Listings");          # heading text
    $h->key("tv");                    # key identifying this heading
    $h->raw(1);                       # switch off HTML encoding
    $h->url("whatsontonight.com");    # redirect URL for this heading
    $h->class("red");                 # this heading has it's own class

    # See the EXAMPLE section for a complete example

=head1 DESCRIPTION

=head2 Introduction

CGI::Widget::Tabs lets you simulate tab widgets in HTML. You could benefit
from a tab widget if you want to serve only one page. Depending on the tab
selected you fetch and display the underlying data. There are three main
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


=head1 EXAMPLE

Before digging into the API and all accessor methods, this example will
illustrate how to implement the spotting page from above. So you have
something to start with. It will give you enough clues to get on the road
quickly. The following code is a simple but complete example. Copy it and run
it through the webservers CGI engine. (For a even more complete and useful
demo with multiple tabs, see the file tabs-demo.pl in the CGI::Widget::Tabs
installation directory.) To fully appreciate it, it would be best to run it
in a performance environment, like mod_perl or SpeedyCGI.

    #! /usr/bin/perl -w

    use CGI::Widget::Tabs;
    use CGI;

    print <<EOT;
    Content-Type: text/html;

    <head>
    <style type="text/css">
    table.tab   { border-bottom: solid thin #C0D4E6; text-align: center }
    td.tab      { padding: 2 12 2 12; width: 80; background-color: #FAFAD2 }
    td.tab_actv { padding: 2 12 2 12; width: 80; background-color: #C0D4E6 }
    td.tab_spc  { width: 5 }
    td.tab_ind  { width: 15 }
    </style></head>
    <body>
    EOT

    my $cgi = CGI->new;
    my $tab = CGI::Widget::Tabs->new;
    $tab->cgi_object($cgi);
    $tab->headings( qw/Planes Traines Classics Bikes/ );
    $tab->wrap(3);
    # $tab->wrap(1);    # |uncomment to see the effect of
    # $tab->indent(0);  # |wrapping at 1 without indentation
    $tab->default("Traines");
    $tab->display;
    print "<br>We now should run some intelligent code ";
    print "to process <strong>", $tab->active, "</strong><br>";
    print "</body></html>";

=head1 PUBLIC INTERFACE


=cut

package CGI::Widget::Tabs;


# pragmata
use strict;
use vars qw/$VERSION/;

# Standard Perl Library and CPAN modules
use Carp;
use URI::Escape();
use HTML::Entities();

# CGI::Widget::Tabs modules
use CGI::Widget::Tabs::Heading;


$VERSION = "1.08";



=head2 Public Class Interface

=head3 new

  new()

Creates and  returns a new  CGI::Widget::Tabs  object. new()  does  not take any
arguments.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    $self->indent(1);
    return $self;
}


=head2 Public Object Interface

=head3 active

 active()

Returns a string indicating the current active tab heading. This is (in order of
precedence) the  heading being clicked on, the  default heading, or the first in
the list. The string value will either  be the heading key  or the heading text,
depending on if you chose to use keys. Example:

    if ( $tab->active() eq "Trains" ) {  # heading text only

    if ( $tab->active() eq "-t" ) {      # key value ISO heading text

=cut

sub active {

    #
    # Returns the active heading. In order of precendence:
    # 1. The heading clicked by the user
    # 2. The default heading
    # 3. The first heading in the list
    #
    my $self = shift;
    my $active;

    # 1. Heading clicked
    $active = $self->cgi_object->param($self->cgi_param);
    return $active if defined $active;

    # 2. Default
    $active = $self->default;
    return $active if defined $active;

    # 3. First
    my $h = ($self->headings)[0];  # headings are always OO objects
    return $h->key || $h->text;
}

=head3 cgi_object

 cgi_object(OBJECT)

Sets/returns the CGI or CGI::Minimal object. If the  optional argument OBJECT is
given, the CGI object is set,  otherwise it is returned.  CGI::Widget::Tabs uses
this object internally to process the CGI query parameters. If  you want you can
use some other CGI object handler. However such an object handler must provide a
param() method with corresponding behaviour as do CGI or CGI::Minimal. Note that
currently only CGI and CGI::Minimal have been tested. Example:

    # set
    my $cgi = CGI::Minimal->new;
    $tab->cgi_object($cgi);

    # get
    my $cgi = $tab->cgi_object;

=cut

sub cgi_object {

    #
    # The cgi object to retrieve the parameters from.
    # Could be a CGI object or a CGI::Minimal object.
    #
    my $self = shift;
    my $cgi = shift;
    if ( $cgi ) {
        if ( ref $cgi ne "CGI" and ref $cgi ne "CGI::Minimal") {
            carp "Warning: Expected CGI or CGI::Minimal object";
        }
        $self->{cgi_object} = $cgi;
    }
    return $self->{cgi_object};
}

=head3 cgi_param

  cgi_param(STRING)

Sets/returns the CGI query  parameter. This parameter  identifies the tab in the
CGI query string (the funny part  of the URL  with the ?  = & # characters).  If
the optional argument STRING is given, the query parameter is set.  Otherwise it
is returned. Usually  you  can leave this   untouched. In that case the  default
parameter "tab" is used. You  will need to  set this if  you have more CGI query
parameters on  the URL with "tab" already  being taken. Another  situation is if
you use multiple tab widgets on one  page. They both  would use "tab" by default
causing conflicts. Example:

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

=cut

sub cgi_param {

    #
    # CGI parameter specifing the tab. Defaults to "tab".
    #
    my $self = shift;
    if ( @_ ) {
        $self->{cgi_param} = shift;
    }
    return $self->{cgi_param} || "tab";
}


=head3 class

  class(STRING)

Sets/returns the name of the CSS class used for the tabs markup. If the optional
argument STRING is given  the class is set,  otherwise  it is returned.   If not
set, the widget will   be based on the  class  "tab". In the  accompanying style
sheet, there are five class elements you need to provide:

=over 4

=item 1. A table element for containment of the entire tab widget

=item 2. A td element for a normal tab

=item 3. A td element for the active tab

=item 4. A td element for the spacers

=item 5. A td element for the indentation (if needed)

=back

The  class names of   these  elements are  directly  borrowed  from  the class()
method. The td elements for the active tab, the spacers and the indentations are
suffixed with  "_actv", "_spc" and  "_ind" respectively. For  instance, if you'd
run

    $tab->class("my_tab");

then the elements look like:

    <table class="my_tab">    # the entire table
    <td class="my_tab">       # normal tab
    <td class="my_tab_actv">  # active tab
    <td class="my_tab_spc">   # spacer
    <td class="my_tab_ind">   # indentation

If you    don't wrap headings,   then ofcourse  you won't   need  to specify the
indentation td's. By the way, the indentation will usually  look most natural if
it has the same width as the spacers or a multiple thereof.  Look at the example
in the EXAMPLE section to see how this all works out.

=cut

sub class {

    #
    # The CSS class for display of the tabs
    # Defaults to 'tab'.
    #
    my $self = shift;
    if ( @_ ) {
        $self->{class} = shift;
    }
    return $self->{class} || "tab";
}


=head3 default

 default(STRING)

Overrides which heading is the default. Normally CGI::Widget::Tabs will make the
first  heading  active. Use the  default() method  if you   want to deviate from
this. The optional argument STRING must either be the heading key or the heading
text, depending on how you chose to initialize the headings. Example:

    # Make the "Trains" heading the default active one.
    $tab->active("Trains");

    # ...or perhaps...
    $tab->active("-t");

=cut

sub default {

    #
    # The default active heading
    #
    my $self = shift;
    if ( @_ ) {
        $self->{default} = shift;
    }
    return $self->{default}
}

=head3 display

  display()

Renders the tab widget   and prints the resulting HTML   to the  default  output
handle (usually STDOUT). Example:


    $tab->display;       # this is the same as...

    print $tab->render;  # ...but saves a few keystrokes

See also the render() method.

=cut

sub display {

    #
    # save a few keystrokes
    #
    my $self = shift;
    print $self->render;
}


=head3 heading

  heading()

Creates, appends and returns a  new heading. The return  value will always be an
OO heading object. Example:

    my $h = $tab->heading();

In general you will  use OO headings if  the  headings() method is  not flexible
enough. For trivial applications the  headings() method mostly suffices. Look at
section PROPERTIES OF OO HEADINGS for more information on OO headings.

=cut

sub heading {

    #
    # Create, add, and return a new heading object
    #
    my $self = shift;
    my $h = CGI::Widget::Tabs::Heading->new();
    push @{ $self->{headings} }, $h;
    return $h;
}

=head3 headings

  headings(LIST)

Sets/returns the tab headings. Without arguments  the currently defined headings
are  returned. If no  headings  are  defined, the empty   list is  returned. Any
returned heading  will  always be an OO  heading,  regardless of if and  how the
initializing LIST argument  is used. Look at section  PROPERTIES OF OO  HEADINGS
for more info on how to deal with OO headings.

The optional LIST argument   is a short-cut  to  the OO headings interface.  The
elements  of LIST can take  various forms. Let's take  a moment  to take a close
look at  the headings of a  tab. Tab headings are the   things that --from human
perspective-- identify a tab page. Observe the spotting  example above. Here the
different tab pages are identified by the strings "Planes", "Trains", "Classics"
and "Bikes". They form the heading for each seperate tab.  The LIST elements can
be used to preset these tab headings.

An element of LIST can be any one of:

=over 4

=item * a string. E.g.:

    qw/Planes Trains Classics Bikes/

This is the simplest initializer. In the spotting example the four tabs headings
are  easily created   by  feeding  these words   as  a list  to  the  headings()
method. And  then you are almost  done: the headings  can be displayed  and each
heading gets it's own self referencing URL.

=item * a key/value pair. E.g.:

    ( -p => "Planes",
      -t => "Trains",
      -c => "Classics,
      -b => "Bikes" )

For trivial CGI::Widget::Tabs applications, the k/v pairs  are the ones you will
probably use the most.  They come in  handy because you don't  need to check the
value returned by active()  against very long  words. Even better, if you change
the tab headings (upper/lower case, typo's) but use the same keys you don't need
to change your code. So it is less  error prone. As a  pleasant side effect, the
URL's  get to  be significantly  shorter.  Do notice that  the keys  want  to be
unique. Keys in a k/v list are not at all magical. You can choose any string you
like with the provision that they start with the '-' (hyphen) sign. The starting
'-' of a list entry is what triggers  CGI::Widget::Tabs to decide  this is a k/v
entry. Single or dual character strings tend to be the most convenient keys.

=item * a hash

This use of the headings() method will clutter  up your code.  The hash tries to
mimic and encapsulate all OO accessor methods. If think  you need an initializer
hash, you probably want OO headings.  Use it only if you  must. If you can stick
with the  strings or  k/v  pairs.  That said,  the   hash  keys are  the   named
equivalents of the OO heading properties. E.g.:

    ( { text  => "Planes",
        key   => "p",
        url   => "www.aviation-mag.com",
        class => "heavens_blue",
        raw   => 0 },

=back

You can   mix  these types  in   any way you   like. The  various  types will be
translated on  the fly to  OO headings and  then processed.  Thus you can safely
say:

    $tab->headings( "Plaines",
                    -t => "Traines",
                    { text => "Classics",
                      key  => "c",
                      ... } )

Just as the hash initializer, this use does clutter up your  code. The reason is
that different concepts  of information are  piled up on  one big heep. You will
need to  scrutinize the code  to understand what it  is going on. Although it is
supported you should refrain yourself from making use of these combinations.

As  a summary,  here  are a  three  examples  of the headings()   method for the
spotting page.

    # Example 1: Set the headings with a list of strings
    my $tab = CGI::Widget::Tabs->new();
    $tab->headings( qw/Planes Trains Classics Bikes/ );

    # Example 2: Set the headings with a list of k/v pairs
    my $tab = CGI::Widget::Tabs->new();
    $tab->headings( -p => "Planes",
                    -t => "Trains",
                    -c => "Classics,
                    -b => "Bikes" );

    # Example 3: Isolate the "Classics" heading
    my $h = ($tab->headings)[2];

Note that these few statements provide almost enough  logic to generate the HTML
for the tab widget!

=cut

sub headings {

    #  Takes optional user defined simple headings as arguments,
    #  which  will be transformed into OO headings. E.g.:
    #  ( "Software", -hw => "Hardware", { text => "Wetware", key => "ww" } )
    #
    my $self = shift;
    if ( @_ ) {  # any arguments?

        my $h;   # OO heading
        my $ht;  # _heading _text

        HEADING: while ( my $arg = shift @_ ) {
            $h = $self->heading();  # add a new heading

            if ( ! ref $arg ) {  # Not a hash initializer
                # -- k/v pair
                ( $arg =~ /^-/ ) && do {
                    $h->key($arg);
                    $h->text(shift @_);
                    next HEADING;
                };

                # -- text only
                $h->text($arg);
                next HEADING;
            }

            # -- hash initializer
            ( ref($arg) eq "HASH" ) && do {
                if ( ! $arg->{text} ) {
                    croak "Hash initializer is missing mandatory text element";
                }

                $h->text($arg->{text});
                if ( exists( $arg->{key} )   && $arg->{key} )   { $h->key( $arg->{key} ) }
                if ( exists( $arg->{url} )   && $arg->{url} )   { $h->url(  $arg->{url} ) }
                if ( exists( $arg->{raw} )   && $arg->{raw} )   { $h->raw(  $arg->{raw} ) }
                if ( exists( $arg->{class} ) && $arg->{class} ) { $h->class(  $arg->{class} ) }
                next HEADING;
            };

            croak "Unsupported heading type";
            next;
        }
    }
    return @{ $self->{headings} || [] };
}

=head3 indent

  indent(BOOLEAN)

Sets/returns the  indentation setting. Without arguments  the current setting is
returned. indent() specifies if indentation should be added to the next row when
the headings  get wrapped. indent() is  a toggle. By default  indent() is set to
TRUE. You must explicitely  switch it off for  the desired effect.  The optional
argument BOOLEAN can be any argument evaluating to a logical value.

The purpose of swithing off indentation  is to simulate  a vertical menu. In the
spotting example, running

    $tab->wrap(1);
    $tab->indent(0);

would result in something like:

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

=cut

sub indent {

    #
    # Indentation after wrapping to next line?
    #
    my $self = shift;
    my $arg = shift;

    if ( defined $arg ) {
        $self->{indent} =  $arg ? 1 : 0;
    }
    return $self->{indent};
}


=head3 render

  render()

Renders the tab widget  and returns the resulting HTML  code. This is  useful if
you need to print the tab to a different file handle. Another use is if you want
to manipulate  the HTML. For  instance to insert session id's  or the like.  See
the class() method  and the EXAMPLE section somewhere  else in this document  to
see how you can influence the markup of the tab widget. Example:

    my $html = $tab->render;
    print HTML $html;  # there's a session id filter behind HTML

=cut

sub render {

    #
    # Process the lot and display it.
    #
    my $self        = shift;
    my $cgi         = $self->cgi_object;
    my @headings    = $self->headings;
    my $class       = $self->class;
    my $cgi_param   = $self->cgi_param;
    my $active      = $self->active;
    my $wrap        = $self->wrap;
    my $indent      = $self->indent;
    my $spacer      = qq(<td class="$class).qq(_spc"></td>);
    my $indentation = qq(<td class="$class).qq(_ind"></td>);
    my @html;
    my $url;
    my $query_string_min_min;  # the query string minus the varying tab

    # - reproduce the CGI query string EXCEPT the varying tab
    my @param_list = grep( $_ ne $cgi_param, $cgi->param() );
    if ( @param_list ) {
        $query_string_min_min = join "&", map ( "$_=".URI::Escape::uri_escape($cgi->param($_)||"") , @param_list );
        $query_string_min_min .= "&";
    } else {
        $query_string_min_min = "";
    }


    if ( @headings ) {
        @html = ();
        push @html, "<!-- Generated by CGI::Widget::Tabs v$VERSION -->\n";

        my $heading_nr = 1;  # we're about to render the first heading...
        my $row_nr     = 1;  # ...of the first row
        my $param_value;
        my $h;
        my $url;

        foreach $h ( @headings ) {
            if ( $heading_nr == 1 ) {   # first one in the row?
                push @html, qq(<table class="$class">\n<tr>\n);
                if ( $indent && $row_nr > 1 ) {                     # = print indents if
                    push @html, ( $indentation x ($row_nr - 1));    # = necessary
                }                                                   # =
                push @html, "$spacer\n";  # each row starts with a spacer
            }

            # -- actual headings
            $param_value = $h->key || $h->text;
            if ( defined $h->class() ) {  # heading has local class?
                push @html, qq(<td class=").$h->class.'">';
            } else {
                push @html, qq(<td class="$class);
                push @html, qq(_actv) if $param_value eq $active;
                push @html, qq(">);
            }

            # -- user defined URL or default self ref. URL?
            my $url = $h->url || ( "?$query_string_min_min$cgi_param=".URI::Escape::uri_escape($param_value) );
            push @html, _link( $h->text , $url );
            push @html, "</td>$spacer\n";

            # -- end of row
            if ( $wrap && ( $heading_nr == $wrap ) ) {  # last one on this row?
                push @html, "</tr>\n";     # | yes, end this row
                push @html, "</table>\n";  # |
                $heading_nr = 0;
                $row_nr++;
            }
            $heading_nr++;
        }

        # --- all headings printed
        if ( $heading_nr > 1 )  {      # | We need to end this
            push @html, "</tr>\n";     # | row if it didn't just
            push @html, "</table>\n";  # | get wrapped.
        }
    }

    push @html, "<!-- End CGI::Widget::Tabs v$VERSION -->\n";
    return join("", @html);
}


=head3 wrap

  wrap(NUMBER)

Sets or returns the wrap setting. Without  arguments the current wrap setting is
returned. If the argument NUMBER is given the headings will wrap to the next row
after NUMBER headings. By default headings are not wrapped.

=cut

sub wrap {

    #
    # wrap to next row after this num of headings
    #
    my $self = shift;
    if ( @_ ) {
        $self->{wrap} = shift;
    }
    return $self->{wrap};
}


=head1 INTERNALS

=head2 Private Class Methods

=head3 _link

 link($text, $href)

Returns a HTML 'a' tag pair linking to $href with text $text

=cut

sub _link {

    #
    # Create a link for some text to a href
    # Expects = (<text>,<href>) pair.
    #
    return qq(<a href="$_[1]">$_[0]</a>);
}



1;

__END__


=head1 PROPERTIES OF OO HEADINGS

These methods define the properties and behaviour of the object oriented
headings. Each OO heading can be tailored to specific requirements. Fresh new
OO headings are created by using the heading() method on a CGI::Widget::Tabs
object. Existing OO headings are returned by the headings() method. In the
tabs-demo.pl file OO headings are used as well. So look at that demo for a
real life example. Example:

    # create, append and return a new heading
    my $h = $tab->heading();

    # focus on the third heading
    my $h = ($tab->headings)[2];


The properties and behaviour of an OO heading can be set with the following
methods:

=over 4



=item B<class(STRING)>

Overrides the widget's CSS class for this heading. This is useful if you have
a specific heading (e.g. "Maintenance") which always needs it's own private
mark up. If the optional argument STRING is given, the class for this heading
is set. Otherwise it is retrieved.



=item B<key(STRING)>

Sets/returns the value to use for this heading in the CGI query param list.
This is similar to the use of keys in key/value pairs in the headings()
method. The goal is to simplify programming logic and shorten the URL's. (See
the headings() method  elsewhere in this document for further explanation).
Example:

    # display the full heading...
    # ...but use a small key as query param value
    $h->text("Remote Configurations");
    $h->key("rc");

In contrast to the use of key/value pairs, CGI::Widget::Tabs knows that this
is a key and not a value. After all, you are using the key() method, right?
Consequently you don't need the prepend the key with a hyphen ("-"). You may
consider using a hyphen for your keys nevertheless. It will lead to more
transparent code. Observe how the snippet from above with a prepended "-"
will later on result in the following check:

    if ( $tab->active eq "-rc" ) {  # clearly we are using keys ....

Consider this a mild suggestion.



=item B<raw(BOOLEAN)>

The heading text will normally be HTML encoded. If you wish you can use
hard coded HTML. To avoid escaping this HTML, you need to set raw() to a
logical TRUE. This is usually a 1 (one). Setting it to FALSE (usually a 0)
will re-enable HTML encoding. The optional argument BOOLEAN can be any
argument evaluating to a logical value. Setting raw() will not take effect
until the widget is rendered. So it does not matter when you set it, as long
as you haven't rendered the widget. Examples:

    # HTML encoded
    $h1->text("Names A > L");
    $h2->text("Names M < Z");

    # Raw
    $h1->text("Names A &gt; L");
    $h1->raw(1);

    $h2->text("Names M &lt; Z");
    $h2->raw(1);

    # get the encoding setting of the fourth element
    my $h = ($tab->headings)[3];
    my $raw = $h->raw;



=item B<text(STRING)>

Sets/returns the heading text. If the optional argument STRING is given, the
text will be set otherwise it will be returned. The heading text will be HTML
encoded unless explicitely told otherwise (see: raw()). Examples:

    # set heading text for the first two headings
    ($tab->headings)[0]->text("Names A > L");
    ($tab->headings)[1]->text("Names M < Z");

    # get the text of the 4th heading
    my $text = ($tab->headings)[3]->text;



=item B<url(STRING)>

Overrides the self referencing URL for this heading. If the optional argument
STRING is given the URL is set. Otherwise it is returned. The URL is used
exactly as given. This means that any query params and values need to be
added explicitely. If a URL is not set, the heading will get a default self
referencing URL. For trivial applications, you will mostly be using this one.
Note that generating the self referencing URL will be delayed until the tab
widget it rendered. This means it will not be returned by the url() method.
Example:

      $h->url("www.someremotesite.com");  # go somewhere else

      my $url = $h->url;                  # return the URL

=back

=head1 INSTALLATION

This module uses Module::Build for its installation. To install this module type
the following:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install


If you do not have Module::Build type:

  perl Makefile.PL

to fetch it. Or use CPAN or CPANPLUS and fetch it "manually".

=head1 DEPENDENCIES

This module requires these other modules and libraries:

 Carp
 CGI  or  CGI::Minimal or another CGI   "object broker" with   a similar param()
 method
 HTML::Entities
 Test::More
 URI::Escape

Test::More is only required for testing purposes.

This module has these optional dependencies:

 File::Find::Rule
 Test::Pod (0.95 or higher)

These are both just requried for testing purposes.

Also required, a CSS stylesheet for the tabs markup

=head1 LIMITATIONS AND EXTENSIBILITY

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

=head1 TODO

Just because these items are in the todo list, does not  mean they will actually
be done. If you think  one of these would  be helpful say  so - and it will then
move up on my priority list.

=over

=item *

Provide a hash  lookup as a  replacement mechanism for  $cgi->params() for those
who don't use CGI or CGI::Minimal

=item *

Add support for heading images instead of text

=item *

Consider replacing some/all of  the hand  crafted  get set  methods with use  of
Class::MethodMaker

=item *

Consider using Test::More in 003_main.t

=item *

Consider moving docs for Headings class into that class

=back

Patches always welcome.

=head1 BUGS

As a side effect, the CGI query parameter to identify the tab (see the
cgi_param() method) is always moved to the end of the query string.

To report a bug or request an enhancement use CPAN's excellent Request Tracker,
either via the web:

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Widget-Tabs>

or via email:

bug-cgi-widget-tabs@rt.cpan.org


=head1 CONTRIBUTIONS

I would appreciate receiving your CSS style sheets used for the tabs markup.
Especially if you happened to be professionally concerned with markup and
layout. For techies like us it is not always easy to see what goes and what
doesn't. If you send in a nice one, I will gladly bundle it with the next
release.

=head1 ACKNOWLEDGEMENTS

=over 4

=item Bodo Eing <eingb@uni-muenster.de>

=item Bernie Ledwick <bl@man.fwltech.com>

=item Bernhard Schmalhofer <Bernhard.Schmalhofer@biomax.de>

=back

=head1 AUTHOR

Koos Pol E<lt>koos_pol@raketnet.nlE<gt>

=head1 MAINTAINER

Sagar R. Shah

=head1 SEE ALSO

L<CGI>,    L<CGI::Minimal>,    CSS  specs:     L<http://www.w3.org/TR/REC-CSS1>,
L<http://www.w3.org/TR/REC-CSS2>

=cut

=head1 COPYRIGHT

Copyright 2003, Koos Pol, All rights reserved

Copyright 2003, Sagar R. Shah, All rights reserved

This program  is free software; you can  redistribute it  and/or modify it under
the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this
module.

=cut
