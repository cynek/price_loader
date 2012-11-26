#
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
use SupplierConfig;
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

my $clean_supplier_dirs = sub {
  shift;
  for my $dir (@_) {
  }
};

=head1 $self->$go
=cut
my $go = sub {
  my $self = shift;
  my @config_files = glob($self->{config_dir}."/*.ini");
  
  while(my $config_file = shift @config_files) {
    my $config = SupplierConfig->new($config_file);
	
    while(my ($k,$v) = each %{$config}) {
      print "$k = $v\n";
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
