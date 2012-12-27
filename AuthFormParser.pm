package AuthFormParser;

use pQuery;
sub parse {
  my ($url, $form_selector, $login_id, $password_id) = @_;
  my %params;
  pQuery($url)->find($form_selector)->each(sub {
    pQuery($_)->find('input')->each(sub {
      my $input = $_->toHtml;
      my ($name) = $input =~ /name=(\S+)[/>]/;
      my ($value) = $input =~ /value=(\S+)[/>]/;
      $params{$name} = $value;
    });
  });
  %params;
}
1;
