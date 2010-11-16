package Xerela::Adapters::Extreme::XOS::NameServer;

use strict;
use warnings;

use Xerela::Adapters::Extreme::XOS::AutoLogin;
use Xerela::CLIProtocolFactory;
use Xerela::Logger;
use Xerela::Typer;

my $LOGGER = Xerela::Logger::get_logger();

sub invoke
{
	my $pkg            = shift;
	my $syslogDocument = shift;

	# Initial connection
	my ( $connectionPath, $nsAddress, $nsAction, $domainSuffixName ) = Xerela::Typer::translate_document( $syslogDocument, 'connectionPath' );

	my $cliProtocol = Xerela::CLIProtocolFactory::create($connectionPath);
	my $promptRegex = Xerela::Adapters::Extreme::XOS::AutoLogin::execute( $cliProtocol, $connectionPath );

	my $response = $cliProtocol->send_and_wait_for( 'disable clipaging', $promptRegex );
	$cliProtocol->set_more_prompt( 'Press <SPACE> to continue or <Q> to quit:', '20');
	$promptRegex =~ s/^\\\*\\\s+//;

	my $configRegex = '\*\s+'.$promptRegex;

	if ( $nsAddress =~ /^[\da-f\:\.]+$/i )
	{
		if ( $nsAction eq 'add' )
		{
			$response .= $cliProtocol->send_and_wait_for( "configure dns-client add name-server $nsAddress", $configRegex );
		}
		elsif ( $nsAction eq 'delete' )
		{
			$response .= $cliProtocol->send_and_wait_for( "configure dns-client delete name-server $nsAddress", $configRegex );
		}
	}
	if ( $domainSuffixName =~ /^[\da-z\.\-]+$/i )
	{
		$response .= $cliProtocol->send_and_wait_for( "configure dns-client add domain-suffix $domainSuffixName", $configRegex );
	}
	$response .= $cliProtocol->send_and_wait_for( 'save', 'overwrite it\?' );
	$response .= $cliProtocol->send_and_wait_for( 'yes', $promptRegex );

	_disconnect($cliProtocol);

	return $response;
}

sub _disconnect
{
	# Grab the Xerela::CLIProtocol object passed in
	my $cli_protocol = shift;

	# Close this session and exit
	$cli_protocol->send("exit");
}

1;
