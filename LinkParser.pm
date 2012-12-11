#
#===============================================================================
#
#         FILE: LinkParser.pm
#
#  DESCRIPTION: Parse page for <a href=...FILENAME></a>
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
package WebLoader;

use strict;
use warnings;
 
use LWP::UserAgent;
use HTML::LinkExtor;
use URI::URL;
use fields qw(loadpage filename authoptions useragent parser urls)

sub new {
  my ($self, $loadpage, $filename, %authoptions) = @_;
  $self = fields::new($self);
  $self->{loadpage} = $loadpage || die "loadpage should be set";
  $self->{filename} = $loadpage || die "filename template should be set";
  $self->{authoptions} = \%authoptions if scalar(keys(%authoptions));
  $self->{useragent} = LWP::UserAgent->new;
  $self->{urls} = [];
  $self->{parser} = HTML::LinkExtor->new(sub {
	my($tag, %attr) = @_;
  	return if $tag ne 'a' or $attr{href} !~ /$self->{filename}$/o;
  	push(@{$self->{urls}}, $attr{href});
  });
  $self;
}

sub parse {
  my ($self) = @_;
  # Request document and parse it as it arrives
  $res = $self->{useragent}->request(HTTP::Request->new(GET => $self->{loadpage}),
									 sub {$p->parse($_[0])});
  
  # Expand all image URLs to absolute ones
  my $base = $res->base;
  @{$self->{urls}} = map { $_ = url($_, $base)->abs } @{$self->{usls}};
  
  # Print them out
  print join("\n", @{$self->{urls}}), "\n";
  $self->{urls};
}
