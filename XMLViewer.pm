# -*- perl -*-

#
# $Id: XMLViewer.pm,v 1.7 2000/01/19 15:58:42 eserte Exp $
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

require Tk;
require Tk::ROText;
require Tk::Pixmap;
use strict;
use vars qw($VERSION);

use base qw(Tk::ROText);
use XML::Parser;

Construct Tk::Widget 'XMLViewer';

$VERSION = '0.06';

my($curr_w); # XXXXX!
my $indent_width = 32;

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
    $w->{IndentTags}  = [];
    $w->{RegionCount} = 0;

    # XXX warum parent?
    $w->{PlusImage}  = $w->parent->Pixmap(-id => 'plus');
    $w->{MinusImage} = $w->parent->Pixmap(-id => 'minus');
}

sub insertXML {
    my $w = shift;
    my(%args) = @_;
    my $p1 = new XML::Parser(Style => "Stream");
    $w->{Indent} = 0;
    $w->{PendingEnd} = 0;
    $curr_w = $w;
    if ($args{-file}) {
	$p1->parsefile($args{-file});
    } else {
	$p1->parse($args{-text});
    }
    $w->_flush;
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
    $curr_w->insert("end", "<$_[1]", 'xml_tag');
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
			    $k, "xml_attrkey",
			    "='", "",
			    $v, "xml_attrval",
			    "'", "");
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
			$_ . "\n",
			$curr_w->_indenttag);
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
	$curr_w->insert("end", "<", "",
			"/$_[1]", 'xml_tag',
			">");
	$curr_w->tagAdd($curr_w->_indenttag, $start, "end");
	my $region_count = $curr_w->{RegionCount};
	$curr_w->tagAdd("region" . $region_count,
			$region_start, $region_end);

 	$curr_w->imageCreate("$tag_start",
 			     -image => $curr_w->{'MinusImage'});
 	$curr_w->tagAdd("plus" . $region_count,
 			$tag_start);
 	$curr_w->tagAdd($curr_w->_indenttag,
 			$tag_start);
 	$curr_w->tagBind("plus" . $region_count,
 			 '<1>' => [$curr_w, 'ShowHideRegion', $region_count]);
 	$curr_w->tagBind("plus" . $region_count,
 			 '<Enter>' => sub { $curr_w->configure(-cursor => 'hand2') });
 	$curr_w->tagBind("plus" . $region_count,
 			 '<Leave>' => sub { $curr_w->configure(-cursor => 'left_ptr') });
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
    $out;
}

sub OpenDepth {
    my($w, $depth) = @_;
    my($begin, $end) = ("1.0");
    while(1) {
	($begin, $end) = $w->tagNextrange('xml_indent' . $depth, $begin);
	last if $begin eq '';
	my(@tags) = $w->tagNames($begin);
	my $region;
	foreach my $tag (@tags) {
	    if ($tag =~ /^region(\d+)/) {
		$region = $1;
		last;
	    }
	}
	next if !defined $region;
	$w->ShowHideRegion($region, -open => 0);
	$begin = "$end + 1 chars";
    }
}

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

=head1 AUTHOR

Slaven Rezic, <eserte@cs.tu-berlin.de>

=head1 SEE ALSO

XML::Parser(3), Tk::Text(3).

=cut
