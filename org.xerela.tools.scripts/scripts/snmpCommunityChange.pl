#!/usr/bin/perl
use strict;
use Getopt::Long;

use Xerela::Logger;
use Xerela::Typer;
use Xerela::Adapters::Invoker;

# Redirect warnings to the Logger so they don't pollute Tool output
my $LOGGER = Xerela::Logger::get_logger();
local $SIG{__WARN__} = sub {
	my $warning = shift;
	chomp $warning;
	$LOGGER->debug($warning);
};

my ( $connectionPathXml, $adapterId, $addCommunity, $addAccessType, $removeCommunity, $removeAccessType, );
GetOptions(
	"connectionPath=s"   => \$connectionPathXml,
	"adapterId=s"        => \$adapterId,
	"addCommunity:s"     => \$addCommunity,
	"addAccessType=s"    => \$addAccessType,
	"removeCommunity:s"  => \$removeCommunity,
	"removeAccessType=s" => \$removeAccessType,
);

my ($connectionPath) = Xerela::Typer::translate_document( $connectionPathXml, 'connectionPath' );
my $device           = $connectionPath->get_ip_address();
my $addCommunityXml  = '<addCommunity community="' . $addCommunity . '" accessType="'.$addAccessType.'"/>';
my $removeCommunityXml = '<removeCommunity community="' . $removeCommunity . '" accessType="'.$removeAccessType.'"/>';
my $operation          = 'snmpcommunitychange';
$connectionPathXml =~ s/(<\/\w+>)$/$addCommunityXml$removeCommunityXml$1/;

my $response;
eval { $response = Xerela::Adapters::Invoker::invoke( $adapterId, $operation, $connectionPathXml ); };
if ($@)
{
	if ( $@ =~ /Can't locate.+\.pm|Can't locate object method/i )
	{
		print "WARN,$device\n";
		print "\n";
		print "The \"$operation\" operation is not yet implemented for the $adapterId adapter\n";
		print "\n";
		print "Visit http://www.xerela.org/zde for information on how to extend the $adapterId adapter.";
	}
	else
	{
		print "ERROR,$device\n";
		print "\n";
		print "$@";
	}
}
else
{
	print "OK,$device\n\n$response";
}

__END__

=head1 DESCRIPTION

A script tool that is designed to add or remove an SNMP v1/v2c community string

=head1 ADAPTER IMPLEMENTATIONS

An adapter that wishing to use this tool must implement the snmpcommunitychange operation.  That operation
should return a single SCALAR upon completion that can be printed out to represent the details of the change.

Proper implementation of the snmpcommunitychange operation would be as follows inside of an Snmpcommunitychange.pm
for your adapter:

	sub invoke
	{
		my $pkg = shift;
		my $doc = shift;

		my ( $connectionPath, $addCommunity, $removeCommunity ) = Xerela::Typer::translate_document( $doc, 'connectionPath' );
		my $cliProtocol    = Xerela::CLIProtocolFactory::create($connectionPath);
		return $response;
	}
	
=head1 LICENSE

 The contents of this file are subject to the Mozilla Public License
 Version 1.1 (the "License"); you may not use this file except in
 compliance with the License. You may obtain a copy of the License at
 http://www.mozilla.org/MPL/

 Software distributed under the License is distributed on an "AS IS"
 basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 License for the specific language governing rights and limitations
 under the License.

=head1 AUTHOR

  Contributor(s): rkruse
  Date: May 15, 2008

=cut
