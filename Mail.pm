#
#===============================================================================
#
#         FILE: Mail.pm
#
#  DESCRIPTION: Загружает прайсы с email (IMAP) сервера
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 05.12.2012 22:37:29
#     REVISION: ---
#===============================================================================
package Mail;

use strict;
use warnings;
 

use Email::MIME;
use IO::Socket::SSL;
use Mail::IMAPClient;
use File::Basename;

use fields qw{connection debug};
my $email_regexp = qr/^\w+(?:\.\w+)*@\w+(?:\.\w+)*$/;
sub new {
  my ($self, $user, $password, $host, $port, $debug) = @_;
  unless(ref $self) {
	  $self = fields::new($self);
	  $self->{connection} = Mail::IMAPClient->new(User => $user,
												  Password => $password,
												  Uid		 => 1,
												  Peek	     => 1,
												  Socket	 => IO::Socket::SSL->new(
												  			  Proto	=> 'tcp',
												  			  PeerAddr => $host,
												  			  PeerPort => $port || 993));
	  die "$0: connect: $@" if defined $@;
  }
  $self->{debug} = $debug || 0;
  $self;
}

sub fetch {
  my ($self, $mailfrom, $dir) = @_;
  die "$0: invalid mailfrom: $mailfrom" unless $mailfrom =~ $email_regexp;
  for my $message_id ($self->{connection}->search(FROM => $mailfrom)) {
	die "$0: badly imap message ID: $message_id" unless $message_id =~ /\A\d+\z/;

	my $message = $self->{connection}->message_string($message_id)
	  or die "$0: message_string: $@";

	my $file_num = 1;
	Email::MIME->new($message)->walk_parts(sub {
		my ($part) = @_;
		return unless $part->content_type =~ /\bname="([^"]+)"/;

		my $filepath = dirname(__FILE__) . "/$dir/" . $file_num++ . "-$1";
		print "$0: writing file: $filepath" if $self->{debug};

		open my $fh, '>', $filepath
		  or die "$0: open $filepath: $!";

		print $fh $part->content_type =~ /^text/ ?
					$part->body_str :
					$part->body
		  or die "$0: print $filepath: $!";
		close $fh or die "$0: close $filepath: $!";
	  })
  }
}

sub DESTROY {
	my $self = shift;
	$self->{connection}->disconnect;
}

1;
