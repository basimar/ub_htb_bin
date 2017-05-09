package HierarchyToolbox;

use strict;
no warnings "uninitialized";
use Carp;
use LWP::Simple;
use URI::Escape;
use ava::sort::utf8;

our $VERSION = '2.02';
our $DEBUG = 0;
our %HTB_NUMBERS;

@HierarchyToolbox::ISA = "Exporter";
@HierarchyToolbox::EXPORT = qw(
    alephseq_extract_490
    alephseq_record_to_xml
    alephx_store_set
    build_hierarchy_bottom_up
    convert_alephseq_to_marcxml
    convert_alephseq_to_multiple_marcxml
    escape_xml
    $ALEPH_RECNO_FORMAT
);

our $def_marc_rec_type  = 'Bibliographic';      # MARC record type
our $def_marc_org_code  = 'SzZuIDS BS/BE';      # MARC field 003 content
our $def_aleph_ignore   = [ 'CAT' ];            # Aleph BIB fields which should *not* be conversed to MARC
our $def_x_service_host = 'aleph.unibas.ch';    # Aleph X-Service server
our $def_x_service_chunk= 99;                   # max chunksize for Aleph X-Service 'present' request
our $def_aleph_bib_lib  = 'dsv01';              # Aleph BIB library
our $ALEPH_RECNO_FORMAT = '%9.9d';              # format of Aleph record numbers (with leading zeroes)

# --------------------
sub convert_alephseq_to_marcxml {
# --------------------
    local(*IN,*OUT);
    my %arg=@_;
    $arg{infile}  ||= '-';
    $arg{outfile} ||= '-';
    $arg{filter}  ||= sub {1;};
    ( ref($arg{filter}) eq 'CODE' )
        or croak "parameter 'filter' must be code reference";
    my ($recbuf,$recno,$last_recno,$xml);
    if ( $arg{numberlist} ) {
        read_numberlist($arg{numberlist});
        $arg{filter}=\&numberlist_filter;
    }
    open(IN,    "<$arg{infile}")    or croak "cannot read $arg{infile}: $!";
    open(OUT,   ">$arg{outfile}")   or croak "cannot write $arg{outfile}: $!";
    print OUT marc_xml_header();
    while ( <IN> ) {
        chomp;
        s/^(\d+) //;
        $recno=$1;
        if ( $recno ne $last_recno ) {
            print OUT alephseq_record_to_xml($last_recno,$recbuf,\%arg);
            $last_recno=$recno;
            $recbuf=();
        }
        push(@$recbuf,$_);
    }
    close IN;
    print OUT alephseq_record_to_xml($recno,$recbuf,\%arg);
    print OUT qq|</collection>\n|;
    close OUT;
}

# --------------------
sub convert_alephseq_to_multiple_marcxml {
# --------------------
    my %arg=@_;
    local *IN;
    $arg{infile}  ||= '-';
    $arg{filter}  ||= sub {1;};
    ( ref($arg{filter}) eq 'CODE' )
        or croak "parameter 'filter' must be code reference";
    my ($recbuf,$recno,$last_recno,$xml);
    if ( $arg{numberlist} ) {
        read_numberlist($arg{numberlist});
        $arg{filter}=\&numberlist_filter;
    }
    open(IN, "<$arg{infile}") or croak "cannot read $arg{infile}: $!";
    while ( <IN> ) {
        chomp;
        s/^(\d+) //;
        $recno=$1;
        if ( $recno ne $last_recno ) {
            print_alephseq_record_to_marcxml($last_recno,$recbuf,\%arg);
            $last_recno=$recno;
            $recbuf=();
        }
        push(@$recbuf,$_);
    }
    close IN;
    print_alephseq_record_to_marcxml($recno,$recbuf,\%arg);
}

sub print_alephseq_record_to_marcxml {
    my($recno,$recbuf,$arg)=@_;
    my $xml=alephseq_record_to_xml($recno,$recbuf,$arg) || return undef;
    $arg->{outfile_format} || croak("missing parameter: outfile_format");
    my $outfile=sprintf($arg->{outfile_format}, $recno);
    ( $arg->{verbose} ) and print $outfile, "\n";
    local *OUT;
    open(OUT,">$outfile") or croak("cannot write $outfile: $!");
    print OUT marc_xml_header(), $xml, qq|</collection>|;
    close OUT;
}

