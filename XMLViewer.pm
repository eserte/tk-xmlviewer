# -*- perl -*-

#
# $Id: XMLViewer.pm,v 1.3 2000/01/19 11:12:58 eserte Exp $
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

use strict;
use vars qw($VERSION);

use base qw(Tk::ROText);
use XML::Parser;

Construct Tk::Widget 'XMLViewer';

$VERSION = '0.03';

my($curr_w); # XXXXX!
my $indent_width = 32;

sub InitObject {
    my($w,$args) = @_;
    warn "$w $args";
    $w->SUPER::InitObject($args);
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
    for my $i (0 .. 10) {
	$w->tagConfigure("xml_indent$i",
			 -lmargin1 => $i*$indent_width,
			 -lmargin2 => $i*$indent_width,
			);
    }
}

sub insertXML {
    my $w = shift;
    my $file = shift;
    my $p1 = new XML::Parser(Style => "Stream");
    $w->{Indent} = 0;
    $curr_w = $w;
    $p1->parsefile($file);
}

sub StartTag {
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
    $curr_w->insert("end", ">");
    $curr_w->tagAdd('xml_indent' . $curr_w->{Indent}, $start, "end");
    $curr_w->insert("end", "\n");
    $curr_w->{Indent}++;
}

sub Text {
    s/^\s+//;
    s/\s+$//;
    if ($_ ne "") {
	$curr_w->insert("end",
			$_ . "\n",
			'xml_indent' . $curr_w->{Indent});
    }
}

sub EndTag {
    $curr_w->{Indent} --;
    my $start = $curr_w->index("end - 1 chars");
    $curr_w->insert("end", "<", "",
		    "/$_[1]", 'xml_tag',
		    ">");
    $curr_w->tagAdd('xml_indent' . $curr_w->{Indent}, $start, "end");
    $curr_w->insert("end", "\n");
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
