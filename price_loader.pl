#!/usr/bin/perl 
#===============================================================================
#
#         FILE: price_loader.pl
#
#        USAGE: ./price_loader.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 24.11.2012 16:16:42
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use File::Basename;
use Thread;
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use Process;
use Config::General;

my $current_dir = dirname(__FILE__);
my $pidfile = "$current_dir/price_loader.pid";
my $general_config_file = $current_dir . '/config.ini';

our $pid_created = sysopen(PID_FH, $pidfile, O_WRONLY | O_CREAT | O_EXCL);
die "pid file exists!" unless $pid_created;
print PID_FH $$;
close PID_FH;

my %app_config;
eval {
  %app_config = Config::General->new($general_config_file)->getall;
};
die "$0: err in general config $general_config_file: $@" if $@;

# Если нужно увеличить скорость по HTTP - можно добавить по отдельному потоку
# на каждого Web поставщика
#my $p = Thread->new(sub {
  Process->run(\%app_config, "$current_dir/iniz");
#});
#eval {
#  $p->join;
#};
print "END\n";

END {
  unlink $pidfile if our $pid_created;
}
