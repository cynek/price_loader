package SupplierConfig;

=pod

=head1 NAME

Config - price download configuration

=head1 SYNOPSIS

  my $object = Config->new(config_file);

=head1 DESCRIPTION

Have setting propeties from config_file (<supplier>-<region>.ini)

=head1 METHODS

=cut

use 5.010;
use strict;
use warnings;
use File::Basename;

our $VERSION = '0.01';
our $default_fields = {
  usemail       => undef, # - использовать почт. Значение – 0/1
  mailfrom      => undef, # - адрес отправителя прайса
  useauth       => undef, # - есть или нет авторизация. Значение – 0/1
  authpage      => undef, # - страница авторизации. Значение – URL
  loadpage      => undef, # – страница загрузки прайса. Значение – URL
  formauth      => undef, # – идентификатор формы для авторизации. Значение - текст
  formlogin     => undef, # – идентификатор поля имени пользователя. Значение - текст
  formpassword  => undef, # - идентификатор поля пароля. Значение – текст
  login         => undef, # – логин. Значение – текст
  password      => undef, # – пароль. Значение – текст
  filename      => undef, # – шаблон имени файла для загрузки. Значение – текстовое поле с символами подстановки. Символы подстановки: * - любо количество символов, $ - один символ.
  filenameinner => undef, #- шаблон имени файла внутри архива на тот случай, если в архиве несколько файлов. Значение – текстовое поле с символами подстановки. Символы подстановки: * - любо количество символов, $ - один символ.
};
my $url_regexp = qr{^(?:http|ftp|https):\/\/[\w\-_]+(?:\.[\w\-_]+)+(?:[\w\-\.,@?^=%&amp;:/~\+#]*[\w\-\@?^=%&amp;/~\+#])?$};
my $domid_regexp = qr/^(?:\w|\-)+/;
my $file_pattern_regexp = qr{^(?:\w|\*|\$)+$};
my $validates = {
  usemail       => qr/^0|1$/,              # - использовать почт. Значение – 0/1
  mailfrom      => qr/^\w+(?:\.\w+)*@\w+(?:\.\w+)*$/,     # - адрес отправителя прайса
  useauth       => qr/^0|1$/,              # - есть или нет авторизация. Значение – 0/1
  authpage      => $url_regexp,          # - страница авторизации. Значение – URL
  loadpage      => $url_regexp,          # – страница загрузки прайса. Значение – URL
  formauth      => $domid_regexp,        # – идентификатор формы для авторизации. Значение - текст
  formlogin     => $domid_regexp,        # – идентификатор поля имени пользователя. Значение - текст
  formpassword  => $domid_regexp,        # - идентификатор поля пароля. Значение – текст
  login         => qr/^\w+$/,              # – логин. Значение – текст
  password      => qr/^.+/,                # – пароль. Значение – текст
  filename      => $file_pattern_regexp, # – шаблон имени файла для загрузки. Значение – текстовое поле с символами подстановки. Символы подстановки: * - любо количество символов, $ - один символ.
  filenameinner => $file_pattern_regexp, #- шаблон имени файла внутри архива на тот случай, если в архиве несколько файлов. Значение – текстовое поле с символами подстановки. Символы подстановки: * - любо количество символов, $ - один символ.
};

my $merge_fields_with = sub {
  my $self = shift;
  my $lines = shift;
  while(my $line = shift(@{$lines})) {
	$line =~ s/\s//g;
    my ($field, $value) = split('=', $line);
    $self->{$field} = $value if(exists($self->{$field}));
  }
};

our $validate = sub {
  my $self = shift;
  my @errors;
  while(my ($field, $value) = each %{$self}) {
    push @errors, $field unless($value =~ $validates->{$field});
  }
  \@errors;
};
=pod

=head2 new

  my $object = Config->new('planet-ekt.ini');

The C<new> constructor lets you create a new B<Config> object.

Returns a new B<Config> or dies on error.

=cut

sub new {
  my ($class, $file) = @_;
  die "$0: file arg must be set" unless $file;
  my %fields = (%{$default_fields}, 'file' => $file, 'supplier_dir' => dirname(__FILE__).'/'.($file =~ m/([^\/]+)\.ini$/)[0]);
  my $self = bless { %fields }, $class;
  $self->parse; 
}

=pod

=head2 parse

Parse config file into fields

=cut

sub parse {
  my $self = shift;

  open(CONFIG_FILE, '<', $self->{file}) or die "Can't open ".$self->{file};
  my $lines = [];
  @{$lines} = <CONFIG_FILE>;
  close CONFIG_FILE;

  $self->$merge_fields_with($lines);
  my $errors = $validate->();
  die join(',', @{$errors}) if(scalar(@{$errors}));
  $self;
}

1;

=pod

=head1 SUPPORT

No support is available

=head1 AUTHOR

Copyright 2011 Anonymous.

=cut
