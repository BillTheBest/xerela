package Xerela::Adapters::Dell::PowerConnect::GetConfig;

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

	# Create an undef reference that can eventually hold the configuration contents that are found
	my $response = undef;

	# Check to see if either TFTP is supported	
	my $tftp_protocol = $connection_path->get_protocol_by_name("TFTP") if ( defined($connection_path) );

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
	my $cli_protocol = shift;
	my $filename	 = shift;

	my $more_info	= 1;
	my $command		= "show $filename";
	my $response	= "";
	my $regex		= $cli_protocol->get_prompt_by_name("prompt");
	$regex			= '('.$regex.'|More: <space>)';
	while ( defined $more_info )
	{
		# Sending "show $filename" command or space to page down
		if ( $command =~ /^show/i )
		{
			$cli_protocol->send( $command );
		}
		else
		{
			$cli_protocol->send_as_bytes( $command );
		}
		$command = "20";

		# Fall back to matching prompt or more string
		$_	= $cli_protocol->wait_for($regex);

		if ( /More: <space>/mi )
		{
			s/More: <space>.*//mig; # remove any More prompt lines
		}
		else
		{
			$more_info = undef;
		}
		$response .= $_;
	}

	$_		  = $cli_protocol->get_prompt_by_name("prompt");
	$response =~ s/^show $filename//mig; # remove leading cruft from the 'show' command output
	$response =~ s/% Unrecognized command.+$//is; # remove the error message
	$response =~ s/$_//mi; # remove the prompt
	$response =~ s/\x1b\[.{1}//mg; # remove the garbage after send_as_byte

	# Return the configuration found
	return $response;
}

sub _get_config_tftp
{
	# Grab our Xerela::CLIProtocol, Xerela::ConnectionPath objects and the filename
	my $cli_protocol		= shift;
	my $connection_path 	= shift;
	my $filename			= shift;

	my $tftp_file_server	= $connection_path->get_file_server_by_name("TFTP");
	my $regex				= $cli_protocol->get_prompt_by_name("prompt");

	# Specify the responses to check for
	my @responses = ();
	push(@responses, Xerela::Response->new('[Ee]rror|operation has failed', undef, $TFTP_ERROR));
	push(@responses, Xerela::Response->new($regex."|completed successfully", \&_finish));

	# Create the local file
	my $filepath = $tftp_file_server->get_root_dir() . "/" . escape_filename ( $cli_protocol->get_ip_address() ) . ".cfg";
	open (CFG_FILE,">$filepath");
	close (CFG_FILE);

	# Get remote file
	my $command = "copy $filename tftp://".$tftp_file_server->get_ip_address()."/".escape_filename($cli_protocol->get_ip_address()).".cfg";
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

	# Grab the Xerela::Connection::FileServer object representing TFTP file server
	my $tftp_file_server = $connection_path->get_file_server_by_name("TFTP");

	# Retrieve the configuration file from the TFTP server
	my $config_name = escape_filename ( $cli_protocol->get_ip_address() ) . ".cfg";
	my $config_file = $tftp_file_server->get_root_dir() . "/$config_name";

	# Open up the configuration file and read it into memory
	open(CONFIG, $config_file) || $LOGGER->fatal("[$TFTP_ERROR]\nCould not open the retrieved configuration file stored in '$config_file'!");
	my @entire_file = <CONFIG>;
	close(CONFIG);
	my $config_contents = join("", @entire_file);
	
	# Clean up our tracks by deleteing the configuration file that was sent to the TFTP server
	unlink ($config_file);
	
	# Record the file transfer of the config
    # Arguments: protocol name, file name, response/contents
    $RECORDING->create_xfer_interaction($tftp_file_server->get_protocol(), $config_name, $config_contents);
	
	# Return the contents of the configuration
	return $config_contents;
}

1;

__END__

=head1 NAME

Xerela::Adapters::Dell::PowerConnect::GetConfig - Retrieves the configuration from a Dell device.

=head1 SYNOPSIS

    use Xerela::Adapters::Dell::PowerConnect::GetConfig qw(get_config);
	my $config = get_config($cli_protocol);
	my $config = get_config($cli_protocol, $connection_path);

=head1 DESCRIPTION

C<Xerela::Adapters::Dell::PowerConnect::GetConfig> allows for the retrieve of the configuration from an Dell device by
using either a C<Xerela::CLIProtocol> object to retrieve the configuration via the command line using the "show config all"
command, or by using a C<Xerela::ConnectionPath> object to retrieve the config via a file transfer protocol client/agent.
The file transfer protocols that are supported currently are: TFTP and SCP.

The only subroutine a user of C<Xerela::Adapters::Cisco::CatOS::GetConfig> should be concerned with is 
C<get_config($cli_protocol, $connection_path)>; it provides an abstraction layer that hides the mechanism for
retrieving the configuration.

