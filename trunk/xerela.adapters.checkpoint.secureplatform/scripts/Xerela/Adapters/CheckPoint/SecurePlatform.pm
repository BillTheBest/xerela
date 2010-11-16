package Xerela::Adapters::CheckPoint::SecurePlatform;

use strict;

use Xerela::Adapters::CheckPoint::SecurePlatform::AutoLogin;
use Xerela::Adapters::CheckPoint::SecurePlatform::Disconnect qw(disconnect);
use Xerela::Adapters::CheckPoint::SecurePlatform::Parsers
  qw(create_config parse_local_accounts parse_chassis parse_snmp parse_system parse_interfaces parse_static_routes);
use Xerela::Adapters::CheckPoint::SecurePlatform::BackupFiles qw(get_file);
use Xerela::Adapters::CheckPoint::OPSEC::Parsers qw(parse_object_groups parse_rules);
use Xerela::Adapters::Utils qw(get_model_filehandle close_model_filehandle);
use Xerela::Adapters::GenericAdapter;
use Xerela::CLIProtocol;
use Xerela::CLIProtocolFactory;
use Xerela::ConnectionPath;
use Xerela::Credentials;
use Xerela::Logger;
use Xerela::Model::XmlPrint;
use Xerela::Typer;

# Grab a reference to the Xerela::Logger
my $LOGGER = Xerela::Logger::get_logger();

sub backup
{
	my $packageName = shift;
	my $backupDoc   = shift;    # how to backup this device
	my $responses   = {};       # will contain device responses to be handed to the Parsers module

	# Translate the backup operation XML document into Xerela::ConnectionPath
	my ($connectionPath) = Xerela::Typer::translate_document( $backupDoc, 'connectionPath' );

	# Set up the XmlPrint object for printing the XerelaElementDocument (ZED)
	my $filehandle = get_model_filehandle( 'Check Point SecurePlatform', $connectionPath->get_ip_address() );
	my $printer = Xerela::Model::XmlPrint->new( $filehandle, 'common' );
	$printer->open_model();

	# Make a Telnet or SSH connection
	my ( $cliProtocol, $promptRegex ) = _connect($connectionPath);
	$responses->{hostname}  = $cliProtocol->send_and_wait_for( 'hostname',                 $promptRegex );
	$responses->{dmidecode} = $cliProtocol->send_and_wait_for( 'dmidecode',                $promptRegex );
	$responses->{version}   = $cliProtocol->send_and_wait_for( 'ver',                      $promptRegex );
	$responses->{snmp}      = $cliProtocol->send_and_wait_for( 'cat /etc/snmp/snmpd.conf', $promptRegex );
	$responses->{uptime}    = $cliProtocol->send_and_wait_for( 'uptime',                   $promptRegex );
	$responses->{dmesg}     = $cliProtocol->send_and_wait_for( 'dmesg',                    $promptRegex );
	$responses->{routes}    = $cliProtocol->send_and_wait_for( 'route -n',                 $promptRegex );
	$responses->{users}     = $cliProtocol->send_and_wait_for( 'showusers',                $promptRegex );
	$responses->{interfaces} = $cliProtocol->send_and_wait_for( 'ifconfig -a', $promptRegex );
	parse_system( $responses, $printer );
	parse_chassis( $responses, $printer );
	my $fwdir = $cliProtocol->send_and_wait_for( 'echo $FWDIR', $promptRegex );
	( $responses->{fwdir} ) = $fwdir =~ /^(\/.*\b)/m;
	$responses->{rulesFile} = get_file( $responses->{fwdir} . '/database/rules.C', $cliProtocol, $connectionPath, $promptRegex );
	$responses->{objectsFile} = get_file( $responses->{fwdir} . '/database/objects.C', $cliProtocol, $connectionPath, $promptRegex );
	disconnect($cliProtocol);
	
	create_config( $responses, $printer );
	parse_object_groups( $responses, $printer );
	parse_rules( $responses, $printer );
	unlink( $responses->{rulesFile} );
	unlink( $responses->{objectsFile} );
	parse_interfaces( $responses, $printer );
	parse_local_accounts( $responses, $printer );
	parse_snmp( $responses, $printer );
	parse_static_routes( $responses, $printer );

	$printer->close_model();                # close out the XerelaElementDocument
	close_model_filehandle($filehandle);    # Make sure to close the model file handle
}

sub commands
{
	my $packageName = shift;
	my $commandDoc  = shift;

	my ( $connectionPath, $commands ) = Xerela::Typer::translate_document( $commandDoc, 'connectionPath' );
	my ( $cliProtocol, $devicePromptRegex ) = _connect($connectionPath);

	my $result = Xerela::Adapters::GenericAdapter::execute_cli_commands( 'Check Point SecurePlatform',
		$cliProtocol, $commands, $devicePromptRegex . '|(#|\$|>)\s*$' );
	_disconnect($cliProtocol);
	return $result;
}

sub _connect
{

	# Grab our arguments
	my $connectionPath = shift;

	# Create a new CLI protocol object by using the Xerela::CLIProtocolFactory::create sub-routine
	# to examine the Xerela::ConnectionPath argument for any command line interface (CLI) protocols
	# that may be specified.
	my $cliProtocol = Xerela::CLIProtocolFactory::create($connectionPath);

	# Make a connection to and successfully authenticate with the device
	my $devicePromptRegex =
	  Xerela::Adapters::CheckPoint::SecurePlatform::AutoLogin::execute( $cliProtocol, $connectionPath );

	# Store the regular expression that matches the primary prompt of the device under the key "prompt"
	# on the Xerela::CLIProtocol object
	$cliProtocol->set_prompt_by_name( 'prompt', $devicePromptRegex );

# Return the created Xerela::CLIProtocol object and the device prompt encountered after successfully connecting to a device.
	return ( $cliProtocol, $devicePromptRegex );
}

1;
