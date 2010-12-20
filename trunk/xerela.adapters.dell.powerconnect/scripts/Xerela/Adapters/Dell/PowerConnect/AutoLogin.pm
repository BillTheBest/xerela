package Xerela::Adapters::Dell::PowerConnect::AutoLogin;

use strict;
use Xerela::CLIProtocol;
use Xerela::Response;

use Xerela::Logger;

# Get the instance of the Xerela::Logger module
my $LOGGER = Xerela::Logger::get_logger();

sub execute
{
	my $cli_protocol    = shift;
	my $connection_path = shift;

	# Pull off the Xerela::Credentials instance from the Xerela::ConnectionPath object
	my $credentials = $connection_path->get_credentials();

	# Store all the information needed to connect to the device
	my $ip_address = $connection_path->get_ip_address();
	my $port       = $cli_protocol->get_port();
	my $username   = $credentials->{username};
	my $password   = $credentials->{password};

	my $protocol_name = $cli_protocol->get_protocol_name();
	$LOGGER->debug("Protocol in use: $protocol_name");
	my $cred_str = $credentials->to_string();
	$LOGGER->debug("Credentials in use: $cred_str");

	# Attempt to connect to the device
	$cli_protocol->connect( $ip_address, $port, $username, $password );
	$LOGGER->debug("Verifying the initial connection ...");

	# If all goes well during the login process, the last method to be called will be "_get_prompt"
	# and its return value will be returned all the way to here
	my $device_prompt_regex = _initial_connection( $cli_protocol, $credentials );

	# Print that the login process has been completed
	$LOGGER->debug("Login has successfully completed!\n");

	return $device_prompt_regex;
}

sub _initial_connection
{
	my $cli_protocol = shift;
	my $credentials  = shift;

	# Specify the responses to check for
	my @responses = ();
	push( @responses, Xerela::Response->new( '[Uu]ser [Nn]ame:', \&_send_username ) );
	push( @responses, Xerela::Response->new( '[Pp]assword:',   \&_send_password ) );
	#push(@responses, Xerela::Response->new('(#|\$)\s*$', \&_get_prompt));
	push( @responses, Xerela::Response->new( '>\s*$',      \&_send_enable ) );
	push( @responses, Xerela::Response->new( '(#|\$)\s*$', \&_get_prompt ) );

	my $response = $cli_protocol->wait_for_responses( \@responses );

	# Based on the response of the device, determine the next interaction that should be executed.
	if ($response)
	{
		my $next_interaction = $response->get_next_interaction();
		return &$next_interaction( $cli_protocol, $credentials );
	}
	else
	{
		$LOGGER->fatal("Invalid response from device encountered!");
	}
}

sub _send_username
{
	my $cli_protocol = shift;
	my $credentials  = shift;

	# Specify the responses to check for
	my @responses = ();
	push( @responses, Xerela::Response->new( '[Pp]assword:', \&_send_password ) );
	push( @responses, Xerela::Response->new( 'incorrect', undef, $INVALID_CREDENTIALS ) );

	# Send username credential
	my $username = $credentials->{username};
	$LOGGER->debug("Sending username credential ...");
	$cli_protocol->send($username);
	my $response = $cli_protocol->wait_for_responses( \@responses );

	if ($response)
	{
		my $next_interaction = $response->get_next_interaction();
		return &$next_interaction( $cli_protocol, $credentials );
	}
	else
	{
		$LOGGER->fatal("Invalid response from device encountered!");
	}
}

sub _send_password
{
	my $cli_protocol = shift;
	my $credentials  = shift;

	# Specify the responses to check for
	my @responses = ();
	push( @responses, Xerela::Response->new( '[Uu]ser [Nn]ame:',          undef, $INVALID_CREDENTIALS ) );
	push( @responses, Xerela::Response->new( 'incorrect|invalid', undef, $INVALID_CREDENTIALS ) );
	push( @responses, Xerela::Response->new( '>\s*$',      \&_send_enable ) );
	push( @responses, Xerela::Response->new( '(#|\$)\s*$', \&_get_prompt ) );

	# Send username credential
	my $password = $credentials->{password};
	$LOGGER->debug("Sending password credential ...");
	$cli_protocol->send($password);
	my $response = $cli_protocol->wait_for_responses( \@responses );

	if ($response)
	{
		my $next_interaction = $response->get_next_interaction();
		return &$next_interaction( $cli_protocol, $credentials );
	}
	else
	{
		$LOGGER->fatal("Invalid response from device encountered!");
	}
}

sub _get_prompt
{
	my $cli_protocol = shift;

	# Grab the last match that the CLIProtocol implementation captured
	my $last_match = $cli_protocol->last_match();
	$LOGGER->debug("---------------------------------------------------------");
	$LOGGER->debug("[LAST MATCH CAPTURED]");
	$LOGGER->debug($last_match);

	# Use a regular expression to strip the prompt from the match
	$last_match =~ /([^\s][^\r\n]*)$/;

	# Grab the extracted device prompt and clean it up for regular expression use
	my $devicePrompt = $1;
	$devicePrompt =~ s/^\s+//;
	$devicePrompt =~ s/\s+$//;
	$devicePrompt = quotemeta($devicePrompt);

	# Construct the regular expression for the prompt so that it will only match the prompt that is displayed
	# as the very last thing.  This will get around the issue of a device possibly echoing back it's prompt when
	# a command is sent.
	my $devicePromptRegEx = $devicePrompt . "\\s*\$";

	$LOGGER->debug("---------------------------------------------------------");
	$LOGGER->debug("[REGULAR EXPRESSION TO MATCH DEVICE PROMPT]");
	$LOGGER->debug($devicePromptRegEx);
	$LOGGER->debug("---------------------------------------------------------");

	return $devicePromptRegEx;
}

