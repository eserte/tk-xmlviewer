# -*- perl -*-

#
# $Id: XMLViewer.pm,v 1.22 2000/09/01 21:48:32 eserte Exp $
# Author: Slaven Rezic
#
# Copyright © 2000 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: mailto:eserte@cs.tu-berlin.de
# WWW:  http://www.cs.tu-berlin.de/~eserte/
#

package Tk::XMLViewer;

use Tk 800.013; # -elide
require Tk::ROText;
require Tk::Pixmap;
use strict;
use vars qw($VERSION);

use base qw(Tk::ROText);
use XML::Parser;

Construct Tk::Widget 'XMLViewer';

$VERSION = '0.12';

my($curr_w); # ugly, but probably faster than defining handlers for everything
my $indent_width = 32;

sub SetIndent {
    my $w = shift;
    my $arg = shift;
    $indent_width = $arg;
}

sub InitObject {
    my($w,$args) = @_;
    $w->SUPER::InitObject($args);
    $w->configure(-wrap   => 'word',
		  -cursor => 'left_ptr');
    $w->tagConfigure('xml_tag',
		     -foreground => 'red',
		     #-font => 'boldXXX',
		     );
    $w->tagConfigure('xml_attrkey',
		     -foreground => 'green4',
		     );
    $w->tagConfigure('xml_attrval',
		     -foreground => 'DarkGreen',
		     );
    $w->tagConfigure('xml_comment',
		     -foreground => 'gold2',
		     );
    $w->{IndentTags}  = [];
    $w->{RegionCount} = 0;
    $w->{XmlInfo}     = {};

    # XXX warum parent?
    $w->{PlusImage}  = $w->parent->Pixmap(-id => 'plus');
    $w->{MinusImage} = $w->parent->Pixmap(-id => 'minus');
}

sub insertXML {
    my $w = shift;
    $w->Busy();
    my(%args) = @_;
    my $p1 = new XML::Parser(Style => "Stream",
			     Handlers => {
				 Comment => \&hComment,
				 XMLDecl => \&hDecl,
				 Doctype => \&hDoctype,
			     });
    $w->{Indent} = 0;
    $w->{PendingEnd} = 0;
    $curr_w = $w;
    eval {
	if ($args{-file}) {
	    $p1->parsefile($args{-file});
	    $w->{Source} = ['file', $args{-file}];
	} elsif (exists $args{-text}) {
	    $p1->parse($args{-text});
	    $w->{Source} = ['text', $args{-text}];
	} else {
	    die "-text or -file argument missing";
	}
    };
    if ($@) {
	if ($@ =~ /byte\s+(\d+)/) {
	    my $byte = $1;
	    my $xmlstring; # the erraneauos (sp?) part
	    if ($args{-file}) {
		if (open(F, $args{-file})) {
		   binmode F;
		   seek(F, $byte, 0);
		   local($/) = undef;
		   $xmlstring = <F>;
		   close F;
		}
	    } else {
		$xmlstring = substr($args{-text}, $byte);
	    }
	    $w->tagConfigure("ERROR",
			     -background => '#800000',
			     -foreground => '#ffffff',
			    );
	    $w->see("end");
	    (my $err = $@) =~ s/(byte\s+\d+)\s*at\s*.*line\s*\d+/$1/;
	    $w->insert("end", "ERROR $err", "ERROR",
		       _convert_from_unicode($xmlstring));
	} else {
	    die "Error while parsing XML: $@";
	}
    } else {
	$w->_flush;
    }
    $w->Unbusy();
}

sub hDoctype {
    my $exp = shift;
    foreach my $i (qw(Name Sysid Pubid Internal)) {
	$curr_w->{XmlInfo}{$i} = shift;
    }
}

sub hDecl {
    my $exp = shift;
    foreach my $i (qw(Version Encoding Standalone)) {
	$curr_w->{XmlInfo}{$i} = shift;
    }
}

sub _indenttag {
    my $w = shift;
    my $indent = shift || $w->{Indent};
    if (!defined $w->{IndentTags}[$indent]) {
	$w->tagConfigure("xml_indent$indent",
			 -lmargin1 => $indent*$indent_width,
			 -lmargin2 => $indent*$indent_width,
			);
	$w->{IndentTags}[$indent] = "xml_indent$indent";
    }
    $w->{IndentTags}[$indent];
}

sub _flush {
    my $w = shift;
    if ($w->{PendingEnd}) {
	$w->insert("end", ">", 'xml_tag', "\n");
	$w->{PendingEnd} = 0;
	my $indent = $w->{Indent}-1;
	$w->markSet('regionstart' . $indent, $w->index("end - 1 chars"));
	$w->markGravity('regionstart' . $indent, 'left');
    }
}

