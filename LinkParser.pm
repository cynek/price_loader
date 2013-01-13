#
#===============================================================================
#
#         FILE: LinkParser.pm
#
#  DESCRIPTION: Get page and parse it for <a href=...MASK></a>
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 11.12.2012 22:59:55
#     REVISION: ---
#===============================================================================
package LinkParser;

use strict;
use warnings;
 
use LWP::UserAgent;
use HTML::LinkExtor;
use URI::URL;
use File::Basename;
use Carp;
use fields qw(source_url mask useragent parser urls);

sub parse_a_handler {
  my ($self) = @_;
  sub {
	my($tag, %attr) = @_;
	return if $tag ne 'a' 
           or !(my $filename_re = $self->{mask})
	       or !(my $href_endpath = ($attr{href} =~ m{([^/]+)$})[0]);
	for($filename_re) {
	  s/\*/.*?/;
      s/\$/.{1}/;
    }
  	return if $href_endpath !~ /($filename_re)$/;
  	push(@{$self->{urls}}, [$attr{href}, $1]);
  }
}

sub new {
  my ($self, $url, $mask, $cookies_file) = @_;
  $self = fields::new($self);
  $self->{source_url} = $url || die "source url should be set";
  $self->{mask} = $mask || die "filename mask should be set";
  $self->{useragent} = LWP::UserAgent->new(agent => "price_loader",
                                           cookie_jar => {file => $cookies_file},
                                           keep_alive => 1);
  $self->{parser} = HTML::LinkExtor->new($self->parse_a_handler);
  $self;
}

sub urls {
  my $self = shift;
  return @{$self->{urls}} if $self->{urls};
  # Request document and parse it as it arrives
  my $res = $self->{useragent}->request(HTTP::Request->new(GET => $self->{source_url}),
									 sub { $self->{parser}->parse($_[0]) });
  
  # Expand all image URLs to absolute ones
  my $base = $res->base;
  @{$self->{urls}} = map { $_->[0] = url($_->[0], $base)->abs; $_ } @{$self->{urls}};
  $self->{urls}
}

1;
