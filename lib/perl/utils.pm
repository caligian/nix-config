#!/usr/bin/env perl

package utils;

use v5.40;
use strict;
use warnings;

use Carp qw 'croak';
use Data::Dumper 'Dumper';
use Exporter 'import';
use File::Slurp 'slurp';
use JSON::PP       qw(decode_json encode_json);
use File::Path     qw(make_path remove_tree);
use Text::Wrap     qw(wrap $columns);
use File::Copy     qw(cp mv);
use Cwd            qw(realpath getcwd cwd);
use File::Basename qw(basename dirname);
use List::Util     qw(
  reduce any all none notall first reductions
  max maxstr min minstr product sum sum0
  pairs unpairs pairkeys pairvalues pairfirst pairgrep pairmap
  shuffle uniq uniqint uniqnum uniqstr head tail
);
use Scalar::Util qw(reftype blessed looks_like_number);
use Getopt::Long::Descriptive 'describe_options';

sub abspath       { return Cwd::abs_path(@_); }
sub pprint        { print Dumper( \@_ ); }
sub is_path       { defined $_[0] && -e $_[0] }
sub is_file       { defined $_[0] && -f $_[0] }
sub is_dir        { defined $_[0] && -d $_[0] }
sub is_link       { defined $_[0] && -l $_[0] }
sub is_readable   { defined $_[0] && -r $_[0] }
sub is_writable   { defined $_[0] && -w $_[0] }
sub is_executable { defined $_[0] && -x $_[0] }
sub is_owned      { defined $_[0] && -o $_[0] }
sub is_socket     { defined $_[0] && -S $_[0] }
sub is_pipe       { defined $_[0] && -p $_[0] }
sub is_blockdev   { defined $_[0] && -b $_[0] }
sub is_chardev    { defined $_[0] && -c $_[0] }
sub is_text       { defined $_[0] && -T $_[0] }
sub is_binary     { defined $_[0] && -B $_[0] }
sub mtime         { defined $_[0] ? -M $_[0] : undef }
sub atime         { defined $_[0] ? -A $_[0] : undef }
sub ctime         { defined $_[0] ? -C $_[0] : undef }
sub filesize      { defined $_[0] && -s $_[0] }
sub is_scalar     { !ref $_[0] }
sub is_number     { defined $_[0] && looks_like_number( $_[0] ) }
sub is_string     { defined $_[0] && !ref $_[0] && !looks_like_number( $_[0] ) }
sub is_undef      { !defined $_[0] }
sub is_ref        { ref $_[0] ? 1 : 0 }
sub println       { print @_, "\n"; }

sub is_arrayref {
    ref $_[0] eq 'ARRAY' || ( blessed( $_[0] ) && reftype( $_[0] ) eq 'ARRAY' );
}

sub is_hashref {
    ref $_[0] eq 'HASH' || ( blessed( $_[0] ) && reftype( $_[0] ) eq 'HASH' );
}

sub is_scalarref {
    ref $_[0] eq 'SCALAR'
      || ( blessed( $_[0] ) && reftype( $_[0] ) eq 'SCALAR' );
}

sub is_coderef {
    ref $_[0] eq 'CODE' || ( blessed( $_[0] ) && reftype( $_[0] ) eq 'CODE' );
}

sub is_globref {
    ref $_[0] eq 'GLOB' || ( blessed( $_[0] ) && reftype( $_[0] ) eq 'GLOB' );
}

sub is_regex {
    ref $_[0] eq 'Regexp'
      || ( blessed( $_[0] ) && reftype( $_[0] ) eq 'Regexp' );
}

sub is_boolean {
    defined $_[0] && ( $_[0] == 0 || $_[0] == 1 ) && !ref $_[0];
}

sub is_integer {
    defined $_[0] && looks_like_number( $_[0] ) && int( $_[0] ) == $_[0];
}

sub is_float {
    defined $_[0] && looks_like_number( $_[0] ) && int( $_[0] ) != $_[0];
}

sub is_nonempty_array {
    is_arrayref( $_[0] ) && @{ $_[0] } > 0;
}

sub is_nonempty_hash {
    is_hashref( $_[0] ) && keys %{ $_[0] } > 0;
}