sub read_numberlist {
    my $file = shift;
    local($_,*IN);
    open(IN,"<$file") or croak("cannot read $file: $!");
    while ( <IN> ) {
        chomp;
        my($sysno) = split /\t/;
        $sysno += 0;
        $HTB_NUMBERS{$sysno}=1;
    }
    close IN;
}

sub numberlist_filter {
    defined $HTB_NUMBERS{$_[0]+0};
}

# --------------------
sub alephseq_record_to_xml {
# --------------------
    my($recno,$buf,$arg)=@_;
    ( $buf ) or return undef;
    if ( $arg->{filter} ) {
        if ( ! &{$arg->{filter}}($recno,$buf) ) {
            return undef;
        }
    }
    local $_;
    my %ignore   = map{$_=>1} ( $arg->{ignore} ? @{$arg->{ignore}} : @$def_aleph_ignore );
    my $org_code = $arg->{orgcode} || $def_marc_org_code;
    my $rec_type = $arg->{rectype} || $def_marc_rec_type;
    my($ret,$leader,$control,$data,$local);
    while ( @$buf ) {
        $_=shift @$buf;
        my $tag=substr($_,0,3);
        next if ( $ignore{$tag} );

        # field indicators
        my $i1=lc(substr($_,3,1));
        my $i2=lc(substr($_,4,1));
        $i1 =~ s/[^a-z0-9 ]/ /;
        $i2 =~ s/[^a-z0-9 ]/ /;

        # field content
        my $content = escape_xml(substr($_,8));

        # parse and order fields
        if ( $tag eq 'LDR' ) {
            # leader, recordnumber (001), organization code (003)
            $content =~ s|[^a-zA-Z 0-9]| |g;
            $leader=qq|<leader>$content</leader>\n|;
            unless ( $arg->{no_001} ) {
                $leader .= qq|<controlfield tag="001">$recno</controlfield>\n|;
            }
            unless ( $arg->{no_003} ) {
                $leader .= qq|<controlfield tag="003">$org_code</controlfield>\n|;
            }
        }
        elsif ( $tag =~ /^00\d/ ) {
            # standard control fields 001-009
            $control.=qq|<controlfield tag="$tag">$content</controlfield>\n|;
        }
        elsif ( $content =~ s/^\$\$// ) {
            # standard data fields
            $data.=qq|<datafield tag="$tag" ind1="$i1" ind2="$i2">\n|;
            my @tmp = split(/\$\$/,$content);
            while ( @tmp ) {
                $_=shift @tmp;
                my $subf_code;
                if ( s/^([a-zA-Z0-9])// ) {
                    $subf_code=$1;
                } else {
                    $subf_code= '?';
                }
                $data.=qq| <subfield code="$subf_code">$_</subfield>\n|;
            }
            $data.=qq|</datafield>\n|;
        }
        else {
            # 'local' extensions to MARC
            $local.= qq|<datafield tag="$tag" ind1="$i1" ind2="$i2">\n|
                .qq| <subfield code="a">$content</subfield>\n</datafield>\n|;
        }
    }
    qq|<record type="$rec_type">\n| .$leader .$control .$data .$local .qq|</record>\n|;
}

# --------------------
sub marc_xml_header {
# --------------------
    qq|<?xml version="1.0" encoding="utf-8"?>\n|
    .qq|<collection xmlns="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"\n|
    .qq|xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">\n|;
}
# --------------------
sub escape_xml {
# --------------------
    local $_ = shift || return undef;
    s/&/&amp;/g;
    s/</&lt;/g;
    s/>/&gt;/g;
    s/\"/&quot;/g;
    s/\'/&apos;/g;
    $_;
}

# --------------------
sub make_sort_string {
# --------------------
    local $_ = shift || return undef;
    s/<<[^>]*>>\s*//g;     # non-sorting-Aleph
    $_=utf8sort_lc($_);
    s/(\d+)/sprintf("%6.6d",$1)/eg;
    s/^\s+//;
    s/\s$//;
    s/ \s+/ /g;
    $_;
}