sub StartTag {
    $curr_w->_flush;
    my $start = $curr_w->index("end - 1 chars");
    $curr_w->insert("end", "<" . _convert_from_unicode($_[1]), 'xml_tag');
    if (%_) {
	$curr_w->insert("end", " ");
	my $need_space = 0;
	while(my($k,$v) = each %_) {
	    if ($need_space) {
		$curr_w->insert("end", " ");
	    } else {
		$need_space++;
	    }
	    $curr_w->insert("end",
			    _convert_from_unicode($k), "xml_attrkey",
			    "=\"", "",
			    _convert_from_unicode($v), "xml_attrval",
			    "\"", "");
	}
    }
    $curr_w->tagAdd($curr_w->_indenttag, $start, "end");
    $curr_w->{PendingEnd} = 1;
    $curr_w->markSet('tagstart' . $curr_w->{Indent}, $start);
    $curr_w->{Indent}++;
}

sub Text {
    $curr_w->_flush;
    s/^\s+//;
    s/\s+$//;
    if ($_ ne "") {
	$curr_w->insert("end",
			_convert_from_unicode($_) . "\n",
			$curr_w->_indenttag);
    }
}
sub hComment {
    $curr_w->_flush;
    $_ = $_[1];
    s/^\s+//; s/\s+$//;
    if ($_ ne "") {
	my $tag_start = $curr_w->index("end - 1 chars");
	$curr_w->insert("end", "<!-- \n", "xml_comment");
	my $region_start = $curr_w->index("end - 1 chars");
	$curr_w->insert("end", 
			_convert_from_unicode($_) . " -->\n", "xml_comment");
	my $region_end   = $curr_w->index("end");
	my $region_count = $curr_w->{RegionCount};
	$curr_w->tagAdd("region" . $region_count,
			$region_start, $region_end);
	$curr_w->imageCreate("$tag_start",
 			     -image => $curr_w->{'MinusImage'});
	$curr_w->tagAdd("plus" . $region_count,
 			$tag_start);
	my $ww = $curr_w;
	$curr_w->tagBind("plus" . $region_count,
 			 '<1>' => [$ww, 'ShowHideRegion', $region_count]);
	$curr_w->tagBind("plus" . $region_count,
 			 '<Enter>' => sub { $ww->configure(-cursor => 'hand2') });
	$curr_w->tagBind("plus" . $region_count,
 			 '<Leave>' => sub { $ww->configure(-cursor => 'left_ptr') });
	$curr_w->{RegionCount}++;
    }
}

sub EndTag {
    $curr_w->{Indent} --;

    if ($curr_w->{PendingEnd}) {
	$curr_w->insert("end", " />", 'xml_tag', "\n");
	$curr_w->{PendingEnd} = 0;
    } else {
	my $region_start = $curr_w->index('regionstart' . $curr_w->{Indent});
	my $tag_start    = $curr_w->index('tagstart' . $curr_w->{Indent});
	my $region_end   = $curr_w->index("end");
	my $start = $curr_w->index("end - 1 chars");
	$curr_w->insert("end", "</" . _convert_from_unicode($_[1]) .">",
			'xml_tag');
	$curr_w->tagAdd($curr_w->_indenttag, $start, "end");
	my $region_count = $curr_w->{RegionCount};
	$curr_w->tagAdd("region" . $region_count,
			$region_start, $region_end);

 	$curr_w->imageCreate("$tag_start",
 			     -image => $curr_w->{'MinusImage'});
 	$curr_w->tagAdd("plus" . $region_count,	$tag_start);
 	$curr_w->tagAdd($curr_w->_indenttag,	$tag_start);
	my $ww = $curr_w;
 	$curr_w->tagBind("plus" . $region_count,
 			 '<1>' => [$ww, 'ShowHideRegion', $region_count]);
 	$curr_w->tagBind("plus" . $region_count,
 			 '<Enter>' => sub { $ww->configure(-cursor => 'hand2') });
 	$curr_w->tagBind("plus" . $region_count,
 			 '<Leave>' => sub { $ww->configure(-cursor => 'left_ptr') });
	$curr_w->{RegionCount}++;
	$curr_w->insert("end", "\n");
    }
}

sub ShowHideRegion {
    my($w, $region, %args) = @_;
    $w->markSet("showhidemarkbegin", "plus" . $region . ".first");
    $w->markGravity("showhidemarkbegin", "left");
    $w->markSet("showhidemarkend", "plus" . $region . ".first + 1 chars");
    $w->markGravity("showhidemarkend", "right");
    # remember tags for restore
    my(@old_tags) = $w->tagNames("showhidemarkbegin");
    $w->delete("showhidemarkbegin", "showhidemarkend");
    if (!exists $args{-open}) {
	$args{-open} = $w->tagCget("region" . $region, -elide);
    }
    if ($args{-open}) {
	$w->imageCreate("showhidemarkbegin",
			-image => $w->{'MinusImage'});
	$w->tagConfigure("region" . $region, -elide => undef);
    } else {
	$w->imageCreate("showhidemarkbegin",
			-image => $w->{'PlusImage'});
	$w->tagConfigure("region" . $region, -elide => 1);
    }
    # restore old tags for minus/plus image
    foreach my $tag (@old_tags) {
	$w->tagAdd($tag, "showhidemarkbegin");
    }
}

