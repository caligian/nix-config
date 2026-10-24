#!/usr/bin/env perl

use strict;
use warnings;

sub foot {
  my ($app_id, $app) = @_;
  return qq{foot -c ~/.user/foot/config.ini -a "$app_id" -e "$app"};
}

my %fav = (
  "File browser"         => foot("yazi-file-browser", "yazi"),
  "Music player"         => foot("cmus-music-player", "cmus"),
  "Spreadsheet"          => "libreoffice --calc",
  "Document editor"      => "libreoffice --writer",
  "Ebook viewer"         => "ebook-viewer",
  "Browser (new window)" => "chromium --new-window",
  "Browser"              => "chromium",
  "Media player"         => "vlc",
  "Calendar"             => "gnome-calendar",
  "Calculator"           => "gnome-calculator",
  "Bluetooth Devices"    => "blueman-manager",
  "Edit connections"     => "nm-connection-editor",
  "Networks"             => "nmgui",
);

my $apps = join("\n", keys(%fav));
my $choice =
qx{echo "$apps" | rofi -dmenu -i -p "Favorite apps" -font "Liberation Mono 14"};

chomp $choice;
$choice =~ s/\s+\z//;

qx{$fav{$choice}} if $choice ne "";