# --------------------
sub alephx_store_set {
# --------------------
    my %arg=@_;
    my $ccl=$arg{ccl}       || croak 'missing CCL';
    my $file=$arg{outfile}  || croak 'missing filename';
    my $host=$arg{host}     || $def_x_service_host;
    my $chunksize=$arg{chunksize}   || $def_x_service_chunk;
    my $alephlib=$arg{alephlib}     || $def_aleph_bib_lib ;
    ( $arg{debug} ) and $DEBUG=1;

    local($_,*OUT);

    # -- find --
    my $url = 'http://' .$host .'/X?op=find&base=' .$alephlib .'&request=' .uri_escape($ccl);
    dprint("ALEPH-X find: $url");
    $_=LWP::Simple::get($url);
    unless ( $_ ) {
        return alephx_store_set_error('cannot connect to Aleph server');
    }
    if ( (my $err) = m|<error>(.*)</error>| ) {
        return alephx_store_set_error($err);
    }
    ( my $setNo ) = m|<set_number>(\d+)</set_number>|;
    ( my $nRec )  = m|<no_records>(\d+)</no_records>|;
    $nRec=int($nRec);
    dprint("ALEPH-X retrieving $nRec records:");

    # -- present
    open(OUT,">:utf8", $file)
        or return alephx_store_set_error("cannot write $file: $!");
    print OUT qq|<?xml version = "1.0" encoding = "UTF-8"?>\n<alephset number_of_records="$nRec">\n|;
    my $first=1;
    while ( $first <= $nRec ) {
        my $last = $first + $chunksize;
        if ( $last > $nRec ) {
            $last = $nRec;
        }
        my $setEntry = $first == $last ? sprintf($ALEPH_RECNO_FORMAT,$first) : sprintf("$ALEPH_RECNO_FORMAT-$ALEPH_RECNO_FORMAT",$first,$last);
        $first += $chunksize + 1;
        $url= 'http://' .$host .'/X?op=present&set_entry=' .$setEntry .'&set_number=' .$setNo .'&base=' .$alephlib;
        dprint("ALEPH-X present: $url");
        $_=LWP::Simple::get($url);
        unless ( $url ) {
            close OUT;
            unlink $file;
            return alephx_store_set_error('cannot connect to Aleph server');
        }
        if ( (my $err) = m|<error>(.*)</error>| ) {
            close OUT;
            unlink $file;
            return alephx_store_set_error($err);
        }
        s/^.*\n.*\n//;     # skip XML declaration and start root element
        s|<session.*$||s;  # skip session element and end root element
        s|[\x00-\x08]||g;  # remove illegal XML characters, see POD note
        s|[\x0b-\x0c]||g;
        s|[\x0e-\x1f]||g;
        print OUT $_;
    }
    print OUT qq|</alephset>\n|;
    close OUT;
    dprint("ALEPH-X store to: $file\n");
    return undef;
}

sub alephx_store_set_error {
    'Aleph X-Services error: ' .$_[0] ."\n";
}

sub dprint {
    if ( $DEBUG ) { print STDERR @_, "\n"; }
}

# --------------------
sub alephseq_extract_490 {
# --------------------
    my %arg=@_;
    local($_,*IN,*OUT);
    $arg{infile}  ||= '-';
    $arg{outfile} ||= '-';

    open(IN,"<$arg{infile}") or croak "cannot read $arg{infile}: $!";
    open(OUT,">$arg{outfile}") or die "cannot write $arg{outfile}: $!";

    print OUT "recno\tuplink\tsortform\n";
    while ( <IN> ) {
        if ( s/^(\d+) 490   L // ) {
            chomp;
            my $tmp;
            $tmp->{sysno} = $1;
            my @tmp = split /\$\$/;
            while ( @tmp ) {
                $_=shift @tmp;
                s/^(.)//;
                my $sub = $1;
                if ( $sub eq 'w' ) {
                    $tmp->{uplink} = sprintf($ALEPH_RECNO_FORMAT,$_);
                }
                elsif ( $sub eq 'i' ) {
                    $tmp->{sortform} = $_;
                }
            }
            if ( defined $tmp->{uplink} ) {
                print OUT $tmp->{sysno}, "\t", $tmp->{uplink}, "\t", $tmp->{sortform}, "\n";
            }
        }
    }
    close OUT;
}

# --------------------
package alephxnode;
# --------------------
use strict;

