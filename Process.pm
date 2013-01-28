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
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use File::Temp qw(tempdir);
use Digest::MD5 qw(md5_hex);
use Archive::Extract;

use SupplierConfig;
use MailLoader;
use WebLoader;
use Reporter;
use Utils;

use constant HASH_FILENAME => 'size.ttt';

############## PRIVATE METHODS ################
my $hash_changed = sub {
  my ($self, $config, $dir, @price_files) = @_;
  my $filemode = -e (my $hash_filepath = $config->{supplier_dir}.'/'.HASH_FILENAME) ? '+<' : '+>';
  open HASH_FILE, $filemode, $hash_filepath or die "$0: can't open hash file $hash_filepath: $!\n";
  my $old_hash = <HASH_FILE> || '';
  chomp $old_hash;
  my $new_hash = '';
  {
    undef(local $/);
    for my $price_filename (@price_files) {
      $price_filename = $dir . '/' . $price_filename;
      open(my $price_fh, '<', $price_filename) or die "$0: can't open price file $price_filename: $!\n";
      $new_hash .= <$price_fh>;
      close $price_fh;
    }
  }
  $new_hash = md5_hex($new_hash); 
  my $is_changed = !($new_hash eq $old_hash);
  if($is_changed) {
	close HASH_FILE;
	open HASH_FILE, ">", $hash_filepath;
	print HASH_FILE $new_hash;
  }
  close HASH_FILE;
  $is_changed
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
	eval {
	  my $tmpdir = tempdir(CLEANUP => 1);
      my $web_loader = WebLoader->new($config->{loadpage}, $config->{filename}, $config) unless $config->{usemail};

      my $fetched = $config->{usemail} ?
	    $mail_loader->fetch($config->{mailfrom}, $config->{filename}, $tmpdir, $self->{mailport}, $self->{mailfolder}) || $self->{reporter}->add_status($config->{supplier}, 'not_found_from_email') :
        $web_loader->fetch($tmpdir) || $self->{reporter}->add_status($config->{supplier}, 'not_found_from_web');
	  next unless $fetched;

      # Разархивируем все архивы 
	  my %unarchived;
	  for my $file (@{$fetched}) {
        if(grep { $file =~ /\.$_$/ } Archive::Extract->types) {
          my $archive = Archive::Extract->new(archive => "$tmpdir/$file");
	  	  $archive->extract(to => $tmpdir);
	      $unarchived{$file} = $archive->files;
        }
	  }
	  # и заменим их в $fetched на распакованные
	  @{$fetched} = map { my $u = $unarchived{$_}; $u ? @{$u} : $_ } @{$fetched};

	  # если указан filenameinner выбираем по этому шаблону
	  if(my $filenameinner_re = $config->{filenameinner}) {
        $filenameinner_re = Utils->pattern_to_regexp($filenameinner_re);
        @{$fetched} = grep /$filenameinner_re$/, @{$fetched};
      }

	  mkdir $config->{supplier_dir} unless -d $config->{supplier_dir};
	  if($self->$hash_changed($config, $tmpdir, @{$fetched})) {
	    rename "$tmpdir/$_", "$config->{supplier_dir}/$_" for @{$fetched};
        $self->{reporter}->add_status($config->{supplier}, 'success_loaded') if @{$fetched};
	  } else {
        $self->{reporter}->add_status($config->{supplier}, 'price_is_old');
	  }
    };
    $self->{reporter}->add_status($config->{supplier}, 'error', $@) if $@;
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
	config_dir => shift || die('Need config dir name'),
	reporter   => Reporter->new
  };
  bless $self, $class;
  $self->$go();
  $self->{reporter}->report;
  $self;
}	

1;
