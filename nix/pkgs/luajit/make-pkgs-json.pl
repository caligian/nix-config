use strict;
use warnings;
use Data::Dumper;
use JSON::PP qw(encode_json decode_json);

my $src_file = "pkgs.txt";
open(my $src_fh, "<", $src_file);
my @repos = <$src_fh>;
chomp @repos;
my %repos = ();

foreach my $line (@repos) {
  my ($name, $url) = split(/\s+/, $line);
  $repos{$name} = {};
  my $json = qx{nix-prefetch-git --quiet "$url"};
  my %res  = %{ decode_json($json) };

  foreach my $key (keys(%res)) {
    $repos{$name}{$key} = $res{$key};
  }

  $repos{$url} = $url;
}

open(my $fh, ">", "./pkgs.json");
print $fh encode_json(\%repos);
print(Dumper(\%repos));

