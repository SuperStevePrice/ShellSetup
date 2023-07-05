#!/usr/bin/env perl

#-------------------------------------------------------------------------------
#         Copyright (C) 2014    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#    xt.pl [--debug]
#
# PURPOSE:
#    This Perl/Tk program creates a GUI panel of buttons, input fields and
#    checkbuttons that allows the creation of xterm windows with different
#    attributes assigned by the user.
#
# HISTORY:
#    07/23/01 rp3138    Created
#
# HISTORY:
#    $Id: xt.pl 6 2014-05-07 00:52:30Z SuperStevePrice $
#    $Date: 2014-05-06 17:52:30 -0700 (Tue, 06 May 2014) $
#    $Revision: 6 $
#    $Author: SuperStevePrice $
#-------------------------------------------------------------------------------
use Tk;
use Getopt::Long;

# Set default value for the debug flag
my $debug = 0;

# Define the command-line options
GetOptions('debug' => \$debug);

# Add your script code here

#-------------------------------------------------------------------------------
# Forward subroutine declarations:
sub Xterm;
sub Xterm_button;
sub create_specific_Xterm_buttons;
sub define_customized_Xterm_button;
sub define_entries;
sub define_focus_bindings;
sub define_font_button;
sub define_font_label;
sub define_fonts_listBox;
sub define_frames;
sub define_log_checkbutton;
sub define_quit_button;
sub destroy_ErrMsgWindow;
sub destroy_ListBoxWindow;
sub fonts_manager;
sub get_host_server_name;
sub get_fonts;
sub pick_font;
sub set_xtrc_values;
sub trim;

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Default global xterm parameters.
# Set 'em before creating any create_specific_Xterm_buttons:
#
sub set_xtrc_values {
    @frame = ();
    $host  = get_host_server_name();

    # If .xtrc exists open it and set globals from those found there.
    # Look only in $ENV{'HOME'}.  If it is not found, use defaults coded here.
    if ( open( XTRC, "$ENV{'HOME'}/.xtrc" ) ) {
        while (<XTRC>) {

            # Skip comment and blank lines, or apparently blank lines:
            next if (/^#|^\w*$|^$|^\n$/);

            chomp();

            my ( $env_variable_name, $env_variable_value ) = /([^=]+)=(.*)/;
            $env_variable_value = trim($env_variable_value);

            if ( $env_variable_name =~ /x_cols/ ) {
                $x_cols = $env_variable_value;
            }

            if ( $env_variable_name =~ /x_rows/ ) {
                $x_rows = $env_variable_value;
            }

            if ( $env_variable_name =~ /x_sl/ ) {
                $x_sl = $env_variable_value;
            }

            if ( $env_variable_name =~ /x_fa/ ) {
                $x_fa = $env_variable_value;
            }

            if ( $env_variable_name =~ /x_fs/ ) {
                $x_fs = $env_variable_value;
            }

            if ( $env_variable_name =~ /x_bg/ ) {
                $x_bg = $env_variable_value;
            }

            if ( $env_variable_name =~ /x_fg/ ) {
                $x_fg = $env_variable_value;
            }

            if ( $env_variable_name =~ /log/ ) {
                $x_log = $env_variable_value;
            }

            if ( $env_variable_name =~ /x_path/ ) {
                $x_path = $env_variable_value;
            }
        }
    }

    # Now use defaults if we don't have values yet:
    $x_cols = 80
        if ( !defined($x_cols) || !$x_cols );
    $x_rows = 44
        if ( !defined($x_rows) || !$x_rows );
    $x_sl = 200
        if ( !defined($x_sl) || !$x_sl );
    $x_fa = "9x15bold"
        if ( !defined($x_fa) || !$x_fa );
    $x_fs = "16"
        if ( !defined($x_fs) || !$x_fs );
    $x_bg = "DarkGrey"
        if ( !defined($x_bg) || !$x_bg );
    $x_fg = "Navy"
        if ( !defined($x_fg) || !$x_fg );
    $x_log = 0    # default is no logging
        if ( !defined($x_log) || !$x_log );

    # Define the fullpath to the xterm executables on this server:
    $x_path = "/opt/X11/bin"
        if ( !defined($x_path) || !$x_path );

    $xterm = "$x_path/xterm";
    my ($dev,  $ino,   $mode,  $nlink, $uid,     $gid, $rdev,
        $size, $atime, $mtime, $ctime, $blksize, $blocks
    ) = stat($xterm);

    $errMsg =
          "\n$xterm cannot be found.\n"
        . "If $ENV{'HOME'}/.xtrc exists correct x_path.\n"
        . "If $ENV{'HOME'}/.xtrc does not exist create it with correct x_path.\n";

    die("$errMsg\n")
        if ( !$size );

}    # end of sub set_xtrc_values

#
#-------------------------------------------------------------------------------

# MAIN BLOCK -------------------------------------------------------------------
set_xtrc_values();

# Create top Main Window:
$top = MainWindow->new();

$top->title("Xterm Window Maker [$host]");
$top->configure( -background => 'black' );

create_specific_Xterm_buttons();

define_frames();

define_entries();

define_focus_bindings();

define_font_button();

define_log_checkbutton();

define_customized_Xterm_button();

define_quit_button();

MainLoop();

# MAIN BLOCK -- End ------------------------------------------------------------

#-------------------------------------------------------------------------------
# Subroutines follow:
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
sub get_host_server_name {
    my $host = "Agnes Dei";

    # Snatch the hostname from the UNIX hostname command:
    open( HOST, "hostname |" ) or die("Can not execute hostname\n");
    $host = <HOST>;
    chomp($host);

    return $host;
}    # end of sub get_host_server_name;

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
sub Xterm {
    my ( $x_bg, $x_fg ) = @_;

    # Snatch the date from the scalar localtime():
    my $date = scalar localtime();

    # Create a window title from $env(LOGNAME), $host, and date:
    my $title = "$ENV{LOGNAME}\@${host}   ${date}";

    # Create a geometry setting from columns and rows:
    my $x_geo = "${x_cols}x${x_rows}";

    #my $cmd = "nohup $x_path/xterm -ls -sb -sl $x_sl";
    my $cmd = "nohup /usr/bin/env xterm -ls -sb -sl $x_sl";

    if ($x_fa) {
        $cmd .= " -fa \"$x_fa\"";
    }

    if ($x_fs) {
        $cmd .= " -fs \"$x_fs\"";
    }

    if ( $x_fa eq "" ) {

        # Parsing failed. Use fallback font.
        $cmd .= " -fa \"9x15bold\"";
    }

    if ( $x_fs eq "" ) {

        # Parsing failed. Use fallback font.
        $cmd .= " -fa 16";
    }

    $cmd .= " -geometry $x_geo -fg $x_fg -bg $x_bg -title \"$title\"";
    $cmd .= " -l" if ($x_log);

    # Uncomment the line below to debug the $cmd:
    print "DEBUG: cmd=$cmd\n"
        if ($debug);

    open( XT, "| $cmd &" ) or die("Cannot execute $x_path/xterm\n");
    print XT "";
}

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# BUTTONS.  All for creating xterm windows of specific colors:
sub create_specific_Xterm_buttons {
    my @colors;         # pairs of colors, background foreground
    my @button = ();    # an array of colorized buttons to invoke Xterm()

    # COLORS       BACKGROUND        FOREGROUND:
    push( @colors, "grey            black" );
    push( @colors, "LightSteelBlue    navy" );
    push( @colors, "CadetBlue        white" );
    push( @colors, "CadetBlue        black" );
    push( @colors, "blue            white" );
    push( @colors, "navy            white" );
    push( @colors, "navy            orange" );
    push( @colors, "navy            yellow" );
    push( @colors, "DarkGreen        white" );
    push( @colors, "DarkSeaGreen        black" );
    push( @colors, "DarkRed        white" );
    push( @colors, "salmon        black" );
    push( @colors, "SaddleBrown        white" );
    push( @colors, "tan            black" );
    push( @colors, "LightYellow        black" );
    push( @colors, "black        lightSteelBlue" );

    # Roll thru the @colors array and create Xterm buttons with the background
    # and foreground colors specified.  Note that the -command is fired by an
    # anonymous array with a reference to the Xterm() subroutine and 2
    # parameters to Xterm(), which happen to be the back- and fore- ground
    # colors:
    for ( my $idx = $f_idx = $last_f_idx = 0 ; $idx <= $#colors ; $idx++ ) {
        my $leading_zero = "0";
        $leading_zero = ""
            if ( ( $idx + 1 ) > 9 );
        my $button_text = "Xterm Window " . $leading_zero . ( $idx + 1 );
        my ( $x_bg, $x_fg ) = split /\s+/, $colors[$idx];

        if ( $idx % 2 == 0 ) {
            $f_idx++;
        }

        # Create a series of frames for the buttons. Each frame may hold
        # up to a pair of buttons.  Don't create any frame more than once.
        # This is prevented by the use of $last_f_idx:
        if ( $last_f_idx < $f_idx ) {
            $frame[$f_idx] = $top->Frame()->pack(
                -side => "top",
                -fill => "y",
            );

            $frame[$f_idx]->configure(
                -borderwidth => 2,
                -background  => 'black',
            );
            $last_f_idx = $f_idx;
        }

        $button[$idx] = $frame[$f_idx]->Button(
            -text        => "$button_text",
            -command     => [ \&Xterm, $x_bg, $x_fg ],
            -borderwidth => 5,
            -padx        => 5,
            -pady        => 5,
            -background  => $x_bg,
            -foreground  => $x_fg,
        );
        $button[$idx]->pack( -side => 'left' );
    }
}    # end of sub create_specific_Xterm_buttons

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# FRAMES:
#    Create 7 frames:
#
#    3 for Entry() items -- colors, sizes, font
#    1 for log creation checkbutton
#    1 for font selection button
#    1 for custom xterm button, and
#    1 for the Quit button:
#
sub define_frames {
    @frames = qw[colors sizes font font_button log custom_button quit_button];

    foreach $frame_type (@frames) {
        $frame{$frame_type} = $top->Frame()->pack(
            -side => "top",
            -fill => "y",
        );

        $frame{$frame_type}->configure(
            -borderwidth => 5,
            -background  => 'black',
        );
    }
}    # end of sub define_frames

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# ENTRIES:
#    Define lablels and entries for
#        1.  colors (foreground and background)
#        2.  sizes (columns and rows)
#
sub define_entries {

    #--------------------------------------------------
    # "Foreground" Label and Entry:
    #--------------------------------------------------
    $Label{'foreground'} = $frame{'colors'}->Label(
        -text        => 'Foreground',
        -padx        => 5,
        -borderwidth => 3,
        -relief      => 'sunken',
        -bg          => darkGrey,
    );

    $Label{'foreground'}->pack( -side => 'left' );

    $Entry{'foreground'} = $frame{'colors'}->Entry(
        -font         => $x_fa,
        -bg           => 'tan',
        -fg           => 'black',
        -width        => 10,
        -textvariable => \$x_fg,
    );

    $Entry{'foreground'}->pack(
        -side  => 'left',
        -after => $Label{'foreground'}
    );

    #--------------------------------------------------

    #--------------------------------------------------
    # "Background" Label and Entry:
    #--------------------------------------------------
    $Label{'background'} = $frame{'colors'}->Label(
        -text        => 'Background',
        -padx        => 5,
        -borderwidth => 3,
        -relief      => 'sunken',
        -bg          => darkGrey,
    );

    $Label{'background'}->pack( -side => 'left' );

    $Entry{'background'} = $frame{'colors'}->Entry(
        -font         => $x_fa,
        -bg           => 'tan',
        -fg           => 'black',
        -width        => 10,
        -textvariable => \$x_bg,
    );

    $Entry{'background'}->pack(
        -side  => 'left',
        -after => $Label{'background'}
    );

    #--------------------------------------------------

    #--------------------------------------------------
    # "Columns" Label and Entry:
    #--------------------------------------------------
    $Label{'columns'} = $frame{'sizes'}->Label(
        -text        => 'Columns',
        -padx        => 5,
        -borderwidth => 3,
        -relief      => 'sunken',
        -bg          => darkGrey,
    );

    $Label{'columns'}->pack( -side => 'left', );

    $Entry{'columns'} = $frame{'sizes'}->Entry(
        -font         => $x_fa,
        -bg           => 'tan',
        -fg           => 'black',
        -width        => 3,
        -textvariable => \$x_cols,
    );

    $Entry{'columns'}->pack(
        -side  => 'left',
        -after => $Label{'columns'},
    );

    #--------------------------------------------------

    #--------------------------------------------------
    # "Rows" Label and Entry:
    #--------------------------------------------------
    $Label{'rows'} = $frame{'sizes'}->Label(
        -text        => 'Rows',
        -padx        => 5,
        -borderwidth => 3,
        -relief      => 'sunken',
        -bg          => darkGrey,
    );

    $Label{'rows'}->pack( -side => 'left', );

    $Entry{'rows'} = $frame{'sizes'}->Entry(
        -font         => $x_fa,
        -bg           => 'tan',
        -fg           => 'black',
        -width        => 3,
        -textvariable => \$x_rows,
    );

    $Entry{'rows'}->pack(
        -side  => 'left',
        -after => $Label{'rows'},
    );

    #--------------------------------------------------

    #--------------------------------------------------
    # "Font" Label and Entry:
    #--------------------------------------------------
    $Label{'font'} = $frame{'font'}->Label(
        -text        => 'Font',
        -padx        => 5,
        -borderwidth => 3,
        -relief      => 'sunken',
        -bg          => darkGrey,
    );

    $Label{'font'}->pack( -side => 'left', );

    $Entry{'font'} = $frame{'font'}->Entry(
        -font         => $x_fa,
        -bg           => 'tan',
        -fg           => 'black',
        -width        => 40,
        -textvariable => \$x_fa,
    );

    $Entry{'font'}->pack(
        -side  => 'left',
        -after => $Label{'font'},
    );

    #--------------------------------------------------

    # "Font Size" Label and Entry:
    #--------------------------------------------------
    # "Font Size" Label and Entry:
    #--------------------------------------------------
    $Label{'font_size'} = $frame{'sizes'}->Label(
        -text        => 'Font Size',
        -padx        => 5,
        -borderwidth => 3,
        -relief      => 'sunken',
        -bg          => 'DarkGrey',
    );

    $Label{'font_size'}->pack( -side => 'left' );

    $Entry{'font_size'} = $frame{'sizes'}->Entry(
        -font         => $x_fa,
        -bg           => 'tan',
        -fg           => 'black',
        -width        => 3,
        -textvariable => \$x_fs,
    );

    $Entry{'font_size'}->pack(
        -side  => 'left',
        -after => $Label{'font_size'},
    );

    #--------------------------------------------------

    #--------------------------------------------------

}    # end of sub define_entries

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# FOCUS:
#    Each Entry widget is focusable.  Initially focus on $Entry{'foreground'}
#    and then move thru all Entry widgets, returning to the initial focus.
#    The focussing keyboard action is '<Return>'.  Leave the default behavior
#    of TAB as it.  That is, TAB moves the focus to all button and entry
#    widgets:
#
sub define_focus_bindings {
    $Entry{'foreground'}->focus;
    $Entry{'foreground'}
        ->bind( '<Return>', sub { $Entry{'background'}->focus } );
    $Entry{'background'}->bind( '<Return>', sub { $Entry{'columns'}->focus } );
    $Entry{'columns'}->bind( '<Return>', sub { $Entry{'rows'}->focus } );
    $Entry{'rows'}->bind( '<Return>', sub { $Entry{'font'}->focus } );
    $Entry{'font'}->bind( '<Return>', sub { $Entry{'foreground'}->focus } );
    $Entry{'font_size'}->bind( '<Return>', sub { $Entry{'font_size'}->focus } );
}    # end of sub define_focus_bindings

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
sub define_customized_Xterm_button {
    my $button = $frame{'custom_button'}->Button(
        -text        => "Create Customized Xterm",
        -command     => [ \&Xterm_button ],
        -borderwidth => 5,
        -background  => $x_bg,
        -foreground  => $x_fg,
    );
    $button->pack();
}    # end of sub define_customized_Xterm_button

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
sub Xterm_button {

    # Get the Entry() values into Perl variables
    $x_fg   = $Entry{'foreground'}->get;
    $x_bg   = $Entry{'background'}->get;
    $x_cols = $Entry{'columns'}->get;
    $x_rows = $Entry{'rows'}->get;
    $x_fs   = $Entry{'font_size'}->get;

    # Create an xterm window:
    Xterm( $x_bg, $x_fg );
}    # end of sub Xterm_button

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
sub define_quit_button {
    my $button = $frame{'quit_button'}->Button(
        -text        => "Quit",
        -command     => 'exit',
        -borderwidth => 5,
        -background  => 'grey',
        -foreground  => 'DarkRed',
    );
    $button->pack();
}    # end of sub define_quit_button

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
sub define_font_button {
    $font_button = $frame{'font_button'}->Button(
        -text        => "Font Selection",
        -command     => [ \&fonts_manager ],
        -borderwidth => 5,
        -background  => 'LightSteelBlue',
        -foreground  => 'Navy',
    );
    $font_button->pack();
}    # end of sub define_font_button

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
sub fonts_manager {
    $font_button->configure(
        -text  => 'Picking Fonts...',
        -state => 'disabled',
    );

    # Remember the font value in case user hits Cancel button:
    $x_fa_reset = $x_fa;

    # get_fonts() will load @fonts with the results of the xlsfonts command
    (@fonts) = get_fonts();

    if ( $#fonts == 0 ) {
        $err_msg = "No results for xlsfonts found.";

        # Create a special window for an Error Message Button:
        $ErrMsgWindow = MainWindow->new();
        $ErrMsgWindow->title('ERROR: xlsfonts');

        $errButton = $ErrMsgWindow->Button(
            -background  => 'grey',
            -foreground  => 'DarkRed',
            -borderwidth => 5,
            -relief      => 'raised',
            -text        => $err_msg,
            -command     => [ \&destroy_ErrMsgWindow ],
        )->pack();

        return;    # if $err_msg, don't go on. $x_fa remains as is
    }

    define_fonts_listBox();
}    # end of sub fonts_manager

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
sub define_fonts_listBox {

    # Create a special window for a Scrolled Listbox:
    $ListBoxWindow = MainWindow->new();
    $ListBoxWindow->title(
        "FONT SELECTION:    Double-click Left Mouse Button in Top Panel");

    # Create a Scrolled ListBox widget in the new ListBoxWindow:
    $font_list = $ListBoxWindow->Scrolled(
        'Listbox',
        -borderwidth => 5,
        -width       => 90,
        -height      => 14,
        -background  => 'LightSteelBlue',
        -foreground  => 'Navy',
        -relief      => 'sunken',
    )->pack();

    # Be sure that the index for see() and activate(), $xlsfont_idx is a legal
    # numeric value.  It is taken from %xlsfonts_idx hash, if possible, or set
    # to 0 if not:
    my $xlsfont_idx = 0;
    $xlsfont_idx = $xlsfonts_idx{$x_fa_reset}
        if ( defined( $xlsfonts_idx{$x_fa_reset} )
        && $xlsfonts_idx{$x_fa_reset} =~ /\d+/ );

    # Populate the Listbox with the results of xlsfonts:
    $font_list->insert( 'end', @fonts );
    $font_list->see($xlsfont_idx);
    $font_list->activate($xlsfont_idx);
    $font_list->focus();

    # Allow the user to scroll around and pick a font,
    # by double click left mouse
    $font_list->bind( '<Double-1>', \&pick_font );

    define_font_label($x_fa_reset);

    $font_ok_button = $ListBoxWindow->Button(
        -background  => 'grey',
        -foreground  => 'DarkGreen',
        -borderwidth => 5,
        -relief      => 'raised',
        -text        => 'OK',
        -command     => [ \&destroy_ListBoxWindow ],
    );
    $font_ok_button->pack( -side => 'left', );

    $font_cancel_button = $ListBoxWindow->Button(
        -background  => 'grey',
        -foreground  => 'DarkRed',
        -borderwidth => 5,
        -relief      => 'raised',
        -text        => 'Cancel',
        -command     => sub {
            $x_fa = $x_fa_reset;
            destroy_ListBoxWindow();
        },
    );
    $font_cancel_button->pack( -side => 'right' );
}    # end of sub define_fonts_listBox

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
sub destroy_ListBoxWindow {
    $ListBoxWindow->destroy();
    $font_button->configure(
        -text  => 'Font Selection',
        -state => 'normal',
    );
}    # end of sub destroy_ListBoxWindow

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
sub get_fonts {
    my @xlsfonts = ();
    my %xlsfonts_idx = ();

    my $idx = 0;

    my $cmd = "sort -u $ENV{'HOME'}/Documents/font_list.txt";
    open(my $FONTS, "-|", $cmd) or return $xlsfonts[0];

    while (my $line = <$FONTS>) {
        chomp($line);
        next if $line =~ /^#/;
        # Relace white space with dash;
        $line =~ s/\s/-/g;
        push(@xlsfonts, $line);
        $xlsfonts_idx{$line} = $idx++;
    }

    print "DEBUG: cmd=$cmd\n"
        if ($debug);

    close $FONTS;

    return @xlsfonts;
} # end of get_fonts()
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
sub define_font_label {
    my ($font)     = @_;
    my $label_text = "This is a FONT Sample 0123456789 (.<>!#%^&*-_)";
    my $width      = length($label_text) + 2;
    $font_label = $ListBoxWindow->Label(
        -borderwidth => 5,
        -width       => $width,
        -height      => 3,
        -background  => 'LightSteelBlue',
        -foreground  => 'DarkGreen',
        -relief      => 'sunken',
        -font        => $font,
        -text        => $label_text,
    );
    $font_label->pack();
}    # end of sub define_font_label {

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
sub pick_font {
    my $font = $font_list->get('active');

    return
        if ( !$font );    # Return if no list item is active

    $font_label->destroy();
    define_font_label($font);

    # Set Global to local:
    $x_fa = $font;
}    # end of sub pick_font

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
sub destroy_ErrMsgWindow {
    $errButton->destroy();
    $ErrMsgWindow->destroy();
}    # end of sub destroy_ErrMsgWindow

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
sub define_log_checkbutton {
    $log_checkbutton = $frame{'log'}->Checkbutton(
        -padx     => 3,
        -pady     => 3,
        -relief   => 'sunken',
        -text     => 'Enable XtermLog.* creation',
        -variable => \$x_log,
    );
    $log_checkbutton->pack();
}    # end of sub define_log_checkbutton

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Remove all space from string and return it.
sub trim {
    my $string = shift;
    $string =~ s/\s+//g;
    return $string;
}

#-------------------------------------------------------------------------------

