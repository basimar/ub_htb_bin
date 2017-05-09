#!/usr/bin/perl
use strict;
use Getopt::Long;
use File::Basename;

my $PROG=File::Basename::basename($0);
sub usage {
    print STDERR<<EOD;
$PROG - 26.07.2010 (c) andres.vonarx\@unibas.ch

usage:  perl $PROG [options]

Reads in an Aleph sequential file and outputs all records where the content
of a certain MARC field and subfield matches a given regular expression.

options:
 --help             show this text and quit
 --version          show version information and quit
 --input=filename   Aleph sequential input file (default: stdin)
 --output=filename  Aleph sequential output file (default: stdout)
 --marctag=string   where to look for: MARC field[+indicator] [subfield]
 --regex=regex      what to look for (regular expression)
 --[no]ignorecase   ignore case in pattern matching (default:ignorecase)

example:
 \$ perl $PROG --in=dsv05.seq --out=gosteli.seq --marc='852 b' --regex='Gosteli' --noignorecase

EOD
    exit;
}

my $help;
my $infile  = '-';
my $outfile = '-';
my $marctag = '';
my $filter  = '';
my $regex   = '';
my $ignorecase = 1;

GetOptions(
    'help'      => \$help,
    'version'   => \$help,
    'input=s'   => \$infile,
    'output=s'  => \$outfile,
    'marctag=s' => \$marctag,
    'regex=s'   => \$regex,
    'ignorecase!' => \$ignorecase,
    ) or usage;


($help) and usage;
($infile)  or usage;
($outfile) or usage;
($marctag) or usage;
($regex) or usage;

# -- Where to search: extract MARC field and subfield
$_ = $marctag;
my ( $Field, $SubField ) = split;

# -- What to search: generate and validate regular expression
if ( $ignorecase ) {
    eval { $regex = qr/$regex/i } ;
    ( $@ ) and die "$PROG: bad regular expression: $regex\n";
} else {
    eval { $regex = qr/$regex/ } ;
    ( $@ ) and die "$PROG: bad regular expression: $regex\n";
}

open(IN, "<$infile") or die("cannot read $infile: $!");
open(OUT, ">$outfile") or die("cannot write $outfile: $!");
my $prev_sysno=0;
my $Rec='';
my $ok=0;
while ( <IN> ) {
    my($sysno)= /^(\d+)/;
    if ( $sysno ne $prev_sysno ) {
        checkrec();
        $prev_sysno=$sysno;
    }
    $Rec .= $_;
}
checkrec();
close IN;
close OUT;

sub checkrec {
    ( $Rec ) or return;
    my $ok=0;
    local $_;
    my @a = split(/\n/, $Rec);
    while ( @a ) {
        $_ = shift @a;
        s/^\d+ (.....)...//;
        my $tag = trim($1);
        if ( $tag eq $Field ) {
            if ( $SubField ) {
                s|^.*\$\$$SubField||;
                s|\$\$.*$||;
            }
            if ( m/$regex/ ) {
                print OUT $Rec;
                last;
            }
        }
    }
    $Rec='';
}

sub trim {
    local $_ = shift;
    s/^\s+//;
    s/\s+$//;
    $_;
}