sub DumpXML {
    my($w) = @_;
    $w->Busy();
    my(@dump) = $w->dump("1.0", "end");
    my $out = "<?xml version='1.0' encoding='ISO-8859-1' ?>";
    $out .= "<perltktext>";
    for(my $i=0; $i<=$#dump; $i++) {
	my $x = $dump[$i];
	if ($x eq 'tagon') {
	    $out .= "<tag name='" . $dump[$i+1] . "'>\n";
	    $i+=2;
	} elsif ($x eq 'tagoff') {
	    $out .= "</tag>\n";
	    $i+=2;
	} elsif ($x eq 'image') {
	    local $^W = undef; # XXX often there is no image?!
	    $out .= "<image name='" . $dump[$i+1] . "' />\n";
	    $i+=2;
	} elsif ($x eq 'text') {
	    $dump[$i+1] =~ s/&/&amp;/g;
	    $dump[$i+1] =~ s/</&lt;/g;
	    $dump[$i+1] =~ s/>/&gt;/g;
	    $out .= $dump[$i+1];
	    $i+=2;
	} elsif ($x eq 'mark') {
	    $out .= "<mark name='" . $dump[$i+1] . "' />\n";
	    $i+=2;
	} else {
	    warn "Unknown type $x";
	    $i+=2;
	}
    }
    $out .= "</perltktext>";
    $w->Unbusy();
    $out;
}

sub OpenCloseDepth {
    my($w, $depth, $open) = @_;
    my($begin, $end) = ("1.0");
    while(1) {
	($begin, $end) = $w->tagNextrange('xml_indent' . $depth, $begin);
#warn "$begin $end<" if $depth == 2;
	last if !defined $begin || $begin eq '';
	my(@tags) = $w->tagNames($begin);
	my $region;
	foreach my $tag (@tags) {
	    if ($tag =~ /^region(\d+)/) {
		$region = $1;
		last;
	    }
	}
#warn "region=$region" if $depth==2;
	if (defined $region) {
	    $w->ShowHideRegion($region, -open => $open);
	}
	$begin = $end; #"$end + 1 chars";
    }
}

sub ShowToDepth {
    my($w, $depth) = @_;
    $w->Busy();
    if(!defined $depth) {
	$depth = 999; #this is just a temporary workaround
    }
#warn "Close Depth $depth";
    $depth--;
    $w->OpenCloseDepth($depth, 0);
    while ($depth > 0) {
	$depth--;
#warn "Open Depth $depth";
	$w->OpenCloseDepth($depth, 1);
    }
    $w->Unbusy();
}

# XXX not really working...
sub CloseSelectedRegion {
    my $w = shift;
    return unless $w->tagRanges("sel");

    my $begin_region;
    my $end_region;

    # find beginning
    my(@tags) = $w->tagNames("sel.first");
warn "@tags";
    foreach my $tag (@tags) {
warn $tag;
        if ($tag =~ /^region(\d+)/) {
            $begin_region = $1;
            last;
        }
    }

    # find end
    @tags = $w->tagNames("sel.last");
warn "@tags";
    foreach my $tag (@tags) {
warn $tag;
        if ($tag =~ /^region(\d+)/) {
            $end_region = $1;
            last;
        }
    }

    if (defined $begin_region and defined $end_region) {
        for my $region ($begin_region .. $end_region) {
            $w->ShowHideRegion($region, -open => 0);
        }
    }
}

sub XMLMenu {
    my $w = shift;
    if ($Tk::VERSION >= 800.015) {
	my $textmenu = $w->menu;
	my $xmlmenu = $textmenu->cascade(-tearoff => 0,
					 -label => "XML");
	$xmlmenu->command(-label => 'Info',
			  -command => sub { $w->Showinfo; });
	my $depthmenu = $xmlmenu->cascade(-tearoff => 0,
					  -label => 'Show to depth');
	for my $depth (1 .. 6) {
	    my $_depth = $depth;
	    $depthmenu->command(-label => $depth,
				-command => sub { $w->ShowToDepth($_depth) });
	}
	$depthmenu->command(-label => "Open all",
			    -command => sub { $w->ShowToDepth(undef) });
# XXX not yet:
#	$xmlmenu->command(-label => "Close selected region",
#			  -command => sub { $w->CloseSelectedRegion });
    }
}