sub get_terminal_width {
    return $ENV{COLUMNS} if $ENV{COLUMNS};

    my $width = `stty size 2>/dev/null`;
    if ( $width =~ /(\d+)$/ ) {
        return int $1;
    }
    return 72;
}

sub dief {
    my $msg  = shift;
    my @args = @_;
    die sprintf( "$msg", @args );
}

sub dieln {
    my $msg  = shift;
    my @args = @_;
    die sprintf( "$msg\n", @args );
}

sub die_unless {
    my $cond = shift;
    unless ($cond) {
        dieln @_;
    }
}

sub die_if {
    my $cond = shift;
    if ($cond) {
        dieln @_;
    }
}

sub throw {
    croak @_;
}

sub throwf {
    my $msg  = shift;
    my @args = @_;
    $msg = sprintf $msg, @args;
    throw $msg;
}

sub throwln {
    my $msg  = shift;
    my @args = @_;
    $msg = $msg . "\n";
    throw $msg, @args;
}

sub throw_if {
    my $cond = shift;
    if ($cond) {
        throwln @_;
    }
}

sub throw_unless {
    my $cond = shift;
    unless ($cond) {
        throwln @_;
    }
}

sub get_default {
    my $current    = shift;
    my $if_nothing = shift;
    my $map        = shift;

    unless ( defined $current ) {
        return $if_nothing->();
    }
    elsif ( defined $map ) {
        return $map->($current);
    }
    else {
        return $current;
    }
}

sub textwrap {
    my ( $text, $width ) = @_;
    $width //= get_terminal_width();
    local $Text::Wrap::columns = $width;
    return wrap '', '', $text;
}

sub ArgumentParser {
    if ( scalar(@_) == 0 ) {
        die
"Expected ArgumentParser(PROG => STRING, DESC=> STRING, <option> => spec, ...)\n";
    }

    my %options = @_;
    unless ( exists $options{PROG} ) {
        die "No program string provided\n";
    }
    unless ( exists $options{DESC} ) {
        die "No program description provided\n";
    }

    my $prog         = $options{PROG};
    my $desc         = $options{DESC};
    my $exit_on_help = $options{EXIT_ON_HELP};
    my @specs        = ( [ 'help|h' => 'Show this help message' ] );
    $desc = textwrap "Description: $desc\n";

    if ( $prog ne "" ) {
        $prog = "Usage: $0 %o $prog\n$desc";
    }
    else {
        $prog = "Usage: $0 %o\n$desc";
    }

    delete $options{PROG};
    delete $options{DESC};
    delete $options{EXIT_ON_HELP};

    while ( my ( $key, $value ) = each %options ) {
        push @specs, [ $key => $value ];
    }

    my ( $opt, $usage ) = describe_options( $prog, @specs );

    if ( $opt->help ) {
        if ( defined $exit_on_help && $exit_on_help ) {
            println $usage->text;
            exit 0;
        }
        else {
            return ( { help => $usage->text }, \@ARGV );
        }
    }
    else {
        return ( $opt, \@ARGV );
    }
}

sub spit {
    my ( $filename, $str, $add_nl ) = @_;
    open( my $fh, ">", $filename ) or return 0;
    print $fh $str;
    print $fh "\n" if $add_nl;
    close $fh;

    return 1;
}

sub make_dirs {
    foreach my $dir (@_) {
        make_path $dir;
    }
}

sub rm_dirs {
    foreach my $path (@_) {
        remove_tree $path, safe => 1;
    }
}

sub read_json {
    my $file    = shift;
    my $default = $_[0] // sub { return };

    return $default->() unless -f $file;
    return decode_json slurp($file);
}

sub write_json {
    my $file     = shift;
    my $obj      = shift;
    my %opts     = @_;
    my $dir      = dirname $file;
    my $makedirs = $opts{mkdir};

    make_dirs $dir if $makedirs;
    return spit $file, encode_json $obj;
}

sub seq_along {
    my $ref = $_[0];
    if ( is_hashref $ref ) {
        return ( 0 .. scalar %{$ref} );
    }
    elsif ( is_arrayref $ref ) {
        return ( 0 .. scalar @{$ref} );
    }
    else {
        die( "Expected arrayref | hashref, got " . ref($ref) );
    }
}

