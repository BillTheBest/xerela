package Xerela::Adapters::APC::SmartUPS::GetConfig;

use strict;

use Xerela::CLIProtocol;
use Xerela::Response;
use Xerela::Recording;
use Xerela::Recording::Interaction;
use Xerela::TransferProtocolFactory;
use Xerela::TransferProtocol;
use Xerela::ConnectionPath;
use Xerela::ConnectionPath::Protocol;
use Xerela::ConnectionPath::FileServer;
use Xerela::Logger;
use Xerela::FTP;
use Xerela::Adapters::Utils qw(escape_filename);

use Exporter 'import';
our @EXPORT_OK = qw(get_config);

# Get the instance of the Xerela::Logger module
my $LOGGER = Xerela::Logger::get_logger();

# Get the instance of the Xerela::Recording module
my $RECORDING = Xerela::Recording::get_recording();

sub get_config
{

	# Grab our Xerela::CLIProtocol and optional Xerela::ConnectionPath
	my $cli_protocol    = shift;
	my $connection_path = shift;

	#my $filepath		= shift;

	# Create an undef reference that can eventually hold the configuration contents that are found
	my $response    = undef;
	my $ftpProtocol = $connection_path->get_protocol_by_name("FTP") if ( defined($connection_path) );

	if ( defined $ftpProtocol )
	{
		$response = get_ftp_config( $cli_protocol, $connection_path );
		return $response;
	}
	else
	{
		$LOGGER->fatal("Unable to backup without FTP.");
	}
}

sub get_ftp_config
{
	my $cli_protocol    = shift;
	my $connection_path = shift;

	# Grab the Xerela::ConnectionPath::Protocol object representing SCP from the Xerela::ConnectionPath object
	my $ftpProtocol = $connection_path->get_protocol_by_name("FTP");

	# Retrieve the configuration file from the device
	my $ftpClient = Xerela::TransferProtocolFactory::create($connection_path);
	$ftpClient->connect(
		$connection_path->get_ip_address(),
		$ftpClient->get_port(),
		$connection_path->get_credential_by_name("username"),
		$connection_path->get_credential_by_name("password"), 0,
	);

	my $configName = 'config.ini';
	eval {
		my $filename = escape_filename ( $cli_protocol->get_ip_address() ) . ".$configName";
		$ftpClient->get( $configName, $filename );
		$ftpClient->disconnect();
		return _finish($filename);
	};
	if ($@)
	{
		return "config.ini not available on this Smart-UPS OS version";
	}
}

sub _finish
{
	my $filename = shift;

	open( CONFIG, "$filename" ) || $LOGGER->fatal("Error: Could not open $filename");
	my @array = <CONFIG>;
	close(CONFIG);
	my $contents = join( "\n", @array );

	# Clean up our tracks
	unlink($filename);

	# Record the file transfer of the config
	# Arguments: protocol name, file name, response/contents, whether or not Xerela acted as the file transfer server
	$RECORDING->create_xfer_interaction( "FTP", $filename, $contents, 0 );

	# Return the contents of the running configuration
	return $contents;
}

1;
