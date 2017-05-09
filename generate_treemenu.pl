#!/usr/bin/perl

use Getopt::Long;
use strict;

my $BOM = "\xEF\xBB\xBF";   # UTF-8 Byte Order Mark.
my $Prog = `basename "$0"`;

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

my $level;
my $prevlevel = 0;

open(IN,"<$InFile") or die("cannot read $InFile: $!");
open(OUT,">$OutFile") or die("cannot write $OutFile: $!");

my $date = localtime(time);
$TopText =~ s/\'/\\\'/;
print OUT qq|// Data for TreeMenu PRO generated: $date\n|,
    qq|// $Prog\n|,
    qq|var $VarName = [['$TopText',''\n|;

while ( <IN> ) {
    chomp;
    next if ( /^#/ );
    next if ( /^\s*$/ );
    ( $. == 1 ) and s/^$BOM//;
    $level = ( s/^(\s+)// ) ? length($1)+1 : 1;
    s/\s*\>\s*(.+)$//;
    my $linkdata = trim($1);
    $linkdata =~ s/\'/\\\'/g;

    # format link
    my $link = ( $linkdata ) ? sprintf($LinkForm, $linkdata) : qq|''|;

    # close open levels
    if ( $level > $prevlevel ) {
        print OUT qq|,\n|;
    }
    elsif ( $level == $prevlevel ) {
        print OUT qq|],\n|;
    }
    else {
        print OUT qq|],\n|;
        while ( $prevlevel-- > $level ) {
            print OUT "\t" x $prevlevel;
            print OUT qq|],\n|;
        }
    }
    $prevlevel = $level;

    # safe characters
    s/\'/\\\'/g;

    # indent
    print OUT "\t" x $level;
    print OUT qq|['|, $_, qq|',|, $link;
}
# close last open levels
print OUT qq|]\n|;
while ( $level-- ) {
    print OUT "\n\t" x $level;
    print OUT qq|]|;
}
print OUT qq|];\n|;

sub trim {
    local $_ = shift || return undef;
    s/^\s+//;
    s/\s+$//;
    $_;
}