sub seq {
    my ( $start, $end, $step ) = @_;
    $step //= 1;
    my @res = ();

    for ( my $i = $start ; $i < $end ; $i += $step ) {
        push @res, $i;
    }

    return \@res;
}

sub sizeof {
    my $arg = shift;
    if ( is_string $arg ) {
        return length $arg;
    }
    elsif ( is_arrayref $arg ) {
        return scalar @{$arg};
    }
    elsif ( is_hashref $arg ) {
        return scalar %{$arg};
    }
    else {
        die "Expected arrayref | string | hashref, got " . ref($arg);
    }
}

sub get_items {
    my @found = ();
    my $hash  = shift;

    while ( my ( $key, $value ) = each %{$hash} ) {
        push @found, [ $key, $value ];
    }

    return \@found;
}

sub get_keys {
    my @ks = keys %{ $_[0] };
    return \@ks;
}

sub get_values {
    my @vs = values %{ $_[0] };
    return \@vs;
}

sub enumerate {
    my $arr   = shift;
    my @found = ();

    for ( my $i = 0 ; $i < scalar @{$arr} ; $i++ ) {
        push @found, [ $i, $arr->[$i] ];
    }

    return \@found;
}

sub is_container {
    my $tbl = shift;
    return ( is_hashref($tbl) || is_arrayref($tbl) );
}

sub is_sequence {
    my $tbl = shift;
    return ( is_string($tbl) || is_arrayref($tbl) );
}

sub assert_integer {
    my $obj = shift;
    unless ( looks_like_number $obj ) {
        dief "Expected integer, got [%s] %s", ref($obj), $obj;
    }
}

sub is_within_bounds {
    my ( $arr, $i ) = @_;
    assert_integer $i;

    my $len = sizeof $arr;
    $i = $i < 0 ? $len + $i : $i;

    return ( $i >= 0 ) && ( $i < $len );
}

sub assert_within_bounds {
    my ( $arr, $i ) = @_;
    unless ( is_within_bounds( $arr, $i ) ) {
        dieln "Index $i is out of bounds for array";
    }
}

sub has_key {
    my ( $tbl, $key ) = @_;
    if ( is_arrayref $tbl ) {
        return is_within_bounds $tbl, $key;
    }
    else {
        return exists $tbl->{$key};
    }
}

