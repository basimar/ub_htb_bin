#!/usr/bin/perl

=for doku

Input:
    hierarchie.xml
        Hierarchie-Datei, wie sie z.B. von htb_build_hierarchy_top_down
        erstellt wird.
    marc.xml
        Bibliographische Daten

Output:
    hierarchie-full.xml
        Hierarchie-Datei, angereichert mit bibliographischen Daten,
        die von tigra_tree_menu_full.xsl verarbeitet werden kann.

Version:
    21.11.2014/ava
    10.02.2015/bmt - Adaption für polyhierarchische Hierarchien (mehrere 490-Felder)
    25.04.2015/bmt - Feld 773 (Brief-Verknüpfungen) wird mit berücksichtigt, falls vorhanden
                   - Falls Argument $autor == Y: Reihenfolge 240/245 vertauscht, Autor (245$$c wird zum Titel hinzugefügt).


Beschreibung:
    Das Skript liest erst die hierarchie.xml Datei ins Memory ein.
    Danach liest sie sequentiell eine marc.xml Datei und extrahiert
    record-per-record bibliographische Information: Autor (100/700/710),
    Titel (240/245), Anzeigeform der Zählung (490$v/773$g). Diese Information
    wird als <data>-Element in die records der hierarchie.xml Datei
    eingefügt. Toplevel Records werden dabei nicht verändert.

Kommentar:

Die Idee hinter dem htb-Tool "tigra_tree_menu.xsl" war folgende:

1. Es wird eine einfache XML-Datei erstellt, die praktisch nur die 
hierarchische Struktur von bibliographischen Aufnahmen enthält plus
ihre Systemnummern.

2. Ein XSL-Programm nimmt diese Hierarchie-XML und holt aus einer
zusätzlichen MARC.xml Datei die bibliographischen Informationen, um
z.B. ein Javascript-Menu für Tigra Tree zu erstellen.

Das funktioniert mit kleinen Datenmengen recht gut, aber schon mit 
mittleren Mengen ist das überhaupt nicht mehr performant. Die richtige 
Lösung ist, die Hierarchie.xml bereits mit allen benötigten 
bibliographischen Daten anzureichern, und dann das htb-Tool 
"tigra_tree_menu_full.xsl" zu verwenden.

Bei den UB-Nachlässen haben wir die Anreicherungen über einen reichlich
schrägen Mechanismus realisiert, bei der jeder verwendete MARC-Record
in eine eigene Datei geschrieben wurde.

Hier machen wir die Anreicherungen der hierarchie.xml in Memory. Das
ist recht performant, hat aber wohl auch irgendwo eine Limite, was die
Anzahl Records betrifft...


CAVEAT
Die Extraktion von Autor und Titel ist sehr elementar gehalten...



=cut

use strict;
use Getopt::Long;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21' );
use MARC::Record;

sub usage {
    print<<EOD;
usage: $0 [options]

options
--infile     input: Hierarchie-XML
--marcfile   MARC.xml Datei
--outfile    output: Hierarchie-XML mit angereicherten <data>
EOD
    exit;
}
my($infile,$outfile,$marcfile,$author);
GetOptions (
    "infile=s"      => \$infile,
    "outfile=s"     => \$outfile,
    "marcfile=s"     => \$marcfile,
    "author=s"         => \$author,
    ) or usage;
( $infile ) or usage;
( $marcfile ) or usage;
$outfile ||= '-';

binmode(STDOUT,'utf8');
binmode(STDERR,'utf8');

# -- slurp hierarchy.xml into memory
my $INFILE;
open(IN,"<:utf8", $infile) 
    or die("cannot read $infile: $!");
{ local $/; $INFILE = <IN>; }
close IN;

open(OUT,">:utf8", $outfile)
    or die("cannot write $outfile: $!");

# -- loop over each MARC record and enrich hierarchy.xml

my $marc = MARC::File::XML->in( $marcfile );
while ( my $rec = $marc->next() ) {

    # -- Systemnummer (001)
    my $recno = $rec->field('001')->data;
    
    # -- Titel
 
    my $titel='';	

    if ($author == "Y") {
        my $f=$rec->field('245') || $rec->field('240');
        if ( $f ) {
            if ( $f->subfield('c')) {
                $titel=safexml($f->subfield('a') . " / " . $f->subfield('c'));
            }
            else {
                $titel=safexml($f->subfield('a'));
            }
        }
    }
    else {
        my $f=$rec->field('240') || $rec->field('245');
        if ( $f ) {
            $titel=safexml($f->subfield('a'));
        }
    }


    
    # -- Anzeigeform Zaehlung (490 $v) 
    
    # load field 490 into an array and check of more than one 490 field is present. If yes, execute a foreach loop and handle each field separatly.
    my @f=$rec->field('490');
    if (@f > 1) {
		foreach (@f) {
			my $zaehlung='';
			my $numzaehlung='';
			$zaehlung=safexml($_->subfield('v'));
			$numzaehlung=safexml($_->subfield('i'));
			my $data = qq|<data><numbering>$zaehlung</numbering><title>$titel</title></data>|;
			$INFILE =~ s|(\" recno=\"$recno\"><data>$numzaehlung<\/data>)|\" recno=\"$recno\">$data|gm;
		};
	}
	else {
		my $zaehlung='';
		my $f=$rec->field('490');			
		if ( $f ) {
			$zaehlung=safexml($f->subfield('v'));
		};
		my $data = qq|<data><numbering>$zaehlung</numbering><title>$titel</title></data>|;
		$INFILE =~ s|(level=\"[^1]\" recno=\"$recno\">).*?$|$1$data|gm;
	}
	
	
	# -- Anzeigeform Zaehlung (773 $g) 
    
    # load field 773 into an array and check of more than one 773 field is present. If yes, execute a foreach loop and handle each field separatly.
    
    if ($rec->field('773')) {
        @f=$rec->field('773');
		if (@f > 1) {
			foreach (@f) {
				my $zaehlung='';
				my $numzaehlung='';
				$zaehlung=safexml($_->subfield('g'));
				$numzaehlung=safexml($_->subfield('j'));
				my $data = qq|<data><numbering>$zaehlung</numbering><title>$titel</title></data>|;
				$INFILE =~ s|(\" recno=\"$recno\"><data>$numzaehlung<\/data>)|\" recno=\"$recno\">$data|gm;
			};
		}
		elsif (@f = 1) {
			my $zaehlung='';
			my $f=$rec->field('773');			
			if ( $f ) {
				$zaehlung=safexml($f->subfield('g'));
			};
			my $data = qq|<data><numbering>$zaehlung</numbering><title>$titel</title></data>|;
			$INFILE =~ s|(level=\"[^1]\" recno=\"$recno\">).*?$|$1$data|gm;
		};
	};	
}
$marc->close();
print OUT $INFILE;
close OUT;

sub safexml {
    local $_=shift;
    s|&|&amp;|g;
    s|<|&lt;|g;
    s|>|&gt;|g;
    s|"|&quot;|g;
    s|'|&apos;|g;
    $_;
}
