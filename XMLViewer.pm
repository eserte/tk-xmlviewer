# -*- perl -*-

#
# $Id: XMLViewer.pm,v 1.5 2000/01/19 13:57:44 eserte Exp $
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

$VERSION = '0.04';

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
#    $w->{RegionStart} = [];
#    $w->{TagStart}    = [];
    $w->{RegionCount} = 0;

    # XXX warum parent?
    $w->{PlusImage}  = $w->parent->Pixmap(-id => 'plus');
    $w->{MinusImage} = $w->parent->Pixmap(-id => 'minus');
}

sub insertXML {
    my $w = shift;
    my $file = shift;
    my $p1 = new XML::Parser(Style => "Stream");
    $w->{Indent} = 0;
    $w->{PendingEnd} = 0;
    $curr_w = $w;
    $p1->parsefile($file);
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
	$w->insert("end", ">\n");
	$w->{PendingEnd} = 0;
	my $indent = $w->{Indent}-1;
	$w->markSet('regionstart' . $indent, $w->index("end - 1 chars"));
	$w->markGravity('regionstart' . $indent, 'left');
    }
}

sub StartTag {
    $curr_w->_flush;
    my $start = $curr_w->index("end - 1 chars");
    $curr_w->insert("end", "<", "",
		    $_[1], 'xml_tag');
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
	$curr_w->insert("end", " />\n");
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
 			 '<1>' => [$curr_w, '_show_hide_region',
				   $region_count, $curr_w->{'Indent'}]);
 	$curr_w->tagBind("plus" . $region_count,
 			 '<Enter>' => sub { $curr_w->configure(-cursor => 'hand2') });
 	$curr_w->tagBind("plus" . $region_count,
 			 '<Leave>' => sub { $curr_w->configure(-cursor => 'left_ptr') });
	$curr_w->{RegionCount}++;
	$curr_w->insert("end", "\n");
    }
}

sub _show_hide_region {
    my($w, $region, $indent) = @_;
    my $index = $w->index("plus" . $region . ".first");
    $w->delete("plus" . $region . ".first",
	       "plus" . $region . ".last");
    if ($w->tagCget("region" . $region, -elide)) {
	$w->imageCreate($index,
			-image => $w->{'MinusImage'});
	$w->tagConfigure("region" . $region, -elide => undef);
    } else {
	$w->imageCreate($index,
			-image => $w->{'PlusImage'});
	$w->tagConfigure("region" . $region, -elide => 1);
    }
    $w->tagAdd("plus" . $region, $index);
    $w->tagAdd($w->_indenttag($indent),
	       $index);

}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Tk::XMLViewer - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Tk::XMLViewer;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Tk::XMLViewer was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut
