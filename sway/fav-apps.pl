#!/usr/bin/env perl

use strict;
use warnings;

sub foot {
  my ($app_id, $app) = @_;
  return qq{foot -c ~/.user/foot/config.ini -a "$app_id" -e "$app"};
}

my %fav = (
  "Audio control (Pavucontrol)" => "pavucontrol",
  "File browser (yazi)"         => foot("yazi-file-browser", "yazi"),
  "Music player (cmus)"         => foot("cmus-music-player", "cmus"),
  "Spreadsheet (libreoffice-calc)"          => "libreoffice --calc",
  "Document editor (libreoffice-writer)"    => "libreoffice --writer",
  "Ebook viewer (ebook-viewer)"             => "ebook-viewer",
  "Browser (new window) (chromium)"         => "chromium --new-window",
  "Browser (chromium)"                      => "chromium",
  "Media player (vlc)"                      => "vlc",
  "Calendar (gnome-calendar)"               => "gnome-calendar",
  "Calculator (gnome-calculator)"           => "gnome-calculator",
  "Bluetooth Devices (blueman-manager)"     => "blueman-manager",
  "Edit connections (nm-connection-editor)" => "nm-connection-editor",
  "Networks (nmgui)"                        => "nmgui",
);

my $apps = join("\n", keys(%fav));
my $choice =
qx{echo "$apps" | rofi -dmenu -i -p "Favorite apps" -font "Liberation Mono 14"};

chomp $choice;
$choice =~ s/\s+\z//;

qx{$fav{$choice}} if $choice ne "";