if ($] >= 5.006) {
    # unicode translator available
    eval <<'EOF';
sub _convert_from_unicode {
    $_[0] =~ tr/\0-\x{FF}//UC;
    $_[0];
}
EOF
} else {
    # try Unicode::String
    eval <<'EOF';
require Unicode::String;
EOF
    if (!$@) {
	eval <<'EOF';
sub _convert_from_unicode {
    my $umap = Unicode::String::utf8( $_[0]);
    $umap->latin1;
}
EOF
    } else { # do nothing
        eval <<'EOF';
require Unicode::String;
sub _convert_from_unicode { $_[0] }
EOF
    }
}

sub SourceType    { $_[0]->{Source} && $_[0]->{Source}[0] }
sub SourceContent { $_[0]->{Source} && $_[0]->{Source}[1] }

sub Showinfo {
    my $w = shift;
    $w->Busy();
    my $file;
    if($w->{Source} && $w->{Source}[0] eq 'file') {
	$file = $w->{Source}[1];
    }
    require Tk::DialogBox;
    my $d = $w->DialogBox(-title => "XMLView: Info", -buttons => ["OK"]);
    my $textbox = $d->add("Scrolled", qw/ROText -wrap none -width 60
			  -height 5 -scrollbars osw -background white/);
    $textbox->pack(qw/-side left -expand yes -fill both/);
    if (keys %{ $w->{XmlInfo} }) {
	my $message = "XMLDecl: " ;
	foreach my $i (qw(Version Encoding Standalone)) {
	    if (defined $w->{XmlInfo}{$i}) {
		$message = $message . $i . ": " . $w->{XmlInfo}{$i} . " \n  ";
	    }
	}
	$textbox->insert("end", $message);
	$message = "\nDOCTYPE: ";
	foreach my $i (qw(Name Sysid Pubid Internal)) {
	    if (defined $w->{XmlInfo}{$i}) {
		$message = $message . $w->{XmlInfo}{$i} . " \n  ";
	    }
	}
	$textbox->insert("end", $message);
    }
    if (defined $file) {
	$textbox->insert("end", "\nFile: " . $file);
	$textbox->insert("end", " \n  " . scalar( -s $file ) . " Bytes\n");
    }
    my $button = $d->Show;
    $w->Unbusy();
}

sub GetInfo { $_[0]->{XmlInfo} }

1;

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Tk::XMLViewer - Tk widget to display XML

=head1 SYNOPSIS

  use Tk::XMLViewer;
  $xmlviewer = $top->XMLViewer->pack;
  $xmlviewer->insertXML(-file => "test.xml");
  $xmlviewer->insertXML(-text => "<?xml?><a><bla /><foo>bar</foo></a>");

=head1 DESCRIPTION

Tk::XMLViewer is an widget inherited from Tk::Text which displays XML
in a hierarchical tree. You can use the plus and minus buttons to
hide/show parts of the tree.

=head1 METHODS

=over 4

=item insertXML

Insert XML into the XMLViewer widget. Use the -file argument to insert
a file and -text to insert an XML string.

=item DumpXML

Dump the contents of an Tk::Text widget into an XML string, which can
be used as input for the XMLViewer widget. Use the static variant for
Tk::Text widgets and the method for XMLViewer widgets.

    $xml_string1 = Tk::XMLViewer::DumpXML($text_widget);
    $xml_string2 = $xmlviewer->DumpXML;

=item SetIndent

Set indent with for XML tags

    $xmlviewer->SetIndent(width);

=item XMLMenu

Insert XML Menu into Text widget menu.

    $xmlviewer->XMLMenu;

=item SourceType

Returns type of source used for last insertXML (-file or -text)

=item SourceContent

Returns filename (source type -file) or XML text (source type -text) used
for last insertXML.

=item GetInfo

Returns hash of standard XML decl and DOCTYPE elements:

    my %xmlheader = $xmlviewer->GetInfo;

Elements for XMLdecl: Version Encoding Standalone
Elements for DOCTYPE: Name Sysid Pubid Internal

=back

=head1 BUGS

Perl/Tk does not support Unicode, yet. For perl 5.6.0 and newer,
unicode characters are translated to ISO-8859-1 chars, if possible.
For older perls, there is no conversion (unless Unicode::String is
installed), so unicode characters will show as binary values.

DumpXML will not work with nested text tags.

There should be only one insertXML operation at one time (these is
probably only an issue with threaded operations, which do not work in
Perl/Tk anyway).

Viewing of large XML files is slow.

head1 TODO

 - show to depth n: close everything from depth n+1
 - create menu item "close selected region"
 - DTD validation (is this possible with XML::Parser?)

=head1 AUTHOR

Slaven Rezic, <eserte@cs.tu-berlin.de>

Some additions by Jerry Geiger <jgeiger@rios.de>.

=head1 SEE ALSO

L<XML::Parser>(3), L<Tk::Text>(3).

=cut