sub _send_enable
{
	my $cli_protocol = shift;
	my $credentials  = shift;
	
	if ( $credentials->{enablePassword} )
	{    
		# Specify the responses to check for
		my @responses = ();
		push( @responses, Xerela::Response->new( 'incorrect|invalid', undef, $INVALID_CREDENTIALS ) );
		push( @responses, Xerela::Response->new( '[Pp]assword:', \&_send_enable_password ) );
		push( @responses, Xerela::Response->new( '(#|\$)\s*$',   \&_get_prompt ) );

		# Send enable
		$cli_protocol->send('enable');
		my $response = $cli_protocol->wait_for_responses( \@responses );

		if ($response)
		{
			my $next_interaction = $response->get_next_interaction();
			return &$next_interaction( $cli_protocol, $credentials );
		}
		else
		{
			$LOGGER->fatal("Invalid response from device encountered!");
		}
	}
	else
	{
		return _get_prompt($cli_protocol);
	}
}

sub _send_enable_password
{
	my $cli_protocol = shift;
	my $credentials  = shift;

	# Specify the responses to check for
	my @responses = ();
	push( @responses, Xerela::Response->new( '[Pp]assword:|incorrect|invalid', undef, $INVALID_CREDENTIALS ) );
	push( @responses, Xerela::Response->new( '(#|\$)\s*$', \&_get_prompt ) );

	# Send password credential
	my $password = $credentials->{enablePassword};
	$LOGGER->debug("Sending enable password credential ...");
	$cli_protocol->send($password);
	my $response = $cli_protocol->wait_for_responses( \@responses );

	if ($response)
	{

		#my $next_interaction = $response->getNextInteraction();
		#return &$next_interaction($cli_protocol, $credentials);
		my $next_interaction = $response->get_next_interaction();
		return &$next_interaction( $cli_protocol, $credentials );
	}
	else
	{
		$LOGGER->fatal("Invalid response from device encountered!");
	}
}

__END__

=head1 NAME

Xerela::Adapters::Cisco::SecurityAppliance::AutoLogin - Automates the connection and authentication with a
Cisco Security Appliance device.

=head1 SYNOPSIS

    use Xerela::Adapters::Cisco::SecurityAppliance::AutoLogin;
	my $cli_protocol = Xerela::CLIProtocolFactory::create( $connection_path );
	my $prompt_regex = Xerela::Adapters::Cisco::SecurityAppliance::AutoLogin::execute( $cli_protocol, $connection_path );

=head1 DESCRIPTION

The autologin module for an adapter provides an abstract sequence of commands and responses
that allow the user to login to the device.  Usually this is via a CLI protocol such as Telnet
or SSH.  Once fully connected and authenticated with the device, the autologin module must be able
to calculate and return the a regular expression that will be leveraged by users of the module
to match the primary prompt for the device.  This is crucial in being able to send commands and wait
for their responses where leveraging the command line interface (CLI) clients provided by the Xerela
Perl framework, such as C<Xerela::Telnet> and C<Xerela::SSH>.

This module should be able to handle all the possible scenarios that might be encountered when
connecting to and authenticating with a device.

The autologin module should be abstract enough that scripts outside of the adapters can use it
as well.  For example, a script to make mass changes to a device should be able to leverage
the autologin sequence just like an adapter does during backup.

=head1 PUBLIC SUB-ROUTINES

=over 12

=item C<execute($cli_protocol, $connection_path)>

The main entry point for connecting to and authenticating with a network device.  This sub-routine
will connect to the device using the specified C<Xerela::CLIProtocol> object as the command line interface (CLI)
client and using the hostname or IP address specified within the C<Xerela::ConnectionPath> object.

This method must return a regular expression that can be used to match the primary prompt of the device that
has been connected to.  This is required so that users of the autologin module can have a way to match the
prompt after sending a command to a device and waiting for the response.

=back

=head1 PRIVATE SUB-ROUTINES

=over 12

=item C<_inital_connection($cli_protocol, $connection_path)>

Once an inital connection has been established with the network device, the first text response over the CLI is
examined.  Depending on the response, various sub-routines may be called.

=item C<_send_username($cli_protocol, $connection_path)>

This sub-routine is called if a response from the device indicates that the "username" credential should be sent to the
device.

=item C<_send_password($cli_protocol, $connection_path)>

This sub-routine is called if a response from the device indicates that the "password" credential should be sent to the
device.

=item C<_send_enable($cli_protocol, $connection_path)>

This sub-routine is called if we have reached the normal device prompt.  Since the SecurityAppliance adapter relies on commands
to be called that can only be called from enabled mode, the "enable" command will be sent to the device so that we may attempt
to enter the enabled mode.

=item C<_send_enable_password($cli_protocol, $connection_path)>

This sub-routine is called if a response from the device indicates that the "enablePassword" credential should be sent to the
device so that we may attempt to enter the enabled mode.  This most likely to happen after the "enable" command has been
sent to the device.

=item C<_get_prompt($cli_protocol, $connection_path)>

This sub-routine is called once the device has been connected to and authentication has completed successfully.  The
last match from the device will be examined the primary prompt will be parsed from it and converted into a regular
expression that can be used to match the prompt of the device.  This regular expression will be returned so that it can
be used by it's caller.

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

Contributor(s): rkruse, Dylan White (dylamite@ziptie.org)
Date: August 10, 2007

=cut
