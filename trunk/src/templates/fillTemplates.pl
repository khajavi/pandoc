#!/usr/bin/env perl
# fills templates in templates directory with haskell-escaped strings
# slurped from input files

use strict;
use warnings;

# Utility routines:

sub slurp {
    open FILE, $_[0] or die "couldn't open file '$_[0]': $!";
    my $contents = do { local $/; <FILE>;};
    close FILE;
    return $contents;
}

sub escape_for_haskell {
    my ($contents) = @_;

    $contents =~ s/\\/\\\\/g;
    $contents =~ s/\t/\\t/g;
    $contents =~ s/"/\\"/g;
    $contents =~ s/\n/\\n/g;
    return $contents;
}

# Template processors.

my %processor = (
    # --------------------------------------------------------------------------
    'Text/Pandoc/Writers/S5.hs' => {
    # --------------------------------------------------------------------------
	proc     => sub {
	    my ($template) = @_;

	    my $slides  = escape_for_haskell(slurp "ui/default/slides.js"); 
	    my $s5core  = escape_for_haskell(slurp "ui/default/s5-core.css");
	    my $framing = escape_for_haskell(slurp "ui/default/framing.css");
	    my $pretty  = escape_for_haskell(slurp "ui/default/pretty.css");
	    my $opera   = escape_for_haskell(slurp "ui/default/opera.css");
	    my $outline = escape_for_haskell(slurp "ui/default/outline.css");
	    my $print   = escape_for_haskell(slurp "ui/default/print.css");

	    $template =~ s/<slides\.js>/$slides/;
	    $template =~ s/<s5-core\.css>/$s5core/;
	    $template =~ s/<framing\.css>/$framing/;
	    $template =~ s/<pretty\.css>/$pretty/;
	    $template =~ s/<opera\.css>/$opera/;
	    $template =~ s/<outline\.css>/$outline/;
	    $template =~ s/<print\.css>/$print/;

	    return $template;
	},
    },
    # --------------------------------------------------------------------------
    'Text/Pandoc/ASCIIMathML.hs' => {
    # --------------------------------------------------------------------------
	proc     => sub {
	    my ($template) = @_;

	    my $script = escape_for_haskell(slurp "ASCIIMathML.js"); 
	    my $acknowledgements =
		" ASCIIMathML.js - copyright Peter Jipsen,".
		" released under the GPL\\nSee ".
		"http://www1.chapman.edu/~jipsen/mathml/asciimath.html/ ";
	    $script =~ s/\/\*.*?\*\//\/\*$acknowledgements\*\//g; # strip comments
	    $template =~ s/<ASCIIMathML\.js>/$script/;

	    return $template;
	},
    },
    # --------------------------------------------------------------------------
    'Text/Pandoc/Writers/DefaultHeaders.hs' => {
    # --------------------------------------------------------------------------
	proc     => sub {
	    my ($template) = @_;

	    my $html  = escape_for_haskell(slurp "headers/HtmlHeader");
	    my $latex = escape_for_haskell(slurp "headers/LaTeXHeader");
	    my $rtf   = escape_for_haskell(slurp "headers/RTFHeader");
	    my $s5    = escape_for_haskell(slurp "headers/S5Header");

	    $template =~ s/<HtmlHeader>/$html/;
	    $template =~ s/<LaTeXHeader>/$latex/;
	    $template =~ s/<RTFHeader>/$rtf/;
	    $template =~ s/<S5Header>/$s5/;
	    
	    return $template;
	},
    },
    # --------------------------------------------------------------------------
    # 'foo/bar/baz' => {
    # --------------------------------------------------------------------------
    #    template => 'optional-template-filename-defaults-to-baz'
    #    proc     => sub {
    # 	    my ($template) = @_;
    # 	    # Process.
    # 	    return $template;
    #    },
    #},
);

# Main.

my $target = shift @ARGV;
if (!defined $target || !length $target) {
	print STDERR "Available targets:\n\n" . join "\n", keys %processor;
	die "\n\nYou must supply a target!\n";
}

die "No processor exists for '$target'!\n" if ! exists $processor{$target};

my $rootdir = shift @ARGV || '..';
chdir $rootdir or die "Couldn't chdir to '$rootdir': $!";

my $template;
if (exists $processor{$target}->{template}) {
   $template = $processor{$target}->{template};
}
else {
    ($template = $target) =~ s!.*/+!!;
}
$template = "templates/$template";
die "No template exists for '$target'!\n" if ! -f "$template";

open OUTFILE, ">$target" or die "couldn't open file '$target': $!";
print OUTFILE <<END;
----------------------------------------------------
-- Do not edit this file by hand.  Edit 
-- '$template'
-- and run $0 $target
----------------------------------------------------

END

print OUTFILE $processor{$target}->{proc}->(slurp($template));
print OUTFILE "\n";
close OUTFILE;