# create a new node
sub new {
    my $class=shift;
    my $self={};
    bless($self,$class);
    $self->{id}=shift;
    $self->{parent}=shift;
    $self->{sort}=shift;
    $self->{data}=shift;
    $self;
}
# add a child to a parent node
sub append {
    my $self=shift;
    my $node=shift;
    $self->{child}->{$node->{id}}=$node;
}
# move children from one node to another
sub relink {
    my $self=shift;
    my $relink=shift;
    foreach my $child_id ( keys %{$relink->{child}} ) {
        $self->append($relink->{child}->{$child_id});
        delete $relink->{child}->{$child_id};
    }
}
# print a node and its children recursively as XML elements
sub serialize {
    my $self=shift;
    my $level=shift || 0;
    if ( $level ) {
        print ' ' x $level, qq|<rec level="$level" recno="$self->{id}">|;
        if ( $self->{data} ) {
            print qq|<data>|, $self->{data}, qq|</data>|;
        }
        print "\n";
    }
    if ( $self->{child} ) {
        foreach my $child_id ( sort { $self->{child}->{$a}->{sort} cmp $self->{child}->{$b}->{sort} } keys %{$self->{child}} ) {
            $self->{child}->{$child_id}->serialize($level+1);
        }
    }
    if ( $level ) {
        print ' ' x $level, qq|</rec>\n|;
    }
}
# -- end package alephxnode
# --------------------
package alephxtree;
# --------------------
use strict;
use Carp;

$alephxtree::VERSION = '1.00';
our $ROOTKEY='root';

# create a new tree with a root node
sub new {
    my $class = shift;
    my %arg = @_;
    my $self = {};
    bless( $self, $class );
    $self->{root}=new alephxnode($ROOTKEY,undef,undef);
    $self->{outfile} = $arg{outfile} || '-';
    $self->{mode} = $arg{mode} || 'bottom-up';
    $self;
}
# add a new node to the tree
sub add {
    my $self=shift;
    my($id,$parent_id,$sort,$data)=@_;
    $parent_id ||= $ROOTKEY;
    my $node = new alephxnode($id,$parent_id,$sort,$data);

    # for bottom-up lookups:
    # check if the node already exists (as a provisional parent node).
    # if yes, relink its children and delete it.
    if ( $self->{mode} eq 'bottom-up' ) {
        my $pnode = lookup($self->{root},$id);
        if ( defined($pnode) ) {
            $node->relink($pnode);
            my $pnode_parent=lookup($self->{root},$pnode->{parent}) || $self->{root};
            delete $pnode_parent->{child}->{$pnode->{id}};
        }
    }
    # check if the parent node already exists. if yes, append
    # node to it. if no, create a provisional parent node.
    if ( $parent_id and $parent_id ne $ROOTKEY) {
        my $parentnode = lookup($self->{root},$parent_id);
        if ( !$parentnode ) {
            $parentnode = new alephxnode($parent_id,$ROOTKEY,undef);
            $self->{root}->append($parentnode);
        }
        $parentnode->append($node);
    }
    else {
        $self->{root}->append($node);
    }
    $self->{nRec} +=1;
}
# start serializing nodes
sub serialize {
    my $self=shift;
    my $date=localtime();
    local *OUT;
    open(OUT,">$self->{outfile}") or croak "cannot write to $self->{outfile}: $!";
    my $ofh = select OUT;
    print   qq|<?xml version="1.0" encoding="utf-8"?>\n|
           .qq|<tree number_of_records="$self->{nRec}" generated="$date">\n|;
    $self->{root}->serialize;
    print "</tree>\n";
    select $ofh;
}
# recursively traverse the tree and return a node whith a given id
sub lookup {
    my($node,$id)=@_;
    my $ret=undef;
    if ( $node->{child} ) {
        unless ( $ret=$node->{child}->{$id} ) {
            foreach my $chid ( keys %{$node->{child}} ) {
                my $child=$node->{child}->{$chid};
                last if ( $ret=lookup($child,$id) );
            }
        }
    }
    return $ret;
}

# print out internals
sub debug {
    my $self=shift;
    eval { use Data::Dumper };
    $Data::Dumper::Indent=1;
    print Dumper($self->{root});
}
# -- end package alephxtree

1;


__END__

=head1 NAME

HierarchyToolbox - perl tools for handling hierarachies of bibliographic records

=head1 SYNOPSIS

Don't use it. Use the shell scripts instead.

=head1 DESCRIPTION

=head2 Shell scripts

