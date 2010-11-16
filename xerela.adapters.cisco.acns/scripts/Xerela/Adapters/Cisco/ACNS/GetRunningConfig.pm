package Xerela::Adapters::Cisco::ACNS::GetRunningConfig;

use strict;
use warnings;

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
use Xerela::Adapters::Utils qw(create_empty_file escape_filename);

use Exporter 'import';
our @EXPORT_OK = qw(get_running_config);

# Get the instance of the Xerela::Logger module
my $LOGGER = Xerela::Logger::get_logger();

# Get the instance of the Xerela::Recording module
my $RECORDING = Xerela::Recording::get_recording();

sub get_running_config
{
	# Grab our Xerela::CLIProtocol and optional Xerela::ConnectionPath
	my $cli_protocol = shift;
	my $connection_path = shift;

	# Create an undef reference that can eventually hold the running configuration contents that are found
	my $response = undef;

	# Check to see if either TFTP or SCP are supported	
	my $tftp_protocol = $connection_path->get_protocol_by_name("TFTP") if ( defined($connection_path) );

	# Check to see if TFTP is supported.  If so, a combination of a CLI Protocol AND TFTP will be used
	# to retrieve the running configuration
	if ( defined($tftp_protocol) )
	{
		_touch_file_for_tftp($cli_protocol, $connection_path);
		$response = _get_running_config_tftp($cli_protocol, $connection_path);
	}
	
	# Otherwise, fall back to CLI protocol only
	else
	{
		$response = _get_running_config_cli($cli_protocol);
	}
	
	# Return the running configuration found
	return $response;
}

sub _get_running_config_cli
{
	# Grab our Xerela::CLIProtocol object
	my $cli_protocol = shift;
	
	# Sending "show running-config" command
	my $command = "show running-config";
	$cli_protocol->send( $command );
	
	# Grab the enable prompt that was retrieved by the auto-login of the IOS device.
	my $enable_prompt = $cli_protocol->get_prompt_by_name("enablePrompt");
	
	# Check to see if the enable prompt was set on the device.  If not, fall back to matching '>|#'
	my $regex = defined($enable_prompt) ? $enable_prompt : '>|#';
	my $response = $cli_protocol->wait_for($regex, 120);
	
	# remove the prompt
	$response =~ s/$regex$//;
	
	# remove any --More-- prompt lines from older (1900) devices
	$response =~ s/^--More--\s*$//mg;

	# remove any extra spaces between !
	$response =~ s/!\n\n!/!\n!/g;
	
	# remove leading cruft from the 'show' command output
	$response =~ s/^.*?(?=^!)//ms;
	
	# remove any trailing CRLF's
	$response =~ s/\n$//;
	
	# Return the running configuration found
	return $response;
}

sub _get_running_config_tftp
{
	# Grab our Xerela::CLIProtocol and Xerela::ConnectionPath objects
	my $cli_protocol = shift;
	my $connection_path = shift;

	my $tftp_file_server = $connection_path->get_file_server_by_name("TFTP");
	my $runningConfigName = escape_filename ( $cli_protocol->get_ip_address() ) . ".running-config";
	my $enable_prompt = $cli_protocol->get_prompt_by_name("enablePrompt");

	# Specify the responses to check for
	my @responses = ();
	push(@responses, Xerela::Response->new('%Error', undef, $TFTP_ERROR));
	push(@responses, Xerela::Response->new('Copy running-config to tftp failed.', undef, $TFTP_ERROR));
	push(@responses, Xerela::Response->new($enable_prompt, \&_finish));

	# Sending "copy running-config tftp" command
	my $command = "copy running-config tftp " . $tftp_file_server->get_ip_address() . " $runningConfigName";
	$cli_protocol->send( $command );
	my $response = $cli_protocol->wait_for_responses(\@responses);

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
		# Return the running configuration found
		return &$next_interaction($cli_protocol, $connection_path);
	}
}

sub _finish
{
	# Grab our Xerela::CLIProtocol and Xerela::ConnectionPath objects
	my $cli_protocol = shift;
	my $connection_path = shift;
	
	# Grab the Xerela::Connection::FileServer object representing TFTP file server
	my $tftp_file_server = $connection_path->get_file_server_by_name("TFTP");
	
	# Retrieve the running configuration file from the TFTP server
	my $running_config_name = escape_filename ( $cli_protocol->get_ip_address() ) . ".running-config";
	my $running_config_file = $tftp_file_server->get_root_dir() . "/$running_config_name";
	
	# Open up the running configuration file and read it into memory
	open(RUNNING_CONFIG, $running_config_file) || $LOGGER->fatal("[$TFTP_ERROR]\nCould not open the retrieved running configuration file stored in '$running_config_file'!");
	my @entire_file = <RUNNING_CONFIG>;
	close(RUNNING_CONFIG);
	my $running_config_contents = join("", @entire_file);
	
	# Clean up our tracks by deleteing the configuration file that was sent to the TFTP server
	unlink ($running_config_file);

	# remove any extra spaces between !
	$running_config_contents =~ s/!\n\n!/!\n!/g;
	
	#remove any trailing crlf's
	$running_config_contents =~ s/\n?\r?$//;
	
	# Record the file transfer of the running config
	# Arguments: protocol name, file name, response/contents
	$RECORDING->create_xfer_interaction($tftp_file_server->get_protocol(), $running_config_name, $running_config_contents);
	
	# Return the contents of the running configuration
	return $running_config_contents;
}

sub _touch_file_for_tftp
{
	my $cli_protocol = shift;
	my $connection_path = shift;
	
	my $tftp_file_server = $connection_path->get_file_server_by_name("TFTP");
	my $running_config_name = escape_filename ( $cli_protocol->get_ip_address() ) . ".running-config";
	create_empty_file($tftp_file_server->get_root_dir() . "/$running_config_name");
}

1;
