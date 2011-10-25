#
# Common stuff for Nagios plugins
#

package Nagios::Plugin;

use strict;
require Exporter;
use File::Basename;
use Config::Tiny;
use Carp;
use Getopt::Long;
Getopt::Long::Configure('bundling');

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $PLUGIN $TIMEOUT $VERBOSE $VERSION);

@ISA = qw(Exporter);
@EXPORT = qw($PLUGIN $TIMEOUT $VERBOSE parse_args nagios_exit exit_results);
@EXPORT_OK = qw(load_config);
%EXPORT_TAGS = (
  std => [ @EXPORT ],
  all => [ @EXPORT, @EXPORT_OK ],
);

$TIMEOUT = 15;

BEGIN {
  my ($pkg, $filename) = caller(2);
  # basename $0 works fine for deriving plugin name except under ePN
  if ($filename && $filename !~ m/EVAL/i) {
    $PLUGIN = basename $filename;
  } else {
    # Nasty hack - under ePN, try and derive the plugin name from the pkg name
    $PLUGIN = lc $pkg;
    $PLUGIN =~ s/^.*:://;
    $PLUGIN =~ s/_5F/_/gi;
  }
}

my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

# Nagios::Plugin version (not _plugin_ version)
$VERSION = 0.04;

# ------------------------------------------------------------------------
# Private subroutines

sub print_revision 
{
  my ($version) = @_;
  print "$PLUGIN $version";
}

sub print_help {
  my ($version, $usage, $help, $licence, $blurb, $help_extra) = @_;
  print_revision($version);
  print "$licence\n";
  print "$blurb\n" if $blurb;
  print "$usage\n";
  print $help;
  print $help_extra if $help_extra;
}

# ------------------------------------------------------------------------
# Public subroutines

# load_config('section')
sub load_config {
  my ($section) = @_;
  $section ||= $PLUGIN;
  my $config_file = '/etc/nagios/plugins.cfg';
  return {} unless -f $config_file;
  my $ct = Config::Tiny->read($config_file);
  return { %{$ct->{$section} || {}} } if ref $ct;
  return {};
}

# nagios_exit("CODE", "error string")
sub nagios_exit 
{
  my $code = shift;
  my $errstr = join ', ', @_;
  $code ||= "UNKNOWN";
  die "invalid code '$code'" unless exists $ERRORS{$code};
  if ($errstr && $errstr ne '1') {
    $errstr .= "\n" unless substr($errstr,-1) eq "\n";
    my $short_name = uc $PLUGIN;
    $short_name =~ s/^check_//i;
    print "$short_name $code - $errstr";
  }
  exit $ERRORS{$code};
}

