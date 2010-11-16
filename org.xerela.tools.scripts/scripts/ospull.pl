#!/usr/bin/perl
use strict;

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

my ( $operationInputXml, $adapterId, $filestorePath ) = @ARGV;
my ($connectionPath) = Xerela::Typer::translate_document( $operationInputXml, 'connectionPath' );
my $device           = $connectionPath->get_ip_address();
my $start            = time();
my $operation 		 = 'ospull';
my $filestoreXml     = '<filestoreRoot path="' . $filestorePath . '"/>';
$operationInputXml =~ s/(<\/\w+>)$/$filestoreXml$1/;    # inject the filestore into the operation input XML

eval { Xerela::Adapters::Invoker::invoke( $adapterId, $operation, $operationInputXml ); };
my $secondsLapsed = time() - $start;
if ($@)
{
	if ( $@ =~ /Can't locate.+\.pm|Can't locate object method/i )
	{
		print "WARN,$device,$secondsLapsed\n";
		print "\n";
		print "The \"$operation\" operation is not yet implemented for the $adapterId adapter\n";
		print "\n";
		print "Visit http://www.xerela.org/zde for information on how to extend the $adapterId adapter.";
	}
	else
	{
		print "ERROR,$device,$secondsLapsed\n";
		print "\n";
		print "$@";
	}
}
else
{
	print "OK,$device,$secondsLapsed\n";
}