The following shell scripts provide a simple interface to the HierarchyToolbox:

=head3 Retrieving data and converting files

=over

=item htb_alephseq_extract_490

Extract 490 fields from an Aleph sequential file.

 usage: htb_alephseq_extract_490  <input_aleph.seq> [<output_490.txt>]

A shell for L<alephseq_extract_490|item alephseq_extract_490>.

=item htb_alephseq_to_marcxml

Convert Aleph sequential to MARC21 XML.

 usage: htb_alephseq_to_marcxml  <input_aleph.seq> [<output_marc.xml>]

A shell for L<convert_alephseq_to_marcxml|item convert_alephseq_to_marcxml>.

=item htb_alephseq_numberlist_to_marcxml

Reads (1) an Aleph sequential file and (2) a "numberlist", i.e. a text file with
Aleph system numbers. Converts all records listed in "numberlist" into one MARC21 XML file.

 usage:  htb_alephseq_numberlist_to_marcxml [options]

 Reads (1) an Aleph sequential file and (2) a "numberlist", i.e. a text
 file with Aleph system numbers. Converts all records listed in "numberlist"
 into MARC21 XML.

 options:
 --help                 show this text and quit
 --version              show version information and quit
 --alephseq=filename    Aleph sequential input file (mandatory)
 --numberlist=filename  textfile with lines of Aleph system numbers (mandatory)
 --output=filename      XML output file (default: stdout)

Another shell for L<convert_alephseq_to_marcxml|item convert_alephseq_to_marcxml>.

=item htb_alephseq_numberlist_to_multiple_marcxml

Reads (1) an Aleph sequential file and (2) a "numberlist", i.e. a text file with
Aleph system numbers. Converts all records listed in "numberlist" into B<separate>
MARC21 XML files.

 usage:  htb_alephseq_numberlist_to_multiple_marcxml [options]

 Reads an Aleph sequential file and a numberlist (a text file consisting
 of one Aleph system number per line). Converts all records listed in
 numberlist into single MARC21 XML files, named "marc<recno>.xml".

 options:
 --help                 show this text and quit
 --version              show version information and quit
 --alephseq=filename    Aleph sequential input file (mandatory)
 --numberlist=filename  textfile with lines of Aleph system numbers (mandatory)
 --outputdir=directory  XML output file (mandatory)
 --quiet                do not output any messages

A shell for L<convert_alephseq_to_multiple_marcxml|item convert_alephseq_to_multiple_marcxml>

=item htb_alephx_store_set

Retrieve bibliographic records thru Aleph X-Services and store them into
a file. The output format is non-standard XML. It can be converted into
standard MARC21 XML using alephxml_marcxml.xsl.

 usage:  htb_alephx_store_set [options]

 Retrieve bibliographic records thru Aleph X-Services and store them into
 a file. The output format is non-standard XML. It can be converted into
 standard MARC21 XML using alephxml_marcxml.xsl.

 options:
 --help               show this text and quit
 --version            show version information and quit
 --ccl="query"        CCL query     (mandatory)
 --file=filename      output file   (mandatory)
 --host=hostname      Aleph server  (default: aleph.unibas.ch)
 --alephlib=library   Aleph library (default: dsv01)
 --quiet              do not output any messages

 example:
 $ htb_alephx_store_set --ccl='wrd=(zen internet) and wsl=A100' --file=out.xml
 $ saxon out.xml alephxml_marcxml.xsl > marc.xml

A shell for L<alephx_store_set|item alephx_store_set>.

=back

=head3 Building hierarchies

=over

=item htb_build_hierarchy_bottom_up

Suppose you have a set of bibliographic records in MARC XML or Aleph sequential format.
All the set's records are either top level records (=records not linked to any other
records) or child level records (=records containing an up-link to another record).
The records are in no particular order.

To produce an ordered XML hierarchy file representing the hierarchical structure
of the records, you would (1) extract hierarchical information into a text file
using B<marcxml_hierarchy.xsl> (for MARC XML) or L<alephseq_extract_490|item alephseq_extract_490>
(for Aleph sequential) and then (2) call the shell script B<htb_build_hierarchy_bottom_up>.

 $ build_hierarchy_bottom_up  input.txt  output.xml

Sample input:

 recno   uplink  sortform   level_of_description
 46313   46311   1/2        file
 46312   46311   1/1        file