sub can_use_key {
    my ( $tbl, $key ) = @_;
    if ( is_arrayref $tbl ) {
        return looks_like_number($key);
    }
    elsif ( is_hashref $tbl ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub assert_is_container {
    my $tbl = shift;
    unless ( is_container $tbl ) {
        dief "Expected arrayref | hashref, got [%s] %s", ref($tbl), $tbl;
    }
}

sub get {
    my ( $tbl, $key ) = @_;
    assert_is_container $tbl;

    if ( is_hashref($tbl) ) {
        return exists $tbl->{$key} ? ( 1, $tbl->{$key} ) : ( 0, undef );
    }
    elsif ( !looks_like_number($key) ) {
        return ( 0, undef );
    }
    elsif ( !is_within_bounds( $tbl, $key ) ) {
        return ( 0, undef );
    }
    else {
        return ( 1, $tbl->[$key] );
    }
}

sub set {
    my ( $tbl, $key, $value ) = @_;
    if ( is_hashref $tbl ) {
        $tbl->{$key} = $value;
        return 1;
    }
    elsif ( !is_within_bounds( $tbl, $key ) ) {
        return 0;
    }
    else {
        $tbl->[$key] = $value;
        return 1;
    }
}

sub is_callable {
    return is_coderef $_[0];
}

sub assert_is_callable {
    unless ( is_callable $_[0] ) {
        my $arg = shift;
        dief "Expected function, got [%s] %s", ref($arg), $arg;
    }
}

sub get_in {
    my ( $tbl, $ks, %opts ) = @_;
    my @ks      = @{$ks};
    my $default = $opts{default};
    my $force   = $opts{force};
    $default //= sub { return };
    $force = $force == 1 ? sub { return {} } : $force;

    if ( defined $force ) {
        assert_is_callable $force;
    }

    if ( defined $default ) {
        assert_is_callable $default;
    }

    if ( scalar(@ks) == 0 ) {
        return ( 0, $default->() );
    }

    my $last_key = pop @ks;
    my $found    = $tbl;
    my $ensure   = sub {
        my ($k) = @_;
        my $value = $force->();
        return ( set( $found, $k, $value ), $value );
    };

    foreach my $k (@ks) {
        my ( $ok, $value ) = get $found, $k;

        unless ($ok) {
            if ( defined $force ) {
                my ( $okay, $result ) = $ensure->($k);
                unless ($okay) {
                    return ( 0, $found );
                }
                else {
                    $found = $result;
                }
            }
            else {
                return ( 0, $default->() );
            }
        }
        elsif ( !is_container($value) ) {
            if ( defined $force ) {
                my ( $okay, $result ) = $ensure->($k);
                unless ($okay) {
                    return ( 0, $found );
                }
                else {
                    $found = $result;
                }
            }
            else {
                return ( 0, $default->() );
            }
        }
        else {
            $found = $value;
        }
    }

    my ( $ok, $value ) = get $found, $last_key;
    unless ($ok) {
        return ( 0, $default->() );
    }
    else {
        return ( 1, $value );
    }
}

sub set_in {
    my ( $tbl, $ks, $value, %opts ) = @_;
    my $force = $opts{force};
    my @ks    = @{$ks};

    if ( defined $force ) {
        $force = $force == 1 ? sub { return {} } : $force;
        assert_is_callable $force;
    }

    unless ( scalar @ks ) {
        return ( 0, $tbl );
    }

    my $last_key = pop @ks;
    unless ( scalar @ks ) {
        my $ok = set $tbl, $last_key, $value;
        return ( $ok, $tbl );
    }

    my $found = $tbl;
    foreach my $k (@ks) {
        my ( $ok, $v ) = get $found, $k;

        unless ($ok) {
            if ($force) {
                my $x  = $force->();
                my $ok = set $found, $k, $x;
                unless ($ok) {
                    return ( 0, $found );
                }
                else {
                    $found = $x;
                }
            }
            else {
                return ( 0, $found );
            }
        }
        elsif ( is_container $v ) {
            $found = $v;
        }
        else {
            return ( 0, $found );
        }
    }

    return ( set( $found, $last_key, $value ), $found );
}

sub contains {
    my ( $tbl, $ks ) = @_;
    my @ks       = @{$ks};
    my $last_key = pop @ks;

    unless ( defined $last_key ) {
        return 0;
    }
    elsif ( scalar(@ks) == 0 ) {
        if ( is_arrayref $tbl ) {
            return is_within_bounds( $tbl, $last_key );
        }
        else {
            return exists $tbl->{$last_key};
        }
    }

    foreach my $k (@ks) {
        my ( $ok, $value ) = get $tbl, $k;
        unless ($ok) {
            return 0;
        }
        elsif ( !is_container($value) ) {
            return 0;
        }
        else {
            $tbl = $value;
        }
    }

    if ( is_arrayref $tbl ) {
        my ( $ok, $_value ) = get $tbl, $last_key;
        return $ok;
    }
    else {
        return exists $tbl->{$last_key};
    }
}

# Collect exports
our @EXPORT = (
    @Cwd::EXPORT,
    qw(
      spit slurp
      decode_json encode_json write_json read_json
      reduce any all none notall first reductions
      max maxstr min minstr product sum sum0
      pairs unpairs pairkeys pairvalues pairfirst pairgrep pairmap
      shuffle uniq uniqint uniqnum uniqstr head tail
      abspath dirname basename realpath
      pprint println Dumper
      is_path is_file is_dir is_link
      is_readable is_writable is_executable is_owned
      is_socket is_pipe is_blockdev is_chardev
      is_text is_binary
      cp mv
      mtime atime ctime filesize
      is_scalar is_number is_string is_undef is_ref
      is_arrayref is_hashref is_scalarref is_coderef is_globref is_regex
      is_boolean is_integer is_float
      is_nonempty_array is_nonempty_hash
      get_keys get_values get_items enumerate seq seq_along
      dief dieln die_if die_unless
      throwf throwln throw_if throw_unless
      get set get_in set_in contains
      textwrap
      ArgumentParser
    ),
);

1;
