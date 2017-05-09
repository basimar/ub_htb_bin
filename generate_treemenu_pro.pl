#!/usr/bin/perl

use Getopt::Long;
use strict;

my $BOM = "\xEF\xBB\xBF";   # UTF-8 Byte Order Mark.
(my $Prog = $0 ) =~ s/^.*\///;

sub usage {
    print STDERR <<EOD;
usage: $Prog [options]

options:
--in   <file>   input (text file)
--out  <file>   output (TigraTree Pro JavaScript menu file). default: stdout
--top  <text>   text for top node. default: 'top node'
--link <text>   format of item links. default: 'javascript:bib(\\'%s\\');'
--var  <text>   name of javascript tree variable. default: 'TREE_ITEMS'
--help          print this text and exit

EOD
    exit;
}

my $Help;
my $InFile   = '';
my $OutFile  = '-';
my $TopText  = 'top node';
my $LinkForm = qq|'javascript:bib(\\'%s\\');'|;
my $VarName  = 'TREE_ITEMS';
my $ZeroLink = qq|''|;

GetOptions(
    'in=s'   => \$InFile,
    'out=s'  => \$OutFile,
    'top=s'  => \$TopText,
    'link=s' => \$LinkForm,
    'var=s'  => \$VarName,
    'help'   => \$Help,
    ) or usage;
( $Help ) and usage;
( $InFile ) or usage;
( @ARGV ) and usage;

open(IN,"<$InFile") or die("cannot read $InFile: $!");
my(@in,@out);

my($lastlevel,$errcode,$n);
while ( <IN> ) {
    chomp;
    $n++;
    ( $. == 1 ) and s/^$BOM//;
    next if ( /^#/ );
    next if ( /^\s*$/ );
    my $level = ( s/^(\s+)// ) ? length($1)+1 : 1;
    if ( $level > ($lastlevel+1) ) {
        $errcode=1;
        print STDERR "$0: Fehler in Eingabedatei, Zeile $n: fehlerhafte Einrückung\n  $_\n";
    }
    $lastlevel=$level;
    s/\'/\\\'/g;
    my $linkdata = '';
    if ( s/\s*\>\s*(.+)$// ) {
        $linkdata = trim($1);
    }
    push(@in,qq|$level¬$_¬$linkdata|);
}
close IN;
( $errcode ) and die("$0: Programm abgebrochen.\n");

my $date = localtime(time);
$TopText =~ s/\'/\\\'/;
open(OUT,">$OutFile") or die("cannot write $OutFile: $!");
print OUT <<EOD;
/*
data for Tigra Tree Menu PRO
generated: $date by $Prog
*/

var $VarName = [['$TopText',$ZeroLink,0,
EOD

my $lastlevel;
for ( my $i=0 ; $i <= $#in ; $i++ ) {
    $_ = $in[$i];
    my ($level,$text,$linkdata)=split/¬/;
    $lastlevel=$level;

    # format link
    my $link = ( $linkdata ) ? sprintf($LinkForm, $linkdata) : $ZeroLink;

    # print indented content
    print OUT "\t" x $level .qq|['$text',$link|;

    # look ahead for next level
    my $nextlevel;
    if ( $i == $#in ) {
        print OUT qq|]\n|;
        while ( $level-- > 1 ) {
            print OUT "\t" x $level .qq|]\n|;
        }
        print OUT qq|]];\n|;
        last;
    } else {
        $nextlevel = $in[$i+1];
        $nextlevel =~ s/¬.*$//;
    }

    # close open arrays if necessary
    if ( $level < $nextlevel ) {
        print OUT qq|,0,\n|;
    }
    elsif ( $level == $nextlevel ) {
        print OUT qq|],\n|;
    }
    elsif ( $level > $nextlevel ) {
        print OUT qq|]\n|;
        while ( $level-- > $nextlevel+1 ) {
            print OUT "\t" x $level .qq|]\n|;
        }
        print OUT "\t" x $level .qq|],\n|;
    }
}

sub trim {
    local $_ = shift || return undef;
    s/^\s+//;
    s/\s+$//;
    $_;
}
=head1 NAME

generate_treemenu_pro.pl - generiere JS-Code fuer TreeMenu Pro

=head1 SYNOPSIS

generate_treemenu_pro.pl [options]

 options:
 --in   <file>   input (text file)
 --out  <file>   output (TigraTree Pro JavaScript menu file). default: stdout
 --top  <text>   text for top node. default: 'top node'
 --link <text>   format of item links. default: 'javascript:bib(\'%s\');'
 --var  <text>   name of javascript tree variable. default: 'TREE_ITEMS'
 --help          print this text and exit

=head1 DESCRIPTION

=head2 Input File Format

The input file is a text file (charset: UTF-8). B<comments> start with a '#'.
Empty lines are treated as comments. The B<hierarchy> of the items is represented
by indenting the display text of all subordinated items by one space character
for each level of subordination. After the display text, some
optional B<link> data may follow. Display text and link data must be separated
by a &gt; character and some optional white space.

Example:

 Energie- und Wasserwirtschaft
  Energiewirtschaft  > H + I Bi 1
  Energiewirtschaft Ausland
   Deutschland  > H + I Bi 1001
   Frankreich  > H + I Bi 1101

=head2 Output File Format

See the Tigra Tree Menu documentation. Each item is an array whithin an array

  Tigra Tree Menu
   0   Caption
   1   Link
   2+  Sub items

  Tigra Tree Menu Pro
   0   Caption
   1   Link
   2   Geometry
   3+  Sub items

=head1 AUTHOR

andres.vonarx@unibas.ch

=head1 HISTORY

  2.00  31.05.2010 - still experimental
  2.01  29.07.2010 - prog dies on badly formatted input files

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Basel University Library, Switzerland.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

See the documentation of Tigra Tree Menu Pro: http://www.softcomplex.com/products/tigra_tree_menu/

=cut

