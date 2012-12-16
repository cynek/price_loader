#
#===============================================================================
#
#         FILE: WebLoader.pm
#
#  DESCRIPTION: Parse page for <a href=...FILENAME></a> and download it
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
use Carp;
use fields qw(loadpage filename_t authoptions useragent parser urls);

sub new {
  my ($self, $loadpage, $filename_t, $dir, %authoptions) = @_;
  $self = fields::new($self);
  $self->{loadpage} = $loadpage || die "loadpage should be set";
  $self->{filename_t} = $filename_t || die "filename template should be set";
  $self->{authoptions} = \%authoptions if scalar(keys(%authoptions));
  $self->{useragent} = LWP::UserAgent->new;
  $self->{parser} = HTML::LinkExtor->new(sub {
	my($tag, %attr) = @_;
	return if $tag ne 'a' 
           or !(my $filename_re = $self->{filename_t})
	       or !(my $href_endpath = ($attr{href} =~ m{([^/]+)$})[0]);
	for($filename_re) {
	  s/\*/.*?/;
      s/\$/.{1}/;
    }
  	return if $href_endpath !~ /($filename_re)$/;
  	push(@{$self->{urls}}, [$attr{href}, $1]);
  });
  $self;
}

sub urls {
  my $self = shift;
  return @{$self->{urls}} if $self->{urls};
  # Request document and parse it as it arrives
  my $res = $self->{useragent}->request(HTTP::Request->new(GET => $self->{loadpage}),
									 sub { $self->{parser}->parse($_[0]) });
  
  # Expand all image URLs to absolute ones
  my $base = $res->base;
  @{$self->{urls}} = map { $_->[0] = url($_[0], $base)->abs; $_ } @{$self->{urls}};
};

sub fetch {
  my ($self, $dir_to_save) = @_;
  my @fetched_files = ();
  for my $url ($self->urls) {
	my $res = $self->{useragent}->request(HTTP::Request->new(GET => $url->[0]), "$dir_to_save/$url->[1]");
    if($res->is_success) {
	  push @fetched_files, $url->[1];
	} else {
	  carp "can't download $url->[0], because: $res->status_line";
	}
  }
  @fetched_files;
}

1;
