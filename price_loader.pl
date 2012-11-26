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
use Process;
my $current_dir = dirname(__FILE__);

my $p = Thread->new(sub {
  Process->run($current_dir."/price_loader.pid", $current_dir.'/iniz');
});
eval {
  $p->join;
};
print "END\n";
