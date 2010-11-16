package Xerela::Adapters::F5::BigIP::NameServer;

use strict;
use warnings;

use Xerela::Adapters::F5::BigIP::AutoLogin;
use Xerela::Adapters::F5::BigIP::Disconnect qw(disconnect);
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
	my $promptRegex = Xerela::Adapters::F5::BigIP::AutoLogin::execute( $cliProtocol, $connectionPath );
	my $response;

	if ( $nsAddress =~ /^[\da-f\:\.]+$/i )
	{
		if ( $nsAction eq 'add' )
		{
			$response .= $cliProtocol->send_and_wait_for( "echo nameserver $nsAddress >> /etc/resolv.conf", $promptRegex );
		}
		elsif ( $nsAction eq 'delete' )
		{	
			$_ = $cliProtocol->send_and_wait_for( "cat /etc/resolv.conf", $promptRegex );
			$response .= $_;
			$response .= $cliProtocol->send_and_wait_for( "rm -rf /etc/resolv.conf", $promptRegex );
			$response .= $cliProtocol->send_and_wait_for( "touch /etc/resolv.conf", $promptRegex );
			while ( /nameserver\s+(\S+)/ )
			{
				if ( $1 ne $nsAddress )
				{
					$response .= $cliProtocol->send_and_wait_for( "echo nameserver $1 >> /etc/resolv.conf", $promptRegex );
				}
			}
		}
	}
	if ( $domainSuffixName =~ /^[\da-z\.\-]+$/i )
	{
		$response .= $cliProtocol->send_and_wait_for( "hostname $domainSuffixName", $promptRegex );
	}
	disconnect($cliProtocol);
	return $response;
}

1;
