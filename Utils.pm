#
#===============================================================================
#
#         FILE: Utils.pm
#
#  DESCRIPTION: Утилиты
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 29.01.2013 01:04:43
#     REVISION: ---
#===============================================================================

package Utils;
use strict;
use warnings;

sub pattern_to_regexp {
  my ($self, $pattern) = @_;
  for($pattern) {
	s/\./\\./g;
    s/\*/.*?/g;
    s/\$/.{1}/g;
  }
  $pattern;
}
1;
