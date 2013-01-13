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
 
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use LinkParser;
use URI::URL;
use LWP::UserAgent;
use File::Basename;
use AuthFormParser;
use Carp;
use fields qw(source mask authoptions useragent urls);

sub new {
  my ($self, $source, $mask, $dir, %authoptions) = @_;
  $self = fields::new($self);
  $self->{source} = $source || die "loadpage should be set";
  $self->{mask} = $mask || die "filename template should be set";
  $self->{authoptions} = \%authoptions if scalar(keys(%authoptions));
  $self->{useragent} = LWP::UserAgent->new(agent => "price_loader",
                                           cookie_jar => {file => dirname(__FILE__)."/.cookies.txt"},
                                           keep_alive => 1,
                                           env_proxy => 1);
  print for $self->{urls} = LinkParser->new($source, $mask, dirname(__FILE__)."/.cookies.txt")->urls;
  $self;
}

sub fetch {
  my ($self, $dir_to_save) = @_;
  my @fetched_files = ();

  $| = 1;  # autoflush
  for my $url ($self->{urls}) {
    open PRICE, '>', "$dir_to_save/$url->[1]" or
      die "Can't write $url->[1]: $!";

	binmode PRICE;
	my $res = $self->{useragent}->request(HTTP::Request->new(GET => $url->[0]), sub {
          print PRICE shift;
		});
	close PRICE;
    if ($res->header("X-Died") || !$res->is_success) {
	  carp "can't download $url->[0], because: $res->status_line";
	} else {
	  push @fetched_files, $url->[1];
	}
  }
  $| = 0;
  @fetched_files;
}

1;
