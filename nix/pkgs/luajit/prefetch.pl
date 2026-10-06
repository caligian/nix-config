#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

my $src = $ARGV[0] // "common.nix";
my %res = ();
my $lines;
my $fh;

open $fh, "<", $src;
$lines = do {local $/; <$fh>; };
close $fh;

while ( $lines =~ /^[ ]*(\w[\w-]+)\s*=\s*mkRock\s*\{(.*?)\n\s*\};/gms ) {
  my ($name, $body) = ($1, $2);
  my @body;
  @body = grep {$_ =~ /(name|commit|owner|repo)\s*=/ } split "\n", $body;

  foreach my $line ( @body ) {
    $line =~ s/^\s*//; 
    $line =~ s/\s*$//;
    $line =~ s/"//g;
    $line =~ s/;//g;
    my @kv = split /\s*=\s*/, $line; 
    $res{$name} = $res{$name} // {};
    $res{$name}{$kv[0]} = $kv[1];
  }
}

foreach my $pkg ( keys %res ) {
  my $name = $pkg;
  my $owner = $res{$pkg}{owner};
  my $repo = $res{$pkg}{repo};
  my $commit = $res{$pkg}{commit};
  my $hash = qx{nix-prefetch-url --unpack "https://github.com/$owner/$repo/archive/$commit.tar.gz"};
  my $sri = qx{nix hash convert --hash-algo sha256 --to sri $hash};
  chomp $sri;
  print "$name [$owner/$repo] -> $sri\n";
}
