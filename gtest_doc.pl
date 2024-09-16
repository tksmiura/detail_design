#!/usr/bin/perl
# MIT License
# Copyright (c) 2024 TAKESHI MIURA
use utf8;
use feature 'unicode_strings';
use Encode;
use Getopt::Long;
use Data::Dumper;
use Excel::Writer::XLSX;

binmode STDIN,  ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

GetOptions('markdown' => \$opt_markdown, 'debug' => \$opt_debug);


sub output_test {
    my ($doxygen_header, $class, $func, $detail) = @_;
    my @precond=(), @check=(), @run=();
    foreach $d (split("\n", $detail)) {
        if ($d =~ /前提条件:\s*(.*)/) {
            my $c = $1;
            push @precond, $c;
        } elsif ($d =~ /確認項目:\s*(.*)/) {
            my $c = $1;
            push @check, $c;
        } elsif ($d =~ /実施内容:\s*(.*)/) {
            my $c = $1;
            push @run, $c;
        } else {
            print "ERROR: $infile: $.: $1\n";
        }
    }
    if ($opt_markdown) {
        print OUT "\n## $class:$func\n\n";

        print OUT "$doxygen_header\n\n";

        print OUT "### 前提条件\n\n";
        foreach my $d (@precond) {
            print OUT "   * $d\n";
        }

        print OUT "\n### 実施内容\n\n";
        foreach my $d (@run) {
            print OUT "   * $d\n";
        }

        print OUT "\n### 確認項目\n\n";
        foreach my $d (@check) {
            print OUT "   * $d\n";
        }

    } else {
        my $cell;
        $Sheet->write($Sheet_line, 0, "$class:$func");


        $Sheet->write($Sheet_line, 1, "$doxygen_header");
        $cell = "";
        foreach my $d (@precond) {
            $cell .= "* $d\n";
        }
        $Sheet->write($Sheet_line, 2, $cell);
        $cell = "";
        foreach my $d (@run) {
            $cell .= "* $d\n";
        }
        $Sheet->write($Sheet_line, 3, $cell);
        $cell = "";
        foreach my $d (@check) {
            $cell .= "* $d\n";
        }
        $Sheet->write($Sheet_line, 4, $cell);

        $Sheet_line++;
    }
}

sub output_spec {
    my ($doxygen_header, $function_decl, $detail) = @_;

    $opt_debug && print "---\n$doxygen_header\n---\n";
    $opt_debug && print "===\n$function_decl\n===\n";
    $opt_debug && print "***\n$detail\n***\n";

    if ($doxygen_header =~ /\@file\s*([^\s]*)/) {
        my $file = $1;
        my $brief;
        my $doxygen_details;
        if ($doxygen_header =~ /\@brief\s*(.*)/) {
            $brief = $1;
        }
        if ($doxygen_header =~ /\@details\s*(.*)/) {
            $doxygen_details = $1;
        }

        $opt_debug && print "FILE HEADER $file\nBRIEF $brief\nDETAILS $doxygen_details\n";
    } elsif ($function_decl =~ /TEST_F\s*\(\s*(.*),\s*(.*)\)/) {
        my $test_class = $1;
        my $test_func = $2;
        $opt_debug && print "TEST $1 $2\n";
        &output_test($doxygen_header, $test_class, $test_func, $detail);

    }

}

if (! $opt_markdown) {
    $Book = Excel::Writer::XLSX->new("unit_test.xlsx");
}

foreach $infile (@ARGV) {              #各ファイルごと
    my $line;
    my $detail = "";
    my $function_decl = "";
    my $doxygen_header = "";

    open FILE, '<:encoding(UTF-8)', $infile || die "Can't open to $infile";

    if ($opt_markdown) {
        open OUT, '>:encoding(UTF-8)', $infile . ".md" || die "Can't open to $infile.md";
    } else {
        $Sheet = $Book->add_worksheet("$infile");
        $Sheet->write(0, 0, "ID");
        $Sheet->write(0, 1, "概要");
        $Sheet->write(0, 2, "前提条件");
        $Sheet->write(0, 3, "実施内容");
        $Sheet->write(0, 4, "確認項目");
        $Sheet_line = 1;
    }

    while ($line = <FILE>) {
        chop $line;
        if ($line =~ /(\s*)\/\*-\s*(.*)/) {     # detail design /*-
            my $indent = $1;
            my $doc = $2;
            if ($doc =~/(.*)\*\//) {
                $doc = $1;
                $doc =~ s/\s+$//;
            } else {
                my $cont_line = <FILE>;
                while ($cont_line !~ /(.*)\*\//) {     # loop for */
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
            $detail .= "$doc\n";
        } elsif ($line =~  /(\s*)\/\*\*\s*(.*)/) {     # doxygen comment
            my $dox = $2;
            if ($dox =~ /^</) {                        # ignore /**<
                next;
            }

            # output previous data
            &output_spec($doxygen_header, $function_decl, $detail);
            $doxygen_header = "";
            $function_decl = "";
            $detail = "";

            while ($dox !~ /(.*)\*\//) {
                $cont_line = <FILE>;
                $cont_line || last;
                $cont_line =~ /\s*(\*[^\/])?\s*(.*)/;
                $dox .= "\n$2";
            }
            $dox =~ s/\*\/\s*//;
            #$opt_debug && print "($dox)\n";
            $doxygen_header = $dox;

            # get code after Doxygen commmet
            $line = <FILE>;
            $line || last;

            if ($line =~ /^\s*$/ ||
                $line =~ /^\s/) {
                next;
            }
            $function_decl = "";
            while ($line !~ /[;{]/ && $line !~ /^\s*$/) {
                $function_decl .= $line;
                $line = <FILE>;
                $line || last;
            }
            $function_decl .= $line;
            if ($function_decl =~ /^\s*struct/||
                $function_decl =~ /^\s*typedef\s+struct/) {   # if struct, continue blank line
                $line = <FILE>;
                $line || last;
                while ($line !~ /^\s*$/) {
                    $function_decl .= $line;
                    $line = <FILE>;
                    $line || last;
                }
            }
        }
    }
    close(FILE);

    &output_spec($doxygen_header, $function_decl, $detail);
    $doxygen_header = "";
    $function_decl = "";
    $detail = "";
    if ($opt_markdown) {
        close(OUT);
    }
}
if (! $opt_markdown) {
    $Book->close();
}
