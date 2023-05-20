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

my $xterm_path = "/opt/X11/bin/xterm";

# Define and initialize parameters object:
my $params = {
    bg   => "CadetBlue",
    fg   => "Black",
    fn   => "9x15bold",
    cols => "80",
    rows => "45",
    sl   => "200",
    log  => 'N',
    dbg  => 'N',
};

# Subroutine to prompt user and return input:
sub prompt_user {
    my ( $question, $default ) = @_;
    my $default_prompt = defined $default ? " [$default]" : "";
    print "$question$default_prompt: ";
    my $input = <STDIN>;
    chomp $input;
    return $input ne "" ? $input : $default;
}    # sub prompt_user

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
    my $cmd = "$xterm_path -sb -sl $params->{sl} $font_param \"$font_value\" ";
    $cmd .= "-geometry $params->{cols}x$params->{rows} -fg \"$params->{fg}\" ";
    $cmd .= "-bg \"$params->{bg}\" -title \"$title\"";
    $cmd .= " -l" if lc( $params->{log} ) eq 'y';

    #$cmd .= " -e '$shell'";
	# Rest of your code...

	# Execute the xterm command in a separate process
	my $pid = fork();

	if ($pid == 0) {
		# Child process
		system($cmd);
		exit(0);
	} elsif ($pid > 0) {
		# Parent process
		print "xterm launched in the background.\n";
		write_debug_file(${cmd})
			if (lc($params->{dbg}) eq 'y')
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
    $params->{log} = prompt_user( "Enable logging? (Y/N)", $params->{log} );
    $params->{dbg} = prompt_user( "Enable debugging? (Y/N)", $params->{dbg} );
    print "\n";
}    # sub get_user_inputs()




sub write_debug_file {
    my ($cmd) = @_;
	my $debug_file = "/Users/steve/Documents/xterm.debug";
	say "See debug file: $debug_file\n";
	open(my $fh, '>>', $debug_file) or die "Failed to open $debug_file: $!";
	say $fh $cmd;
	close($fh);
	return $debug_file;
}

# Launch xterm
get_user_inputs();
Xterm($params);

#-------------------------------------------------------------------------------