# parse_args(version => $v, usage => $u, spec => \@s)
sub parse_args
{
  my %arg = @_;

  foreach (qw(usage version spec)) {
    croak "missing required argument '$_'" unless exists $arg{$_};
  }

  my $usage = sprintf $arg{usage}, $PLUGIN;
  $usage .= "\n" if substr($usage,-1) ne "\n";
  my $version = $arg{version};
  $version .= "\n" if substr($version,-1) ne "\n";
  my $spec = $arg{spec};
  my $blurb = $arg{blurb} || '';
  $blurb .= "\n" if $blurb && substr($blurb,-1) ne "\n";
  my $licence = $arg{licence} || $arg{license} || qq(
This nagios plugin is free software, and comes with ABSOLUTELY NO WARRANTY. 
It may be used, redistributed and/or modified under the terms of the GNU 
General Public Licence (see http://www.fsf.org/licensing/licenses/gpl.txt).
);
  $licence .= "\n" if $licence && substr($licence,-1) ne "\n";
  my $help_extra = $arg{help_extra};
  $help_extra .= "\n" if $help_extra && substr($help_extra,-1) ne "\n";
  croak "invalid spec argument - not array ref" unless ref $spec eq 'ARRAY';
  croak "odd number of spec elements" unless int(scalar @$spec % 2) == 0;

  # Build up options and help text from spec array
  my ($show_usage, $show_help, $show_version, @verbose);
  my @opt = (
    "usage|?"             => \$show_usage,
    "help|h"              => \$show_help,
    "version|V"           => \$show_version,
    "timeout|t=i"         => \$TIMEOUT, 
    "verbose|v"           => \@verbose,
  );
  my $help_tmpl = qq(Options:
 -h, --help
   Print detailed help screen
 -V, --version
   Print version information
%s
 -t, --timeout=INTEGER
   Seconds before plugin times out (default: $TIMEOUT)
 -v, --verbose
   Show details for command-line debugging 
);
  my $help = '';
  my @req = ();
  while (@$spec) {
    my $opt = shift @$spec;
    my $elt = shift @$spec;
    croak "spec element for option '$opt' is not array ref"
      unless ref $elt eq 'ARRAY';
    my ($var, $help_text, $req) = @$elt;
    push @opt, $opt, $var;
    $help_text = " $help_text" unless substr($help_text,0,1) eq ' ';
    $help_text .= "\n" unless substr($help_text,-1) eq "\n";
    $help .= $help_text;
    push @req, $var if $req;
  }
  chomp $help;
  $help = sprintf $help_tmpl, $help;

  my $result = GetOptions(@opt) || print($usage) && exit;

  # Handle standard options
  nagios_exit("UNKNOWN", print_revision($version)) if $show_version;
  nagios_exit("UNKNOWN", print($usage)) if $show_usage;
  nagios_exit("UNKNOWN", print_help($version,$usage,$help,$licence,$blurb,$help_extra)) 
    if $show_help;

  # Check required arguments
  for (@req) {
    if (ref $_ eq 'SCALAR') {
      &nagios_exit("UNKNOWN", print($usage)) unless defined $$_;
    } elsif (ref $_ eq 'ARRAY') {
      &nagios_exit("UNKNOWN", print($usage)) unless @$_;
    } else {
      die "invalid required reference '$_' - expected scalar ref or array ref only";
    }
  }

  # Setup alarm handler (will handle any alarm($TIMEOUT) for plugin)
  $SIG{ALRM} = sub {
    &nagios_exit("UNKNOWN", "no response from $PLUGIN (timeout, ${TIMEOUT}s)");
  };

  $VERBOSE = scalar(@verbose);
}

# exit_results(%arg) 
#   returns CRITICAL if @{$arg{CRITICAL}}, WARNING if @{$arg{WARNING}}, else OK
#   uses $arg{results} for message if defined, else @{$arg{<STATUS>}}, 
#     where <STATUS> is the return code above
sub exit_results
{
  my (%arg) = @_;
  
  my %keys = map { $_ => 1 } qw(CRITICAL WARNING OK results);
  for (sort keys %arg) {
    croak "[Nagios::Plugin::exit_results] invalid argument $_" unless $keys{$_};
  }

  my $results = '';
  my $delim = ' : ';
  if ($arg{results}) {
    $results = ref $arg{results} eq 'ARRAY' ? 
      join($delim, @{$arg{results}}) : 
      $arg{results};
  }

  if ($arg{CRITICAL} && (ref $arg{CRITICAL} ne 'ARRAY' || @{$arg{CRITICAL}})) {
    &nagios_exit("CRITICAL", $results) if $results;
    &nagios_exit("CRITICAL", join($delim, @{$arg{CRITICAL}})) 
      if $arg{CRITICAL} && ref $arg{CRITICAL} eq 'ARRAY' && @{$arg{CRITICAL}};
    &nagios_exit("CRITICAL", $arg{CRITICAL}) if $arg{CRITICAL};
  }

  elsif ($arg{WARNING} && (ref $arg{WARNING} ne 'ARRAY' || @{$arg{WARNING}})) {
    &nagios_exit("WARNING", $results) if $results;
    &nagios_exit("WARNING", join($delim, @{$arg{WARNING}})) 
      if $arg{WARNING} && ref $arg{WARNING} eq 'ARRAY' && @{$arg{WARNING}};
    &nagios_exit("WARNING", $arg{WARNING}) if $arg{WARNING};
  }

  &nagios_exit("OK", $results) if $results;
  &nagios_exit("OK", join($delim, @{$arg{OK}})) 
    if $arg{OK} && ref $arg{OK} eq 'ARRAY' && @{$arg{OK}};
  &nagios_exit("OK", $arg{OK}) if $arg{OK};
  &nagios_exit("OK", "All okay");
}

# ------------------------------------------------------------------------

1;

__END__

=head1 NAME

Nagios::Plugin - Perl module for creating nagios plugins

=head1 SYNOPSIS

    # Nagios::Plugin exports $PLUGIN, $TIMEOUT, and $VERBOSE variables,
    #   and three subroutines by default: parse_args(), nagios_exit(), 
    #   and exit_results(). load_config() can also be imported explicitly.
    use Nagios::Plugin;
    use Nagios::Plugin qw(:std load_config);

    # parse_args - parse @ARGV for std args and args in @spec
    parse_args(
      version => 0.01,
      usage => 'usage: %s -w <warn> -c <crit>',
      spec => \@spec,
    );

    # nagios_exit($code, $msg) 
    #   where $code is qw(OK WARNING CRITICAL UNKNOWN DEPENDENT)
    nagios_exit("CRITICAL", "You're ugly and your mother dresses you funny");

    # exit_results - exit based on the given arrays
    exit_results(
      CRITICAL => \@crit,
      WARNING  => \@warn,
      OK       => $ok_message,
    );

    # load_config - load $section section of plugins.cfg config file
    #   If not set, $section default to plugin name.
    $config = load_config();
    $config = load_config($section);


=head1 DESCRIPTION

Nagios::Plugin is a perl module for simplifying the creation of 
nagios plugins, mainly by standardising some of the argument parsing
and handling stuff most plugins require.

Nagios::Plugin exports the following variables:

=over 4

=item $PLUGIN 

The name of the plugin i.e. basename($0).
  
=item $TIMEOUT 

The number of seconds before the plugin times out, set via the -t argument.

=item $VERBOSE 

The number of -v arguments to the plugin.
    
=back

Nagios::Plugin also exports three subroutines by default: parse_args(), 
for parsing @ARGV for std and supplied args; nagios_exit(), for returning 
a standard Nagios return status plus a message; and exit_results(), for 
checking a set of message arrays and exiting appropriately. The following 
subroutines can also be imported explicitly: load_config(), for loading
a set of config settings from the plugins.cfg config file.

=head2 parse_args

The parse_args subroutine provides the core Nagios::Plugin functionality, 
and should be called early in your plugin. It uses a named argument
syntax, and currently takes three arguments: the version number ('version'); 
a short usage message ('usage', newlines okay, %s will be substituted with 
$PLUGIN); and an argument spec for any additional arguments your plugin 
will accept.

Nagios::Plugin provides standard argument handling for the following 
arguments:

=over 4

=item --usage | -?

Print a short usage message for the plugin.

=item --help | -h

Print a longer help message, include the version number, the usage
message, and help text for the individual arguments.

=item --version | -V

Print the plugin version number and licence information (currently
hardcoded).

=item --timeout | -t

Number of seconds for plugin timeout (if the plugin implements one);
default: 15.

=item --verbose | -v

Turn on verbose debug output (may be repeated - the exported $VERBOSE 
variable is set to the number of -v arguments parsed).

=back

To define additional arguments for your plugin, you fill out an
argument specifier, which is just an arrayref of argument definitions.
Each definition is basically an extended Getopt::Long definition - 
instead of the two-item tuple $option_defn => $variable used in
Getopt::Long, Nagios::Plugin uses a three- or four-item tuple which 
also includes help text for argument, and optionally an additional
mandatoriness flag - the syntax used is:

  $option_defn => [ $variable, $help_text, $required_flag ]

e.g.

  parse_args(
    version => 0.01,
    usage => 'usage: %s -w <warn> -c <crit>',
    spec => [
      "warning|w=s" => [
        \$warning, 
        q(-w, --warning=INTEGER\n   Exit with WARNING status if less than INTEGER foobars are free),
        'REQUIRED',
      ],
      "critical|c=s" => [
        \$critical, 
        q(-c, --critical=INTEGER\n   Exit with CRITICAL status if less than INTEGER foobars are free),
        'REQUIRED',
      ],
    ],
  );


=head2 nagios_exit

Convenience function, to exit with the given nagios status code 
and message:

  nagios_exit(OK => 'query successful');
  nagios_exit("CRITICAL", "You're ugly and your mother dresses you funny");

Valid status codes are "OK", "WARNING", "CRITICAL", "UNKNOWN".


=head2 exit_results

exit_results exits from the plugin after examining a supplied set of 
arrays. Syntax is:

  exit_results(
    CRITICAL => \@crit,
    WARNING  => \@warn,
    OK       => $ok_message,    # or \@ok_messages
  );

exit_results returns 'CRITICAL' if the @crit array is non-empty;
'WARNING' if the @warn array is non-empty; and otherwise 'OK'. The
text returned is typically the joined contents of @crit or @warn or
@ok_messages (or $ok_message).

Sometimes on error or warning you want to return more than just the 
error cases in the returned text. You can do this by passing a
'results' parameter containing the string or strings you want to use
for all status codes e.g.

  # Use the given $results string on CRITICAL, WARNING, and OK
  exit_results(
    CRITICAL => \@crit,
    WARNING  => \@warn,
    results => $results         # or \@results
  );


=head2 load_config

Load a hashref of config variables from the given section of the 
plugins.cfg config file. Section defaults to plugin name.
e.g.

  $config = load_config();
  $config = load_config('prod_db');



=head1 CHANGES

Versions prior to 0.03 overrode the standard exit() function instead
of using a separate nagios_exit. This breaks under ePN with Nagios 2.0,
so the change to nagios_exit was made. Thanks to Håkon Løvdal for the
problem report.

The auto-exported $CONFIG variable was removed in 0.04, replaced with
the load_config function, again due to problems running under ePN.


=head1 AUTHOR

Gavin Carr <gavin@openfusion.com.au>


=head1 LICENCE

Copyright 2005-2006 Gavin Carr. All Rights Reserved.

This module is free software. It may be used, redistributed
and/or modified under either the terms of the Perl Artistic 
License (see http://www.perl.com/perl/misc/Artistic.html)
or the GNU General Public Licence (see 
http://www.fsf.org/licensing/licenses/gpl.txt).

=cut

# arch-tag: 1495e893-2a66-4e61-a8eb-8bfa401b2a4f
# vim:ft=perl:ai:sw=2
