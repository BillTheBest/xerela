package Xerela::Adapters::Cisco::SecurityAppliance::AddStaticRoute;

use strict;
use warnings;

use Xerela::Adapters::Cisco::SecurityAppliance::AutoLogin;
use Xerela::Adapters::Cisco::SecurityAppliance::Disconnect qw(disconnect);
use Xerela::CLIProtocolFactory;
use Xerela::Logger;
use Xerela::Typer;

my $LOGGER = Xerela::Logger::get_logger();

sub invoke
{
	my $pkg            = shift;
	my $syslogDocument = shift;

	# Initial connection
	my ( $connectionPath, $destAddress, $destMask, $gwAddress ) = Xerela::Typer::translate_document( $syslogDocument, 'connectionPath' );

	my $cliProtocol = Xerela::CLIProtocolFactory::create($connectionPath);
	my $promptRegex = Xerela::Adapters::Cisco::SecurityAppliance::AutoLogin::execute( $cliProtocol, $connectionPath );
	$cliProtocol->send_and_wait_for( 'term pager 0', $promptRegex );
	my $configPrompt = '#\s*$';
	my $response = $cliProtocol->send_and_wait_for( 'config term', $configPrompt );

	my $ifs		= $cliProtocol->send_and_wait_for( "show interface", $configPrompt );
	$response	.= $ifs;
	if ( $destAddress =~ /^\S+$/i && $destMask =~ /^\S+$/i && $gwAddress =~ /^\S+$/i )
	{
		while ( $ifs =~ /^Interface\s+\S+\s+"([^\s"]+)"\,\s+is\s+up\,\s+line\s+protocol\s+is\s+up/mig )
		{
			my $ifName = $1;
			$response .= $cliProtocol->send_and_wait_for( "route $ifName $destAddress $destMask $gwAddress", $configPrompt );
		}
	}
	$response .= $cliProtocol->send_and_wait_for( 'end', $promptRegex );
	$response .= $cliProtocol->send_and_wait_for( 'write mem', $promptRegex );

	disconnect($cliProtocol);

	return $response;
}

1;
