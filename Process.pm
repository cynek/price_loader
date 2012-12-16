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
use MailLoader;
use WebLoader;
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use File::Temp qw(tempdir);

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

=head1 $self->$go
=cut
my $go = sub {
  my $self = shift;
  my @config_files = glob($self->{config_dir}."/*.ini");

  # читаем конфиги
  my @suppliers_configs = map { SupplierConfig->new($_) } @config_files;
  
  # удаляем прошлые прайсы кроме файла с хэшем size.ttt
  unlink grep(!/\/size\.ttt$/, glob) for(map { $_->{supplier_dir}.'/*' } @suppliers_configs);
  
  # постоянное подключение почтового сервера для всех конфигов
  my $mail_loader = MailLoader->new($self->{app_config}->{mailuser},
					   $self->{app_config}->{mailpassword},
					   $self->{app_config}->{mailhost});

  for my $config (@suppliers_configs) {
	my $tmpdir = tempdir(CLEANUP => 1);
	my @files;
    my $web_loader = WebLoader->new($config->{loadpage}, $config->{filename});

	@files = $config->{usemail} ?
	  $mail_loader->fetch($config->{mailfrom}, $tmpdir) :
      $web_loader->fetch($tmpdir);

	mkdir $config->{supplier_dir} unless -d $config->{supplier_dir};
	rename $tmpdir.'/'.$_, $config->{supplier_dir}.'/'.$_ for @files;
  }
};

################ PUBLIC METHODS ###############

=head1 run
  Конструктор
  my Process->run($app_config, "./process.pid", "config_dir")  
=cut
sub run {
  my $class = shift;
  my $self = {
	app_config => shift,
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
