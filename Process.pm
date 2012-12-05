#===============================================================================
#
#         FILE: Process.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 24.11.2012 15:30:02
#     REVISION: ---
#===============================================================================
package Process;

use strict;
use warnings;
use POSIX;
use File::Basename;
use File::Glob ':glob';
use SupplierConfig;
use Mail;
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);

############## PRIVATE METHODS ################

my $die_now = sub {
  my $self = shift;
  $self->{nodestruct} = 1;
  die shift."\n";
};

=head1 $self->$write_pid
=cut
my $write_pid = sub {
  my $self = shift;
  sysopen(PID_FH, $self->{pidfile}, O_WRONLY | O_CREAT | O_EXCL)
    or $self->$die_now("pid file exists!");
  print PID_FH $$;
  close PID_FH;
};

my $fetch_mail = sub {
  my $self = shift;
  my $mail
};

=head1 $self->$go
=cut
my $go = sub {
  my $self = shift;
  my @config_files = glob($self->{config_dir}."/*.ini");
  
  
  # удаляем прошлые прайсы
  #TODO: исключить size.ttt
  unlink glob for(map({ dirname(__FILE__).'/'.(m/([^\/]+)\.ini$/)[0]."/*" } @config_files));
  
  # устанавливаем соединение с mail сервером
  my $mail = Mail->new();

  # читаем конфиги
  while(my $config_file = shift @config_files) {
    my $config = SupplierConfig->new($config_file);
	if($config->{usemail}) {
	  $self->$fetch_mail;
	} else {
	  $self->$fetch_http($config->{useauth});
	}
  }
};

################ PUBLIC METHODS ###############

=head1 run
  Конструктор
  my Process->run("./process.pid", "config_dir")  
=cut
sub run {
  my $class = shift;
  my $self = {
	pidfile => shift || die("Need pid file name"),
	config_dir => shift || die('Need config dir name')
  };
  bless $self, $class;
  $self->$write_pid();
  $self->$go();
  $self;
}	

sub DESTROY {
  my $self = shift;
  unlink $self->{pidfile} unless $self->{nodestruct};
}

1;
