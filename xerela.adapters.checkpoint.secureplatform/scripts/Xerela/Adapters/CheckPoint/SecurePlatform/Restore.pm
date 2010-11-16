package Xerela::Adapters::CheckPoint::SecurePlatform::Restore;

use strict;

use Xerela::CLIProtocol;
use Xerela::Response;
use Xerela::ConnectionPath;
use Xerela::Logger;
use Xerela::Adapters::Utils qw(escape_filename);
use Xerela::Adapters::CheckPoint::SecurePlatform::Disconnect qw(disconnect);

# Get the instance of the Xerela::Logger module
my $LOGGER = Xerela::Logger::get_logger();

sub invoke
{
	my $package_name = shift;
	my $command_doc  = shift;    # how to restore config

	# Initial connection
	my ( $connectionPath, $restoreFile ) = Xerela::Typer::translate_document( $command_doc, 'connectionPath' );
	my $cliProtocol = Xerela::CLIProtocolFactory::create($connectionPath);
	my $promptRegex = Xerela::Adapters::CheckPoint::SecurePlatform::AutoLogin::execute( $cliProtocol, $connectionPath );

	# Restore the config
	execute( $connectionPath, $cliProtocol, $promptRegex, $restoreFile );

	# Disconnect from the specified device
	disconnect($cliProtocol);
}

sub execute
{
	my ( $connectionPath, $cliProtocol, $prompt, $restoreFile ) = @_;

	my $tftpServer = $connectionPath->get_file_server_by_name("TFTP");
	if ( defined $tftpServer )
	{
		my $prefix     = escape_filename( $cliProtocol->get_ip_address() . '-' );
		my $tftpFolder = $tftpServer->get_root_dir();
		my $fullFile   = File::Temp::tempnam( $tftpFolder, $prefix );
		my $shortFile  = $fullFile;
		$shortFile =~ s/^.+[\\\/]//;

		# Write out the file to the TFTP directory
		open( CONFIG_FILE, ">$fullFile" );
		print CONFIG_FILE $restoreFile->get_blob();
		close(CONFIG_FILE);

		$cliProtocol->send_and_wait_for( 'tftp ' . $tftpServer->get_ip_address(), 'tftp>' );
		my $tftpResponse = $cliProtocol->send_and_wait_for( 'get ' . $shortFile . ' ' . $restoreFile->get_path(), 'tftp>', 180 );
		$cliProtocol->send_and_wait_for( 'quit', $prompt );
		unlink($fullFile);
		if ( $tftpResponse =~ /timed out/i )
		{
			$LOGGER->fatal_error_code($TFTP_ERROR);
		}
	}
	else
	{
		$LOGGER->fatal("Unable to restore file.  Protocol TFTP is not available.");
	}
}

1;
