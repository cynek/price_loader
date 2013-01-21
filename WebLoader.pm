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
 
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use LWP::UserAgent;
use HTML::LinkExtor;
use URI::URL;
use File::Basename;
use Carp;
use AuthFormParser;
use Web::Query;
use Encode qw(encode);
use fields qw(loadpage filename_t authoptions useragent parser urls);

sub new {
  my ($self, $loadpage, $filename_t, $authoptions) = @_;
  $self = fields::new($self);
  $self->{loadpage} = $loadpage || die "loadpage should be set";
  $self->{filename_t} = $filename_t || die "filename template should be set";
  if($authoptions->{useauth}) {
    $self->{authoptions} = {};
	@{$self->{authoptions}}{'authpage','formauth','formlogin','formpassword', 'login', 'password'} =
      @$authoptions{'authpage','formauth','formlogin','formpassword', 'login', 'password'};
  }

  $self->{useragent} = LWP::UserAgent->new(agent => "price_loader",
                                           cookie_jar => {file => dirname(__FILE__)."/.cookies.txt",
										                  autosave => 1},
                                           keep_alive => 1,
                                           env_proxy => 1);
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

# Парсит форму авторизации. возвращает ее action, method и все input тэги
sub auth_params {
  my ($self, $url, $form_selector) = @_;
  my %inputs;
  my $query = Web::Query->new_from_url($url) or die "$0: can't open auth url $url: $!";
  
  my $form = $query->find($form_selector);
  $form->each(sub {
	my (undef, $form) = @_;
    $form->find('input')->each(sub {
      my (undef, $input) = @_;
	  return unless $input->attr('name');
      my $name = $input->attr('name');
      $inputs{$name} = $name eq $self->{authoptions}->{formlogin} ? $self->{authoptions}->{login} :
                       $name eq $self->{authoptions}->{formpassword} ? $self->{authoptions}->{password} :
                       $input->attr('value');
    });
  });
  return ($form->attr('action') || $url,
		  %inputs);
}

sub authorize {
  my ($self) = @_;
  my ($auth_url, %auth_params) = $self->auth_params($self->{authoptions}->{authpage}, $self->{authoptions}->{formauth});
  my $res = $self->{useragent}->post($auth_url, \%auth_params);

  croak "can't authorize, because: ".$res->status_line if ($res->header("X-Died") || !($res->is_success || $res->is_redirect))
}

sub urls {
  my $self = shift;
  return @{$self->{urls}} if $self->{urls};
  # Request document and parse it as it arrives
  my $res = $self->{useragent}->request(HTTP::Request->new(GET => $self->{loadpage}),
									 sub { $self->{parser}->parse($_[0]) });
  
  # Expand all links URLs to absolute ones
  my $base = $res->base;
  @{$self->{urls}} = map { $_->[0] = url($_->[0], $base)->abs; $_ } @{$self->{urls}};
};

sub fetch {
  my ($self, $dir_to_save) = @_;
  $self->authorize if $self->{authoptions};

  my @fetched_files = ();

  carp "Not found links for download on $self->{loadpage}" unless scalar $self->urls;
  $| = 1;  # autoflush
  for my $url ($self->urls) {
    open PRICE, '>', "$dir_to_save/$url->[1]" or
      die "Can't write $url->[1]: $!";

	binmode PRICE;
	my $res = $self->{useragent}->request(HTTP::Request->new(GET => $url->[0]), sub {
          print PRICE shift;
		});
	close PRICE;
    if ($res->header("X-Died") || !$res->is_success) {
	  carp "can't download ".$url->[0].", because: ".$res->status_line;
	} else {
	  push @fetched_files, $url->[1];
	}
  }
  $| = 0;
  @fetched_files;
}

1;
