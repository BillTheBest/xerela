package Xerela::Adapters::Enterasys::SSR::GetConfig;

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
	my $cli_protocol	= shift;
	my $connection_path = shift;
	my $filename		= shift;
	$filename = 'startup' if ( !$filename );

	# Create an undef reference that can eventually hold the configuration contents that are found
	my $response = undef;

	# Check to see if either TFTP is supported	
	my $tftp_protocol	= $connection_path->get_protocol_by_name("TFTP") if ( defined($connection_path) );

	# Check to see if TFTP is supported.  If so, a combination of a CLI Protocol AND TFTP will be used
	# to retrieve the configuration
	if ( defined($tftp_protocol) )
	{
		$response = _get_config_tftp($cli_protocol, $connection_path, $filename);
	}
	
	# Otherwise, fall back to CLI protocol only
	else
	{
		$response = _get_config_cli($cli_protocol, $filename);
	}

	# Return the configuration found
	return $response;
}

sub _get_config_cli
{
	# Grab our Xerela::CLIProtocol object
	my $cli_protocol	= shift;
	my $filename		= shift;
	$filename = 'startup' if ( !$filename );

	# Get the prompt regex
	my $prompt_regex = $cli_protocol->get_prompt_by_name("prompt");

	# Output the configuration
	$_ = $cli_protocol->send_and_wait_for( "show $filename-config", $prompt_regex );

	# Clean the output
	s/^show show $filename-config\s*$//mig; # remove leading cruft from the 'show' command output
	s/$prompt_regex//mg; # remove the garbage after send_as_byte

	# Return the configuration found
	$_;
}

sub _get_config_tftp
{
	# Grab our Xerela::CLIProtocol, Xerela::ConnectionPath objects and the filename
	my $cli_protocol	= shift;
	my $connection_path = shift;
	my $filename		= shift;
	$filename = 'startup' if ( !$filename );

	my $tftp_file_server	= $connection_path->get_file_server_by_name("TFTP");

	# Specify the responses to check for
	my @responses = ();
	push(@responses, Xerela::Response->new('[^\s-]+-E\S+', undef, $TFTP_ERROR));
	push(@responses, Xerela::Response->new('TFTP-I-XFERRATE', \&_finish));

	# Create the local file
	my $filepath = $tftp_file_server->get_root_dir() . "/" . $filename . "-config." . escape_filename ( $cli_protocol->get_ip_address() );
	open (CFG_FILE,">$filepath");
	close (CFG_FILE);

	# Get remote file
	my $command = "copy $filename to tftp://".$tftp_file_server->get_ip_address()."/".$filename."-config.".escape_filename($cli_protocol->get_ip_address());
	$cli_protocol->send( $command );
	my $response = $cli_protocol->wait_for_responses(\@responses, 180);
	
	# Based on the response of the device, determine the next interaction that should be executed.
	my $next_interaction = undef;
	if ($response)
	{
		$next_interaction = $response->get_next_interaction();
	}
	else
	{
		$LOGGER->fatal("Invalid response from device encountered!");
	}
	
	# Call the next interaction if there is one to call
	if ($next_interaction)
	{
		# Return the configuration found
		return &$next_interaction($cli_protocol, $connection_path, $filename);
	}
}

sub _finish
{
	# Grab our Xerela::CLIProtocol and Xerela::ConnectionPath objects
	my $cli_protocol	= shift;
	my $connection_path = shift;
	my $filename		= shift;
	$filename = 'startup' if ( !$filename );

	# Grab the Xerela::Connection::FileServer object representing TFTP file server
	my $tftp_file_server = $connection_path->get_file_server_by_name("TFTP");

	# Retrieve the configuration file from the TFTP server
	my $config_file = $tftp_file_server->get_root_dir() . "/" . $filename . "-config." . escape_filename( $cli_protocol->get_ip_address() );

	# Open up the configuration file and read it into memory
	open(CONFIG, $config_file) || $LOGGER->fatal("[$TFTP_ERROR]\nCould not open the retrieved configuration file stored in '$config_file'!");
	my @entire_file = <CONFIG>;
	close(CONFIG);
	my $config_contents = join("", @entire_file);
	
	# Clean up our tracks by deleteing the configuration file that was sent to the TFTP server
	unlink ($config_file);
	
	# Record the file transfer of the config
    # Arguments: protocol name, file name, response/contents
    $RECORDING->create_xfer_interaction($tftp_file_server->get_protocol(), $filename."-config", $config_contents);
	
	# Return the contents of the configuration
	return $config_contents;
}

1;