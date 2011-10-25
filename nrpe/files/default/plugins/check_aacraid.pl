#!/usr/bin/perl
#
#
# nrpe-script for monitoring icp or adaptec raid controller
#
# -- depends on adaptecs arcconf --
#
# initial version: 22 september 2008 by martin probst <maddin(at)megamaddin(dot)de>
# current status: $Revision: 6 $
#
# Copyright Notice: GPL
#
# add these lines to /etc/sudoers:
#
#       nagios  ALL = NOPASSWD: /usr/StorMan/arcconf
#
#

use strict;
use warnings;
use Data::Dumper;

## nagios exit codes
use constant STATE_OK => 0;
use constant STATE_WARNING => 1;
use constant STATE_CRITICAL => 2;
use constant STATE_UNKNOWN => 3;
use constant STATE_DEPENDENT => 4;

## if we're dying unexpectely, we'll send status unknown
$SIG{KILL} = $SIG{TERM} = sub{ exit( STATE_UNKNOWN ); };

## path to executables
my $arcconf = "/usr/StorMan/arcconf";
my $sudo = "/usr/bin/sudo";

## change to dir $wd before executing, because arcconf
## throws logfiles in this directory where it's executed
my $wd = "/tmp";

## some vars for the devices
my $ctrl = 0;
my $logDrives = 0;
my $phyDrives = 0;
my %devices;

## the states which are allowed
my $allowedStates = "Optimal Online Hot Present Normal Charging";

## prints the multi-dimensional-hash for debuging via Data::Dumper if $debug is true
my $debug = 0;


unless( -e $arcconf && -x $sudo)
{
        Exit( "arcconf binary or sudo binary not found or not executable!<br>", STATE_UNKNOWN );
}

chdir( $wd );

$ctrl = getCtrl();

if( $ctrl == 0 )
{
        Exit( "no controller found!<br>", STATE_UNKNOWN );
}

getDev();

print Dumper(%devices) if $debug;

getInfo();

print Dumper(%devices) if $debug;

my ( $text, $state ) = checkStates();

( $text eq '' ) ? Exit( "cant get some informations about the controller/s<br>", STATE_UNKNOWN ) : Exit( $text, $state );

sub checkStates
{
        my $text = "";
        my $status = STATE_UNKNOWN;
        foreach my $controller( keys( %devices ) )
        {
                unless( $allowedStates =~ m/$devices{$controller}{"STATUS"}/ )
                {
                        $text .= "status of controller $controller is not optimal!<br>";
                        $status = STATE_CRITICAL;
                }
                unless(  $allowedStates =~ m/$devices{$controller}{"BATTERY"}/ )
                {
                    $text .= "battery status of controller $controller not optimal!<br>";
                    $status = STATE_WARNING;
                }
                unless(  $devices{$controller}{"TEMP"} =~ m/Normal/ )
                {
                    $text .= "temperature of controller $controller not normal: $devices{$controller}{'TEMP'}!<br>";
                    $status = STATE_WARNING;
                }
                foreach my $logicDrive( keys( %{$devices{$controller}{"LD"}} ) )
                {
                    unless( $allowedStates =~ m/$devices{$controller}{"LD"}{$logicDrive}{"STATUS"}/ )
                    {
                        $text .= "status of logical device $logicDrive on controller $controller is not optimal!<br>";
                        $status = STATE_CRITICAL;
                    }
                    unless( $devices{$controller}{"LD"}{$logicDrive}{"FAILED_STRIPES"} eq "No" )
                    {
                        $text .= "there are some failed stripes on logical device $logicDrive on controller $controller!<br>";
                        $status = STATE_WARNING;
                    }
                    foreach my $group( keys( %{$devices{$controller}{"LD"}{$logicDrive}{"GROUP"}} ) )
                    {
                        foreach my $segment( keys( %{$devices{$controller}{"LD"}{$logicDrive}{"GROUP"}{$group}{"SEGMENT"}} ) )
                        {
                            unless(  $allowedStates =~ m/$devices{$controller}{"LD"}{$logicDrive}{"GROUP"}{$group}{"SEGMENT"}{$segment}{"PRESENT"}/ )
                            {
                                $text .= "segment $segment on group $group in logical device $logicDrive on controller $controller is not present!<br>";
                                $status = STATE_CRITICAL;
                            }
                        }
                    }
                }
                foreach my $physDrive( keys( %{$devices{$controller}{"PD"}} ) )
                {
                    unless(  $allowedStates =~ m/$devices{$controller}{"PD"}{$physDrive}{"STATUS"}/ )
                    {
                        $text .= "physical device $physDrive on controller $controller is not online!<br>";
                        $status = STATE_CRITICAL;
                    }
                }
        }
        if( $text eq '' && $status == STATE_UNKNOWN )
        {
                return( "controller status seems fine", STATE_OK )
        }
        return( $text, $status );

}

