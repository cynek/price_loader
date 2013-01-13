package AuthFormParser;

require Exporter;
use Web::Query;
our @ISA = ('Exporter');
our @EXPORT = qw(parse);

sub auth_params {
  my ($url, $form_selector) = @_;
  my %params;
  my $query = Web::Query->new_from_url($url) or die "$0: can't open auth url $url: $!";
  
  $query->find($form_selector)->each(sub {
	my (undef, $form) = @_;
    $form->find('input')->each(sub {
      my (undef, $input) = @_;
      $params{$input->attr('name')} = $input->attr('value');
    });
  });
  %params;
}

1;