Sample output:

 <?xml version="1.0" encoding="utf-8"?>
 <tree number_of_records="2" generated="Fri Dec 21 11:53:28 2007">
    <rec level="1" recno="000046311">
        <rec level="2" recno="000046312"><data><level_of_description>file</level_of_description></data>
        </rec>
        <rec level="2" recno="000046313"><data><level_of_description>file</level_of_description></data>
        </rec>
    </rec>
 </tree>

=begin html

<table border="1" cellpadding="2" style="border-collapse:collapse;font-size:0.8em;margin-left:1cm;margin-bottom:5mm" width="400">
<colgroup><col width="40"><col width="*"></colgroup>
<tr><td>in</td><td>text TSV (recno, uplink sysno, sortform, level)</td></tr>
<tr><td>out</td><td>Ordered hierarchy XML</td></tr>
</table>

=end html

=item htb_build_hierarchy_top_down

Suppose you have a unordered set of bibliographic data composed of records which may
or may not belong to a hierarchy. You also have a list of the top level
records of the hierarchy which may or may not be in the bibliographic set.

To produce a list of all the records which pertain to the hierarchy, you would (1) extract
490 information into a text file using B<marcxml_hierarchy.xsl> (for MARC XML) or
L<alephseq_extract_490|item alephseq_extract_490> (for Aleph sequential) and then
(2) call the shell script B<htb_build_hierarchy_top_down>.

 $ htb_build_hierarchy_top_down --toplist='top.txt' --list490='all490.txt' --outfile='hierarchy.xml'

Sample input: toplist

 recno    sortform   data
 0001234  aa         some data
 0001235  bb         some more data

Sample input: list490

 recno   uplink  sortform
 3456    1234    aa.1
 3457    1234    aa.2
 3458    2345    cc.1
 3459    2345    cc.2
 3460    1235    bb.1
 3461    1236    bb.2

Sample output

Same format as for L<htb_build_hierarchy_bottom_up|item htb_build_hierarchy_bottom_up>.

=begin html

<table border="1" cellpadding="2" style="border-collapse:collapse;font-size:0.8em;margin-left:1cm;margin-bottom:5mm" width="400">
<colgroup><col width="80"><col width="*"></colgroup>
<tr><td>in (toplist)</td><td>text TSV (recno top level,sortform,data)</td></tr>
<tr><td>in (list490)</td><td>text TSV (recno,uplink,sortform)</td></tr>
<tr><td>out</td><td>text TSV (recno all, level)</td></tr>
</table>

=end html

=back

=head2 Perl interface

=over

=item alephx_store_set (%args)

Connects to an Aleph X-Server, retrieves bibliographic data using CCL, and stores the
result in a valid XML file, in a format not entirely unlike Exlibris Ltd's "OAI XML" format.
Returns undef for success, an error message for error.

 alephx_store_set(
   ccl     => 'wsu=perl',
   outfile => 'oai.xml',
 );

The mandatory hash B<%arg> takes the following keys:

 ccl         CCL search string                            mandatory
 outfile     name of the file where results get stored    mandatory
 host        hostname of Aleph Server                     default: aleph.unibas.ch
 alephlib    Aleph BIB library                            default: dsv01
 debug       if true, prints out X-Service requests       default: false

B<Caveat> In V16 or V18, the Aleph X-Service XML data may be buggy:
(1) Data may contain illegal XML characters, e.g. an erroneously entered C<Ctrl-A>
in a MARC field indicator. The script will remove these characters.
(2) When escaping an ampersand, the Aleph X-Service sometimes adds an extra space
after C<&amp;>. If that matters, for instance in 856 URLs, you must correct that
yourselves.

B<Hint>: use B<alephxml_marcxml.xsl> to convert the resulting XML file into
MARC21 Slim XML.

=begin html

<table border="1" cellpadding="2" style="border-collapse:collapse;font-size:0.8em;margin-left:1cm;margin-bottom:5mm" width="400">
<colgroup><col width="40"><col width="*"></colgroup>
<tr><td>in</td><td>CCL command</td></tr>
<tr><td>out</td><td>Aleph OAI XML</td></tr>
</table>

=end html

=item convert_alephseq_to_marcxml (%args)