sub getInfo
{
        my @dev = ();
        foreach my $controller( 1..$ctrl )
        {
                foreach my $logicDrive( 0..$devices{$controller}{"LDS"} )
            {
                @dev = `$sudo $arcconf GETCONFIG $controller LD $logicDrive`;
                foreach my $singleLogicDrive( @dev )
                {
                    if( $singleLogicDrive =~ m/RAID\slevel\s+:\s(\d+)\s+/ )
                    {
                        $devices{$controller}{"LD"}{$logicDrive}{"RAID_LEVEL"} = $1;
                    }
                    if( $singleLogicDrive =~ m/Status\sof\slogical\sdevice\s+:\s(\w+)\s+/ )
                    {
                        $devices{$controller}{"LD"}{$logicDrive}{"STATUS"} = $1;
                    }
                    if( $singleLogicDrive =~ m/Failed\sstripes\s+:\s(\w+)\s+/ )
                    {
                        $devices{$controller}{"LD"}{$logicDrive}{"FAILED_STRIPES"} = $1;
                    }
                    if( $singleLogicDrive =~ m/Segment\s(\d+)\s+:\s(\w+).*/ )
                    {
                        if( $singleLogicDrive =~ m/Group\s(\d+),\sSegment\s(\d+)\s+:\s(\w+).*/i )
                        {
                            $devices{$controller}{"LD"}{$logicDrive}{"GROUP"}{$1}{"SEGMENT"}{$2}{"PRESENT"} = $3;
                        }
                        else
                        {
                            $devices{$controller}{"LD"}{$logicDrive}{"GROUP"}{0}{"SEGMENT"}{$1}{"PRESENT"} = $2;
                        }
                    }
                }
            }

            @dev = `$sudo $arcconf GETCONFIG $controller PD`;
            my $num = 0;
            foreach my $physDrive( @dev )
            {
                if( $physDrive =~ m/Device\s#(\d+)\s+/ )
                {
                    $num = $1;
                }
                if( $physDrive =~ m/State\s+:\s(\w+)\s+/ )
                {
                    $devices{$controller}{"PD"}{$num}{"STATUS"} = $1;
                }

            }

            @dev = `$sudo $arcconf GETCONFIG $controller AD`;
            foreach my $ctrlDrive( @dev )
            {
                if( $ctrlDrive =~ m/Controller\sStatus\s+:\s(\w+)\s+/ )
                {
                    $devices{$controller}{'STATUS'} = $1;
                }
                if( $ctrlDrive =~ m/Temperature\s+:\s(\d+).*\((\w+)\)/ )
                {
                    $devices{$controller}{'TEMP'} = "$1C/$2";
                }
                if( $ctrlDrive =~ m/Status\s+:\s(\w+)\s+/ )
                {
                    $devices{$controller}{'BATTERY'} = $1;
                }
            }
        }
}

sub getDev
{
        my @dev = ();
        foreach my $controller( 1..$ctrl )
        {
                $devices{$controller}{"LDS"} = -1;
                $devices{$controller}{"STATUS"} = "NULL";
                $devices{$controller}{"TEMP"} = "NULL";
                $devices{$controller}{"BATTERY"} = "NULL";

                @dev = `$sudo $arcconf GETCONFIG $controller LD`;
                foreach my $logicDrive( @dev )
                {
                        if( $logicDrive =~ m/Logical\sdevice\snumber\s(\d+)\s+/ )
                        {
                                $devices{$controller}{"LDS"}++;
                                $devices{$controller}{"LD"}{$1}{"STATUS"} = "NULL";
                                $devices{$controller}{"LD"}{$1}{"FAILED_STRIPES"} = "NULL";
                                $devices{$controller}{"LD"}{$1}{"RAID_LEVEL"} = -1;
                        }
                }

                @dev = `$sudo $arcconf GETCONFIG $controller PD`;
                foreach my $physDrive( @dev )
                {
                    if( $physDrive =~ m/Device\s#(\d+)\s+/ )
                    {
                        $devices{$controller}{"PD"}{$1}{"STATUS"} = "Online";
                    }
                }
        }
}

sub getCtrl
{
        my $num = 0;
        foreach( `$sudo $arcconf GETVERSION` )
        {
                $_ =~ m/^Controllers\sfound:\s+(\d)$/;
                $num = $1;
        }
        return( $num );
}


sub Exit
{
        my $string = shift;
        my $state = shift;
        print $string;
        exit( $state );
}
