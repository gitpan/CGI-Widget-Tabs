# $Id: Heading.pm,v 1.4 2003/01/16 21:25:35 koos Exp $

use strict;
use HTML::Entities;

package CGI::Widget::Tabs::Heading;

# ----------------------------------------------
sub new {
# ----------------------------------------------
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    $self->raw(0);  # by default text is HTML escaped
    return $self;
}



# ----------------------------------------------
sub key {
# ----------------------------------------------
    #
    # The key to identify this heading with
    #
    my $self = shift;
    if ( @_ ) {
        $self->{key} = shift;
    }
    return $self->{key};
}



# ----------------------------------------------
sub text {
# ----------------------------------------------
    #
    # Text to be displayed
    #
    my $self = shift;
    my $text;

    if ( @_ ) {
        $self->{text} = shift;
    }
    if ( $self->raw ) {
        $text = $self->{text};
    } else {
        $text = HTML::Entities::encode_entities( $self->{text} );
    }
    return $text;
}



# ----------------------------------------------
sub raw {
# ----------------------------------------------
    #
    # Raw or HTML escaped?
    #
    my $self = shift;
    my $arg = shift;

    if ( defined $arg ) {
        $self->{raw} =  $arg ? 1 : 0;
    }
    return $self->{raw};
}



# ----------------------------------------------
sub url {
# ----------------------------------------------
    #
    # The redirect URL where this tab heading points to
    #
    my $self = shift;
    if ( @_ ) {
        $self->{url} = shift;
    }
    return $self->{url};
}

1;

__END__

=head1 NAME

CGI::Widget::Tabs::Heading - Create OO tab headings for CGI::Widget::Tabs objects

This module is designed to work with CGI::Widget::Tabs. You can not use this module
in a standalone fashion. Look at the CGI::Widget::Tabs documentation for more info.

=cut