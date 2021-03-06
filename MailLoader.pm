#
#===============================================================================
#
#         FILE: MailLoader.pm
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
package MailLoader;

use strict;
use warnings;
 

use Email::MIME;
use IO::Socket::SSL;
use Mail::IMAPClient;
use File::Basename;
use Utils;

use fields qw{connection debug};
my $email_regexp = qr/^\w+(?:\.\w+)*@\w+(?:\.\w+)*$/;
sub new {
  my ($self, $user, $password, $host, $port, $folder, $debug) = @_;
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
	  die "$0: connect: $@" if $@;
	  $self->{connection}->select($folder || 'INBOX');
	  die "$0: select folder: $@" if $@;
  }
  $self->{debug} = $debug || 0;
  $self;
}

sub fetch {
  my ($self, $mailfrom, $filename_pattern, $dir) = @_;
  die "$0: invalid mailfrom: $mailfrom" unless $mailfrom =~ $email_regexp;

  my $filename_re = Utils->pattern_to_regexp($filename_pattern);
  my @filenames;
  for my $message_id ($self->{connection}->search(FROM => $mailfrom, 'UNSEEN')) {
	die "$0: badly imap message ID: $message_id" unless $message_id =~ /\A\d+\z/;

	my $message = $self->{connection}->message_string($message_id)
	  or die "$0: message_string: $@";

	Email::MIME->new($message)->walk_parts(sub {
		my ($part) = @_;
		return unless $part->content_type =~ /\bname="($filename_re)"/;

		my $filename = $1;
		push @filenames, $filename;
		my $filepath = $dir . '/' . $filename;
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
  \@filenames;
}

sub DESTROY {
	my $self = shift;
	$self->{connection}->disconnect;
}

1;
