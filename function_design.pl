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
binmode STDERR, ":utf8";

$tab_width = 8;

#options
# -m -markdown
GetOptions('markdown' => \$opt_markdown, 'debug' => \$opt_debug);



foreach $infile (@ARGV) {              #各ファイルごと
    my $line;
    my $level = 0;
    my @level_indent =();
    my $level_offset = 0;
    my $next_level_offset = 0;
    my $detail = "";
    my $function_decl = "";
    my $doxygen_header = "";

    open FILE, '<:encoding(UTF-8)', $infile || die "Can't open to $infile";

    if ($opt_markdown) {
        open OUT, '>:encoding(UTF-8)', $infile . ".md" || die "Can't open to $infile.md";
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

            if ($doc =~ /^\>/) {
                $next_level_offset = 1;
                $doc =~ s/^\>\s*//;
            } elsif ($doc =~ /^\<\>/) {
                $level_offset--;
                $next_level_offset = 1;
                $doc =~ s/^\<\>\s*//;
            } elsif ($doc =~ /^\</) {
                $next_level_offset = -1;
                $doc =~ s/^\<\s*//;
            }
            my $i = &indent_width($indent);
            if (@level_indent > 0) {
                if ($i > $level_indent[$#level_indent]) {
                    push @level_indent, $i;
                } else {
                    while ($i < $level_indent[$#level_indent]) {
                        pop @level_indent;
                    };
                }
            } else {
                push @level_indent, $i;
            }
            $level = $#level_indent + $level_offset;
            if ($level < 0) {
                print STDERR "$infile: $.: level error $line\n";
                $level = 0;
            }
            if ($doc !~ /^\s*$/)  {
                $doc = ("\t" x $level) . $doc;
                $opt_debug && print "$i $level [$doc]\n";
                $detail .= "$doc\n";
            }
            $level_offset += $next_level_offset;
            $next_level_offset = 0;
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
            $level_offset = 0;
            @level_indent =();

            while ($dox !~ /(.*)\*\//) {
                $cont_line = <FILE>;
                $cont_line || last;
                $cont_line =~ /\s*(\*[^\/])?\s*(.*)/;
                $dox .= "\n$2";
            }
            $dox =~ s/\*\/\s*//;
            $opt_debug && print "($dox)\n";
            $doxygen_header = $dox;

            # get code after Doxygen commmet
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

            $opt_debug && print "{$function_decl}\n";
        }

    }
    &output_spec($doxygen_header, $function_decl, $detail);
    $doxygen_header = "";
    $function_decl = "";
    $detail = "";
    $level_offset = 0;
    @level_indent =();

    if ($opt_markdown) {
        close OUT;
    }
    close FILE;
}

sub indent_width {
    my ($pad) = @_;
    my $i = 0;

    foreach $c (split(//, $pad)) {
        if ($c eq " ") {
            $i++;
        } elsif ($c eq "\t") {
            $i += $tab_width;
        }
    }
    return $i;
}

sub output_doxygen_function {
    my ($header, $function_decl) = @_;
    my ($brief, @param, $return, @retval, $details);
    my $section;
    foreach $section (split("@", $header)) {
        if ($section =~ /^param\s*(.*)/) {
            push @param, $1;
        } elsif($section =~ /^return\s*(.*)/s) {
            $return = $1;
        } elsif($section =~ /^retval\s*(.*)/) {
            push @retval, $1;
        } elsif($section =~ /^details\s*(.*)/s) {
            $details .= $1;
        } elsif($section =~ /^brief\s*(.*)/s) {
            $brief .= $1;
        } else {
            if ($brief) {
                $details .= $section;
            } else {
                $brief = $section;
            }
        }
    }

    $opt_debug && print "brief [$brief]\n";
    $opt_debug && print "param [@param]\n";
    $opt_debug && print "return [$return]\n";
    $opt_debug && print "retval [@retval]\n";
    $opt_debug && print "details [$details]\n";

    $function_decl =~ /(\w+)\s*\(/;
    my $func_name = $1;
    $opt_debug && print "function [$func_name]\n";

    print OUT "## 関数 $func_name()\n\n$brief\n";

    if ($function_decl) {
        $function_decl =~ s/\s*\{$//s;

        print OUT "### 関数定義\n\n";
        print OUT "```c\n";
        print OUT "$function_decl";
        print OUT "```\n\n"
    }

    if (@param) {
        print OUT "### 引数\n\n";
        print OUT "| in/out  | 引数名 | 説明 |\n";
        print OUT "| ------- | ------ | ---- |\n";
        foreach my $p (@param) {
            my $inout = "";
            if ($p =~ s/\[(.*)\]//) {
                $inout = $1;
            }
            if ($p =~ /([^:]*):(.*)/) {
                print OUT "| $inout | $1 | $2 |\n"
            } else {
                print OUT "| $inout | | $p |\n"
            }
        }
        print OUT "\n";
    }
    if ($return) {
        print OUT "### 戻値\n\n$return\n\n";
    }
    if (@retval) {
        print OUT "### 戻値の一覧\n\n";
        print OUT "| 値      | 説明 |\n";
        print OUT "|  ------ | ---- |\n";
        foreach my $p (@retval) {
            my ($v, $d) = split(":", $p);
            print OUT "| $v | $d |\n"
        }
        print OUT "\n";
    }
    if ($details) {
        print OUT "### 詳細説明\n\n$details\n\n";
    }
}

sub output_file {
    my ($header) = @_;
    my ($brief, $file, $details);
    my $section;
    $opt_debug && print "output_file [$header]\n";
    foreach $section (split("@", $header)) {
        if ($section =~ /^file\s*(.*)/) {
            $file = $1;
        } elsif($section =~ /^brief\s*(.*)/) {
            $brief = $1;
        } elsif($section =~ /^details\s*(.*)/s) {
            $details .= $1;
        } else {
            if ($brief) {
                $details .= $section;
            } else {
                $brief = $section;
            }
        }
    }

    $opt_debug && print "file [$file]\n";
    $opt_debug && print "brief [$brief]\n";
    $opt_debug && print "details [$details]\n";
    if ($brief) {
        print OUT "# $brief\n\n file: $file\n";
    } else {
        print OUT "# $file\n\n";
    }
    if ($details) {
        print OUT "\n$details\n\n";
    }
}

sub output_struct {
    my ($doxygen_header, $function_decl) = @_;
    $opt_debug && print "output_struct [$function_decl]\n";

    $doxygen_header =~ s/^\s*//;
    $doxygen_header =~ s/\s*$//;

    my $name = "";
    my @member =();
    foreach $d (split("\n", $function_decl)) {
        if ($d =~/^\s*struct\s*([^\s]*)/) {
            $name = $1;
            $opt_debug && print "struct $name\n";

        } elsif ($d =~ /^\s*(.*)\/\*\*<\s*(.*)\*\// ) {
            my $decl = $1;
            my $desc = $2;
            $decl =~ s/\s*$//;
            $opt_debug && print "  $decl : $desc\n";
            push @member, "| $decl | $desc |";
        }
    }

    print OUT "## $name 構造体 \n\n$doxygen_header\n\n";
    $function_decl =~ s/\/\*\*<.*\*\///g;

    print OUT "```\n";
    print OUT "$function_decl\n";
    print OUT "```\n\n";

    print OUT "| メンバー   | 説明 |\n";
    print OUT "| ---------- | ---- |\n";

    foreach my $m (@member) {
        print OUT "$m\n";
    }

}

sub output_spec {
    my ($doxygen_header, $function_decl, $detail) = @_;

    if (!$doxygen_header && !$detail) {
        return;
    }
    $opt_debug && print "output_spec [$function_decl]\n";

    if ($doxygen_header =~ /\@file/) {
        &output_file($doxygen_header);
    } elsif ($function_decl =~ /^\s*struct/) {      # 構造体
        &output_struct($doxygen_header, $function_decl);
    } elsif ($function_decl =~ /^\s*typedef\s+struct/) {      # 構造体型
        &output_struct($doxygen_header, $function_decl);
    } elsif ($function_decl =~ /^\s*typedef/) {     # 型定義
    } elsif ($function_decl =~ /\{$/) {          # 関数詳細
        &output_doxygen_function($doxygen_header, $function_decl);
        if ($detail) {
            print OUT "### 実装仕様\n\n";
            foreach $d (split("\n", $detail)) {
                $d =~ s/(\s*)(.*)/$1* $2/;
                print OUT "$d\n"
            }
            print OUT "$d\n"
        }
    } else {                                      # グローバル変数

    }
}
