#!/usr/bin/perl
# MIT License
# Copyright (c) 2024 TAKESHI MIURA
use utf8;
use feature 'unicode_strings';
use Encode;
use Getopt::Long;
use Data::Dumper;

binmode STDIN,  ":utf8";
binmode STDOUT, ":utf8";

#options
# -m -markdown
GetOptions('markdown' => \$opt_markdown, 'debug' => \$opt_debug);


foreach $infile (@ARGV) {
    my $line;
    my $previous_indent = 0;
    my $level = 0;
    open FILE, '<:encoding(UTF-8)', $infile || die "Can't open to $infile";
    while ($line = <FILE>) {
        chop $line;
        if ($line =~ /(\s*)\/\*-\s*(.*)/) {     # detail design
            my $indent = $1;
            my $doc = $2;
            if ($doc =~/(.*)\*\//) {
                $doc = $1;
                $doc =~ s/\s+$//;
            } else {
                my $cont_line = <FILE>;
                while ($cont_line !~ /(.*)\*\//) {
                    if ($cont_line =~ /\s*\*\s*(.*)/) {
                        $doc .= $1;
                        $doc =~ s/\s+$//;
                    } else {
                        $cont_line =~ /\s*(.*)/;
                        $doc .= $1;
                        $doc =~ s/\s+$//;
                    }
                    $cont_line = <FILE>;
                }
                $cont_line =~ /(.*)\*\//;
                $cont_line = $1;
                $cont_line =~ /\s*\*?\s*(.*)/;
                $doc .= $1;
                $doc =~ s/\s+$//;
            }

            my $i = &indent_width($indent);
            if ($previous_indent == 0 || $previous_indent == $i) {
                # same level
            } elsif ($previous_indent < $i) {
                $level++;
            } else {
                $level--;
            }
            $previous_indent = $i;
            $doc = ("\t" x $level) . $doc;
            $opt_debug && print "[$doc]\n";

        } elsif ($line =~  /(\s*)\/\*\*\s*(.*)/) {     # doxygen header
            my $dox = $2;
            while ($dox !~ /(.*)\*\//) {
                $cont_line = <FILE>;
                $cont_line || last;
                $cont_line =~ /\s*(\*[^\/])?\s*(.*)/;
                $dox .= "\n$2";
            }
            $dox =~ s/\*\/\s*//;
            $opt_debug && print "($dox)\n";
            $line = <FILE>;
            $line || last;

            if ($line =~ /^\s*$/ ||
                $line =~ /^\s/) {
                next;
            }
            $function_decl = "";
            while ($line !~ /[;{]/) {
                $function_decl .= $line;
                $line = <FILE>;
                $line || last;
            }
            $function_decl .= $line;

            $opt_debug && print "{$function_decl}\n";
        }

    }

    close FILE;
}

$tab_width = 8;

sub indent_width {
    my ($pad) = @_;
    my $i = 0;

    foreach $c (split(//, $pad)) {
        if ($c == " ") {
            $i++;
        } elsif ($c == "\t") {
            $i += $tab_width;
        }
    }
    return $i;
}
