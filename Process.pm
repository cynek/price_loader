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
use Digest::MD5 qw(md5_hex);

use constant HASH_FILENAME => 'size.ttt';

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

my $new_hash = sub {
  my ($self, $config, $dir, @price_files) = @_;
  my $filemode = -e (my $hash_filepath = $config->{supplier_dir}.'/'.HASH_FILENAME) ? '+<' : '+>';
  open HASH_FILE, $filemode, $hash_filepath or die "$0: can't open hash file: $!\n";
  my $old_hash = <HASH_FILE> || '';
  chomp $old_hash;
  my $new_hash = '';
  {
    undef(local $/);
    for my $price_filename (@price_files) {
      $price_filename = $dir . '/' . $price_filename;
      open(my $price_fh, '<', $price_filename) or die "$0: can't open price file: $!\n";
      $new_hash .= <$price_fh>;
      close $price_fh;
    }
  }
  $new_hash = md5_hex($new_hash); 
  my $is_changed = !($new_hash eq $old_hash);
  print $new_hash, " && ", $old_hash, "\n";
  if($is_changed) {
	truncate HASH_FILE, 0;
	print HASH_FILE $new_hash;
  }
  close HASH_FILE;
  $is_changed ? $new_hash : 0;
};

=head1 $self->$go
=cut
my $go = sub {
  my $self = shift;
  my @config_files = glob($self->{config_dir}."/*.ini");

  # читаем конфиги
  my @suppliers_configs = map { SupplierConfig->new($_) } @config_files;
  
  # удаляем прошлые прайсы кроме файла с хэшем HASH_FILENAME
  (my $hash_filename_re_esc = HASH_FILENAME) =~ s/\./\./;
  unlink grep(!/\/$hash_filename_re_esc/, glob) for(map { $_->{supplier_dir}.'/*' } @suppliers_configs);
  
  # постоянное подключение почтового сервера для всех конфигов
  my $mail_loader = MailLoader->new($self->{app_config}->{mailuser},
					   $self->{app_config}->{mailpassword},
					   $self->{app_config}->{mailhost});

  for my $config (@suppliers_configs) {
	my $tmpdir = tempdir(CLEANUP => 1);
	my @files;
    my $web_loader = WebLoader->new($config->{loadpage}, $config->{filename}, $config) unless $config->{usemail};

	@files = $config->{usemail} ?
	  $mail_loader->fetch($config->{mailfrom}, $tmpdir) :
      $web_loader->fetch($tmpdir);

	mkdir $config->{supplier_dir} unless -d $config->{supplier_dir};
	if($self->$new_hash($config, $tmpdir, @files)) {
	  rename $tmpdir.'/'.$_, $config->{supplier_dir}.'/'.$_ for @files;
	}
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
