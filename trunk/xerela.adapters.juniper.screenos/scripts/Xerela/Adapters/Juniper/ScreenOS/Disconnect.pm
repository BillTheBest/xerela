# Disconnect helps automate the exit and disconnect process from the devices.
#
# Author:	Dylan White (dylamite@xerela.org)
# Customized to work with !IOS devices: Mekhman Kourbanov (mkourbanov@isthmusit.com)
package Xerela::Adapters::Juniper::ScreenOS::Disconnect;

use strict;
use Xerela::CLIProtocol;
use Xerela::Response;
use Xerela::Logger;

use Exporter 'import';
our @EXPORT_OK =
  qw(disconnect);

# Get the instance of the Xerela::Logger module
my $LOGGER = Xerela::Logger::get_logger();

# Attempts to disconnect from an IOS-based device that a CLIProtocol object is currently connected to.
# If all is well, the device will be successfully disconnected from and no error will occur.
#
# Input:	$cliProtocol -	A valid Xerela::CLIProtocol object that is already connected to a device.
#			$debug -		Whether or not to display debug information.
#
# Returns:	Nothing.
sub disconnect
{
	# Grab the CLI protocol
	my $cliProtocol = shift;

	# Keep sending the "exit" command until we have successfully exited the device
	_send_exit($cliProtocol);
	
	# Finally, disconnect from our CLIProtocol
	$cliProtocol->disconnect();
}

# Repeatedly send the "exit" command to a device that a CLIProtocol is already connected to until it
# has successfully closed out its connection.
#
# Input:	$cliProtocol -	A valid Xerela::CLIProtocol object that is already connected to a device.
#
# Returns:	Nothing.
sub _send_exit
{
	# Grab the CLI protocol
	my $cliProtocol = shift;
	
	# Specify the responses to handle
	my @responses = ();
	push(@responses, Xerela::Response->new("#|>", \&_send_exit));
	push(@responses, Xerela::Response->new('Configuration\s+modified', \&_send_no));
	push(@responses, Xerela::Response->new(".*"));

	# Send the "exit" command
	$cliProtocol->send("exit");
	my $response = $cliProtocol->wait_for_responses(\@responses);
	
	# Based on the response of the device, determine the next interaction that should be executed.
	my $nextInteraction = undef;
	if ($response)
	{
		$nextInteraction = $response->get_next_interaction();
	}
	else
	{
		$LOGGER->fatal("Invalid response from device encountered!");
	}
	
	# Call the next interaction if there is one to call
	if ($nextInteraction)
	{
		return &$nextInteraction($cliProtocol);
	}
}

# Send the "n" option to a device when it asks for configuration saving
#
# Input:	$cliProtocol -	A valid Xerela::CLIProtocol object that is already connected to a device.
#
# Returns:	Nothing.
sub _send_no
{
	# Grab the CLI protocol
	my $cliProtocol = shift;
	
	# Specify the responses to handle
	my @responses = ();
	push(@responses, Xerela::Response->new(".*"));
	
	# Send the "n" command
	$cliProtocol->send("n");
	my $response = $cliProtocol->wait_for_responses(\@responses);
	
	# Based on the response of the device, determine the next interaction that should be executed.
	my $nextInteraction = undef;
	if ($response)
	{
		$nextInteraction = $response->get_next_interaction();
	}
	else
	{
		$LOGGER->fatal("Invalid response from device encountered!");
	}
	
	# Call the next interaction if there is one to call
	if ($nextInteraction)
	{
		return &$nextInteraction($cliProtocol);
	}
}

1;