=head1 EXPORTED SUBROUTINES

=over 12

=item C<get_config($cli_protocol, $connection_path)>

Main entry point into the functionality for retrieveing a configuration from a CatOS-based device.
It provides an abstraction layer that hides the mechanism for retrieving the configuration file.

First, the specified C<Xerela::ConnectionPath> object is examined to see if a file transfer protocol has been specified to
use as the transfer mechanism.  If this is the case, then the corresponding private subroutine that utilizes that type of file
transfer protocol will be called.  For example, if TFTP is the file transfer protocol specified, the
C<_get_config_tftp($cli_protocol, $connection_path)> private subroutine will be used.  If the SCP is the file transfer protocol
specified, the C<_get_config_scp($cli_protocol, $connection_path)> private subroutine will be used. 

If no file transfer protocol has been specified, then the specified C<Xerela::CLIProtocol> object will be used to
retrieve the configuration via a command-line interface (CLI) through the C<get_config_cli($cli_protocol)> private
subroutine.

Regardless of the mechanism chosen, the contents of the configuration will be returned.

Input:		$cli_protocol -		A valid C<Xerela::CLIProtocol> object that is already connected to a CatOS-based device.
			$connection_path -	Optional.  C<A valid Xerela::ConnectionPath> object that contains all of the IP, credential,
								protocol, and file server information needed to correctly retrieve the configuration
								from the the CatOS-based device.

=back

=head1 PRIVATE SUBROUTINES

=over 12

=item C<_get_config_cli($cli_protocol)>

Retrieves the configuration for an CatOS-based device by executing the "show config all" command via a C<Xerela::CLIProtocol>
object that has been previously connected to a CatOS-based device.

This subroutine will be called by C<get_config($cli_protocol, $connection_path)> if no valid C<Xerela::ConnectionPath>
object was specified.

=item C<_get_config_scp($cli_protocol, $connection_path)>

Retrieves the configuration from the CatOS-based device using an SCP client to retrieve the "config" file that stores the
configuration file.  The contents of this file will the be parsed and returned.

This subroutine will be called by C<get_config($cli_protocol, $connection_path)> if a valid C<Xerela::ConnectionPath>
object was specified that contains a valid C<Xerela::ConnectionPath::Protocol> object representing the SCP protocol.

=item C<_get_config_tftp($cli_protocol, $connection_path)>

Starts the retrieval of the configuration for an CatOS-based device by caliing the "copy config tftp all" command via 
a C<Xerela::CLIProtocol> object that has already been connected to a CatOS-based device.

=back

=head1 PRIVATE SUBROUTINES POSSIBLY INVOKED BY C<_get_config_tftp($cli_protocol, $connection_path)>

=over 12

=item C<_specify_source_file($cli_protocol, $connection_path)>

Continues the retrieval of the configuration for an CatOS-based device by specifying the name of the file on 
the device that contains the configuration.  This will be "config".  The command/input is sent via a C<Xerela::CLIProtocol> object
that has already been connected to an CatOS-based device.

The file name for the configuration file might have to be specified for certain versions of CatIOS that require this input as
part of the follow-up information required by the "copy config tftp all" command.

=item C<_specify_tftp_address($cli_protocol, $connection_path)>

Continues the retrieval of the configuration for an CatOS-based device by specifying the IP address of the TFTP file server to backup
the configuration to via a C<Xerela::CLIProtocol> object that has already been connected to an CatOS-based device. 

=item C<_specify_config_name($cli_protocol, $connection_path)>

Continues the retrieval of the configuration for an CatOS-based device by specify the name to save the configuration file under on
the TFTP server via a C<Xerela::CLIProtocol> object that has already been connected to an CatOS-based device.

The name of the configuration file will always be determined using the following algorithm: the IP address of
the device we are interaction with the extension ".config" appended to it.  Example: "10.100.10.10.config".

=item C<_confirm_tftp($cli_protocol, $connection_path)>

Continues the retrieval of the configuration for an CatOS-based device by sending a "yes" confirmation via a
C<Xerela::CLIProtocol> object that has already been connected to an CatOS-based device.

=item C<_finish($cli_protocol, $connection_path)>

Finishes the retrieval of the configuration for an CatOS-based device by reading the configuration file that was successfully
backed up to the specified TFTP server and retrieving the contents so that it can be parsed and returned.

=back

=head1 LICENSE

The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS"
basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations
under the License.

The Original Code is Ziptie Client Framework.

The Initial Developer of the Original Code is AlterPoint.
Portions created by AlterPoint are Copyright (C) 2006,
AlterPoint, Inc. All Rights Reserved.

=head1 AUTHOR

Contributor(s): dwhite (dylamite@xerela.org)
Date: August 9, 2007

=cut
