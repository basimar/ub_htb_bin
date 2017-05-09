#!/usr/bin/perl

# replace non-unicode chars
#
# usage: perl fix_aleph_xml_charset.pl < infile > outfile
#
# history
# rev 24.08.2010/ava

use strict;
open(IN,"-") or die $!;
while ( <IN> ) {
    # control chars
    s/[\x00-\x09\x0b\x0c\x0e\x0f]/ /g;

    # pseudo-utf8 chars (relics of Windows CP 1252)
    # cf. http://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP1252.TXT
    #
    s/\xC2\x80/\xE2\x82\xAC/g;  # EURO SIGN
    s/\xC2\x81/\x20/g;          # UNDEFINED
    s/\xC2\x82/\xE2\x80\x9A/g;  # SINGLE LOW-9 QUOTATION MARK
    s/\xC2\x83/\xC6\x92/g;      # LATIN SMALL LETTER F WITH HOOK
    s/\xC2\x84/\xE2\x80\x9E/g;  # DOUBLE LOW-9 QUOTATION MARK
    s/\xC2\x85/\xE2\x80\xA6/g;  # HORIZONTAL ELLIPSIS
    s/\xC2\x86/\xE2\x80\xA0/g;  # DAGGER
    s/\xC2\x87/\xE2\x80\xA1/g;  # DOUBLE DAGGER
    s/\xC2\x88/\xCB\x86/g;      # MODIFIER LETTER CIRCUMFLEX ACCENT
    s/\xC2\x89/\xE2\x80\xB0/g;  # PER MILLE SIGN
    s/\xC2\x8A/\xC5\xA0/g;      # LATIN CAPITAL LETTER S WITH CARON
    s/\xC2\x8B/\xE2\x80\xB9/g;  # SINGLE LEFT-POINTING ANGLE QUOTATION MARK
    s/\xC2\x8C/\xC5\x92/g;      # LATIN CAPITAL LIGATURE OE
    s/\xC2\x8D/\x20/g;          # UNDEFINED
    s/\xC2\x8E/\xC5\xBD/g;      # LATIN CAPITAL LETTER Z WITH CARON
    s/\xC2\x8F/\x20/g;          # UNDEFINED
    s/\xC2\x90/\x20/g;          # UNDEFINED
    s/\xC2\x91/\xE2\x80\x98/g;  # LEFT SINGLE QUOTATION MARK
    s/\xC2\x92/\xE2\x80\x99/g;  # RIGHT SINGLE QUOTATION MARK
    s/\xC2\x93/\xE2\x80\x9C/g;  # LEFT DOUBLE QUOTATION MARK
    s/\xC2\x94/\xE2\x80\x9D/g;  # RIGHT DOUBLE QUOTATION MARK
    s/\xC2\x95/\xE2\x80\xA2/g;  # BULLET
    s/\xC2\x96/\xE2\x80\x93/g;  # EN DASH
    s/\xC2\x97/\xE2\x80\x94/g;  # EM DASH
    s/\xC2\x98/\xCB\x9C/g;      # SMALL TILDE
    s/\xC2\x99/\xE2\x84\xA2/g;  # TRADE MARK SIGN
    s/\xC2\x9A/\xC5\xA1/g;      # LATIN SMALL LETTER S WITH CARON
    s/\xC2\x9B/\xE2\x80\xBA/g;  # SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
    s/\xC2\x9C/\xC5\x93/g;      # LATIN SMALL LIGATURE OE
    s/\xC2\x9D/\x20/g;          # UNDEFINED
    s/\xC2\x9E/\xC5\xBE/g;      # LATIN SMALL LETTER Z WITH CARON
    s/\xC2\x9F/\xC5\xB8/g;      # LATIN CAPITAL LETTER Y WITH DIAERESIS
    print $_;
}
close IN;
