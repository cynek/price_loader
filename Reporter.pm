#
#===============================================================================
#
#         FILE: Reporter.pm
#
#  DESCRIPTION: Создает отчет
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 23.01.2013 23:12:55
#     REVISION: ---
#===============================================================================

package Reporter;
use strict;
use warnings;
use File::Basename;
use POSIX;
use fields qw(file statuses);

use constant STATUSES => {not_found_from_email => 1,
					      not_found_from_web   => 2,
				          price_is_old         => 3,
				          success_loaded       => 4,
				          error                => 5};
sub new {
  my ($self) = @_;
  $self = fields::new($self);
  $self->{file} = dirname(__FILE__)."/".strftime('%Y%m%d%H%M', localtime).'.csv';
  $self->{statuses} = [];
  $self
}

sub add_status {
  my ($self, $supplier, $status, $msg) = @_;
  $status = STATUSES->{$status};
  $status .= ": $msg" if $msg;
  push $self->{statuses}, [$supplier, $status];
  0
}

sub report {
  my ($self) = @_;
  open REPORT, '>', $self->{file};
  for my $status (@{$self->{statuses}}) {
    print REPORT join(';', @{$status}), "\n";
  }
  close REPORT;
}

1;