Converts an Aleph 500 sequential file into a MARC21 Slim XML file.

 convert_alephseq_to_marcxml(
   infile  => 'aleph.seq',
   outfile => 'marc.xml',
 );

The optional hash B<%args> takes the following keys:

 infile     name of Aleph 500 sequential file    default: stdin
 outfile    name of MARC 21 Slim XML file        default: stdout
 orgcode    MARC 003 organization code           default: "SzZuIDS BS/BE"
 rectype    MARC 21 Slim record type             default: "Bibliographic"
 ignore     arrayref of field tags to ignore     default: ['CAT']
 filter     coderef to a filter callback         default: a sub {} returning true
 numberlist name of numberlist file              default: none
 no_001     do not generate a 001 control field  default: false
 no_003     do not generate a 003 field          default: false

The B<filter> callback serves to select records during conversion and/or to
manipulate input data. The callback function receives one Aleph sequential record
at a time in the form of a reference to an ARRAY of record lines (see below).
If the callback function returns true, the record will be converted to XML.
Otherwise, it will be ignored.

A B<numberlist> is the name of a TSV text file consisting of record numbers in
the first column. Only records present in the numberlist will be converted.

=begin html

<table border="1" cellpadding="2" style="border-collapse:collapse;font-size:0.8em;margin-left:1cm;margin-bottom:5mm" width="400">
<colgroup><col width="40"><col width="*"></colgroup>
<tr><td>in</td><td>Aleph sequential</td></tr>
<tr><td>out</td><td>MARC21 Slim XML</td></tr>
</table>

=end html

=item convert_alephseq_to_multiple_marcxml (%args)

Converts an Aleph 500 sequential file into multiple MARC21 Slim XML files.

 convert_alephseq_to_marcxml(
   infile  => 'aleph.seq',
   outfile_format => 'mydir/marc%s.xml',
 );

For every record, a MARC21 XML file will be genarated, using the B<outfile_format>
parameter to construct its filename. Other B<%args> are the same as in
L<convert_alephseq_to_marcxml|item convert_alephseq_to_marcxml>, notably the
B<filter> argument.

=begin html

<table border="1" cellpadding="2" style="border-collapse:collapse;font-size:0.8em;margin-left:1cm;margin-bottom:5mm" width="400">
<colgroup><col width="40"><col width="*"></colgroup>
<tr><td>in</td><td>Aleph sequential</td></tr>
<tr><td>out</td><td>multiple MARC21 Slim XML</td></tr>
</table>

=end html


=item alephseq_record_to_xml ($recno, $content, $options)

Converts one Aleph sequential record to MARC21 Slim XML. The B<content> is
an ARRAY reference to a list of single lines, with the leading record number removed:

Example:

 $sysno = 4711;
 $content = [
    'FMT   L BK',
    'LDR   L 00000ntm--2200000uu-4500',
    '008   L 991131n--------xx-||||||-||||00||-|ger-d',
    '245   L $$aNachlass 79: Gustav Teichmuller (1832-1888)',
    '909   L $$ax2',
    '830   L $$aTeichmuller, Gustav (1832-1888)',
    '852   L $$aCH$$bBS UB$$cHandschriften$$dNL 79'
 ];
 alephseq_record_to_xml($sysno,$content);

This produces:

 <record type="Bibliographic">
    <leader>00000ntm  2200000uu 4500</leader>
    <controlfield tag="001">4711</controlfield>
    <controlfield tag="003">SzZuIDS BS/BE</controlfield>
    <controlfield tag="008">991131n--------xx-||||||-||||00||-|ger-d</controlfield>
    <datafield tag="245" ind1=" " ind2=" ">
        <subfield code="a">Nachlass 79: Gustav Teichmuller (1832-1888)</subfield>
    </datafield>
    <datafield tag="909" ind1=" " ind2=" ">
        <subfield code="a">x2</subfield>
    </datafield>
    <datafield tag="830" ind1=" " ind2=" ">
        <subfield code="a">Teichmuller, Gustav (1832-1888)</subfield>
    </datafield>
    <datafield tag="852" ind1=" " ind2=" ">
        <subfield code="a">CH</subfield>
        <subfield code="b">BS UB</subfield>
        <subfield code="c">Handschriften</subfield>
        <subfield code="d">NL 79</subfield>
    </datafield>
    <datafield tag="FMT" ind1=" " ind2=" ">
        <subfield code="a">BK</subfield>
    </datafield>
 </record>

