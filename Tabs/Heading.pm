# $Id: Heading.pm,v 1.3 2002/11/02 13:42:49 koos Exp $

use strict;
use warnings;
use HTML::Entities;

package CGI::Widget::Tabs::Heading;

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
    # The HTML unescaped text to display on the tab heading
    #
    my $self = shift;
    if ( @_ ) {
        $self->{text} = HTML::Entities::encode_entities(shift);
    }
    return $self->{text};
}



# ----------------------------------------------
sub raw_text {
# ----------------------------------------------
    #
    # The HTML escaped text to display on the tab heading
    #
    my $self = shift;
    if ( @_ ) {
        $self->{raw_text} = shift;
    }
    return $self->{raw_text};
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
