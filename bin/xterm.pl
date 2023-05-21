#!/usr/bin/env perl 

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	xterm.ksh
#
# PURPOSE:
#	Spawn an xterm window after prompting the user for parameters.
#
# USAGE:
#	xterm.pl
#-------------------------------------------------------------------------------
use strict;
use warnings;
use feature 'say';

my $xterm = qx[which xterm];

# Define and initialize parameters object:
my $params = {
    bg   => "CadetBlue",
    fg   => "Black",
    fn   => "9x15bold",
    cols => "80",
    rows => "45",
    sl   => "200",
    log  => 'N',
    cmd  => 'N',
};

# Subroutine to prompt user and return input:
sub prompt_user {
	my ( $prompt, $default ) = @_;
	my $default_text = defined $default ? "[$default]" : "";
	print sprintf( "%-30s %s: ", $prompt, $default_text );
	my $input = <STDIN>;
	chomp $input;
	return $input || $default;
}

# Subroutine to launch xterm
sub Xterm {
    my ($params) = @_;

    # Format the title
    my $title = "steve\@ " . localtime();

    # Prompt for the shell
    #my $shell = prompt_user( "Enter the shell (/bin/ksh)", "/bin/ksh" );

    # Determine the font parameter
    my $font_param = $params->{fn} =~ /\s/ ? "-fa"              : "-fn";
    my $font_value = $font_param eq "-fn" ? "\"$params->{fn}\"" : $params->{fn};

    # Format the xterm command
	my $cmd = "$xterm -sb -sl $params->{sl} $font_param $font_value ";
    $cmd .= "-geometry $params->{cols}x$params->{rows} -fg \"$params->{fg}\" ";
    $cmd .= "-bg \"$params->{bg}\" -title \"$title\"";
    $cmd .= " -l" if lc( $params->{log} ) eq 'y';

	# Execute the xterm command in a separate process
	my $pid = fork();

	if ($pid == 0) {
		# Child process
		system(" " . $cmd);
		exit(0);
	} elsif ($pid > 0) {
		# Parent process
		print "xterm launched in the background.\n";
		write_command_log(${cmd})
			if (lc($params->{cmd}) eq 'y')
	} else {
		# Forking failed
		die "Failed to fork a child process: $!";
	}


}    # sub Xterm

# Prompt user for parameter values:
sub get_user_inputs() {
    print "\n";
    $params->{bg} = prompt_user( "Pick a background color", $params->{bg} );
    $params->{fg} = prompt_user( "Pick a foreground color", $params->{fg} );
    $params->{fn} = prompt_user( "Enter the font", $params->{fn} );
    $params->{cols} =
      prompt_user( "Enter the number of columns", $params->{cols} );
    $params->{rows} =
      prompt_user( "Enter the number of rows", $params->{rows} );
    $params->{sl} =
      prompt_user( "Enter the memory buffer size", $params->{sl} );
    $params->{log} = prompt_user( "Enable keystroke logging? (Y/N)", $params->{log} );
    $params->{cmd} = prompt_user( "Enable command logging? (Y/N)", $params->{cmd} );
    print "\n";
}    # sub get_user_inputs()




sub write_command_log {
    my ($cmd) = @_;
	my $command_log = "/Users/steve/Documents/xterm.log";
	say "See debug file: $command_log\n";
	open(my $fh, '>>', $command_log) or die "Failed to open $command_log: $!";
	$cmd.="\n";
	say $fh "\n $cmd";
	close($fh);
	return $command_log;
}

# Launch xterm
get_user_inputs();
Xterm($params);

#-------------------------------------------------------------------------------