The optional hash B<%args> takes the same keys as L<convert_alephseq_to_marcxml|item convert_alephseq_to_marcxml>.

CAUTION: All field indicator A-Z will be converted to lower case. All field indicators other than a-z and 0-9
will be silently converted to blanks. - All subfield codes other than letters a-z, A-Z and digits 0-9 will be replaced by a '?' and the content of the subfield code will be prepended to the subfield content.

=begin html

<table border="1" cellpadding="2" style="border-collapse:collapse;font-size:0.8em;margin-left:1cm;margin-bottom:5mm" width="400">
<colgroup><col width="40"><col width="*"></colgroup>
<tr><td>in</td><td>fragments of Aleph sequential</td></tr>
<tr><td>out</td><td>fragment of MARC21 Slim XML</td></tr>
</table>

=end html

=item alephseq_extract_490 (%args)

Extracts hierarchy information from an Aleph sequential file and prints it out in an unsorted
TSV text file. For all records having a 490 field, it prints out the system number of
the uplink (490 $w), the system number of the current record, and the sortform (490 $i).

 alephseq_extract_490(
   infile => 'aleph.seq',
   outfile => '490.txt',
 );

Sample output:

 recno           sysno           sortform
 000046313       000046311       1/2
 000046312       000046311       1/1

The optional hash B<%args> takes the following keys:

 infile     name of Aleph 500 sequential file   default: stdin
 outfile    name of the text output file        default: stdout

B<Note:> Much more elaborate information can be obtained using B<marcxml_hierarchy.xsl>.

=begin html

<table border="1" cellpadding="2" style="border-collapse:collapse;font-size:0.8em;margin-left:1cm;margin-bottom:5mm" width="400">
<colgroup><col width="40"><col width="*"></colgroup>
<tr><td>in</td><td>Aleph sequential</td></tr>
<tr><td>out</td><td>Text TSV (sysno, uplink_sysno, sortform)</td></tr>
</table>

=end html

=back

=head3 alephxtree: OO interface to the hierarchy tree

=over

=item Overview

With this mechanism, you can collect some fragments of MARC data which contain
linking information (IDS MARC 490 $w). The fragments can be added in any order;
they will be ordered and hierarchized during serialization.

  use HierarchyToolbox;
  my $Tree = alephxtree->new (
    outfile => 'out.xml
  );
  while (...) {
    $Tree->add($recno,$uplink,$sort,$data);
  }
  $Tree->serialize;

=item alephxtree::new (%args)

Creates a tree object. The optional hash B<%args> takes the following keys:

 outfile   output for serialize()    default: stdout

=item alephxtree::add ($recno,$uplink,$sort,$data)

Adds a node to the hierarchy tree. B<recno> is the Aleph record number of the
current item. B<uplink> is the Aleph record number of the parent of this node,
or zero, if it is a top node. B<sort> is some data used for sorting nodes on
the same level.

If B<data> is present, it will be output in a E<lt>dataE<gt> element. It may
contain an XML text node or XML elements, but it is your responsability to
provide correct XML code.

=item alephxtree::serialize

Prints the sorted hierarchy tree in XML format to the I<outfile> which has
been defined when constructing the tree object or I<stdout>.

  $Tree->serialize;

Example output, (assuming that the ISAD-G 'level_of_description' is used as
B<data> parameter when adding nodes to the tree):

 <?xml version="1.0" encoding="utf-8"?>
 <tree number_of_records="201" generated="Fri Apr 21 14:24:24 2006">
  <rec level="1" recno="000048713">
   <data>Fonds</data>
   <rec level="2" recno="000049180">
    <data>Series</data>
    <rec level="3" recno="000049182">
     <data>File</data>
    </rec>
    <rec level="3" recno="000049309">
     <data>File</data>
    </rec>
   </rec>
  </rec>
 </tree>

=item alephxtree::debug

Prints out some internals of the Tree

  $Tree->debug;

=back

=head1 AUTHOR

andres.vonarx@unibas.ch

=head1 HISTORY

  0.01  21.04.2006 - experimental
  1.00  31.12.2007 - even more experimental
  2.02  06.04.2009 - still experimental
  2.03  08.03.2012 - alephx_store_set: open output with ':utf8' property

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2012 by Basel University Library, Switzerland.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut
