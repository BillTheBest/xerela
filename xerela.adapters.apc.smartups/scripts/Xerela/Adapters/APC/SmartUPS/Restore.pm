package Xerela::Adapters::APC::SmartUPS::Restore;

use strict;

use Xerela::CLIProtocol;
use Xerela::Response;
use Xerela::ConnectionPath;
use Xerela::CLIProtocolFactory;
use Xerela::Adapters::APC::SmartUPS::AutoLogin;
use Xerela::Logger;
use Xerela::FTP;
use Xerela::Adapters::Utils qw(escape_filename);

# Get the instance of the Xerela::Logger module
my $LOGGER = Xerela::Logger::get_logger();

sub invoke
{
	my $package_name = shift;
	my $command_doc  = shift; # how to restore config

	# Initial connection
	my ( $connectionPath, $restoreFile ) = Xerela::Typer::translate_document( $command_doc, 'connectionPath' );
	my ( $cli_protocol, $prompt_regex ) = _connect( $connectionPath );

	# Restore the config
	execute( $connectionPath, $cli_protocol, $prompt_regex, $restoreFile );

	# Disconnect from the specified device
	_disconnect($cli_protocol);
}

sub _connect
{
	# Grab our arguments
	my $connection_path = shift;

	# Create a new CLI protocol object by using the Xerela::CLIProtocolFactory::create sub-routine
	# to examine the Xerela::ConnectionPath argument for any command line interface (CLI) protocols
	# that may be specified.
	my $cli_protocol = Xerela::CLIProtocolFactory::create($connection_path);

	# Make a connection to and successfully authenticate with the device
	my $device_prompt_regex = Xerela::Adapters::APC::SmartUPS::AutoLogin::execute( $cli_protocol, $connection_path );
	
	# Store the regular expression that matches the primary prompt of the device under the key "prompt"
	# on the Xerela::CLIProtocol object
	$cli_protocol->set_prompt_by_name( 'prompt', $device_prompt_regex );
	
	# Return the created Xerela::CLIProtocol object and the device prompt encountered after successfully connecting to a device.
	return ( $cli_protocol, $device_prompt_regex );
}

sub _disconnect
{
	my $cliProtocol = shift;
	my $prompt      = $cliProtocol->get_prompt_by_name('prompt');
	$_ = $cliProtocol->send_as_bytes_and_wait( '1B', $prompt );    # escape until we get to the main menu
	if ( /(\d+)-\s*Logout/ )
	{
		return $cliProtocol->send($1);
	}
	$cliProtocol->disconnect();
}

sub execute
{
	my ($connection_path, $cli_protocol, $enable_prompt_regex, $restoreFile) = @_;

	# Check to see if TFTP is supported
	my $ftp_protocol = $connection_path->get_protocol_by_name("FTP") if ( defined($connection_path) );

	if ( $restoreFile->get_path() =~ /config/i )
	{
		if ( defined($ftp_protocol) )
		{
			restore_via_ftp( $connection_path, $cli_protocol, $restoreFile, $enable_prompt_regex );
		}
		else
		{
			$LOGGER->fatal("Unable to restore APC SmartUPS config. Protocol FTP is not available.");
		}
	}
	else
	{
		$LOGGER->fatal( "Unable to promote this type of configuration '" . $restoreFile->get_path() . "'." );
	}
}

sub restore_via_ftp
{
	my ( $connectionPath, $cliProtocol, $promoteFile, $promptRegex ) = @_;
	my $ftpProtocol		= $connectionPath->get_file_server_by_name("FTP");
	my $configName		= escape_filename ( $cliProtocol->get_ip_address() ) . ".config";
	my $configFile		= $ftpProtocol->get_root_dir() . "/$configName";

	# Write out the file to the TFTP directory
	open( CONFIG_FILE, ">$configFile" );
	print CONFIG_FILE $promoteFile->get_blob();
	close( CONFIG_FILE );

	# Store the configuration file to the device
	my $ftpClient = Xerela::TransferProtocolFactory::create( $connectionPath );
	$ftpClient->connect(	$connectionPath->get_ip_address(),
							$ftpClient->get_port(),
							$connectionPath->get_credential_by_name("username"),
							$connectionPath->get_credential_by_name("password"),
							0,
	 );

	$ftpClient->put( $configFile, $promoteFile->get_path() );
	$ftpClient->disconnect();

	return _finish( $connectionPath, $cliProtocol, $promoteFile, $promptRegex );
}

sub _finish
{
	my ( $connectionPath, $cliProtocol, $promoteFile, $promptRegex ) = @_;
	my $ftpProtocol		= $connectionPath->get_file_server_by_name("FTP");
	my $configName		= escape_filename ( $cliProtocol->get_ip_address() ) . ".config";
	my $configFile		= $ftpProtocol->get_root_dir() . "/$configName";
	unlink($configFile);

	return 0;
}

1;
