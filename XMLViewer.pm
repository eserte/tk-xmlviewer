package Tk::XMLViewer;

require Tk;
require Tk::ROText;

use strict;
use vars qw($VERSION);

use base qw(Tk::ROText);
use XML::Parser;

Construct Tk::Widget 'XMLViewer';

$VERSION = '0.01';

my($curr_w); # XXXXX!
my $indent_width = 2;

sub insertxml {
    my $w = shift;
    my $file = shift;
    my $p1 = new XML::Parser(Style => "Stream");
    $w->{Indent} = 0;
    $curr_w = $w;
    $p1->parsefile($file);
}

sub _indent {
    my $w = shift;
    " " x ($w->{Indent} * $indent_width);
}

sub StartTag {
    $curr_w->insert("end",
		    $curr_w->_indent .
		    "<$_[1]");
    if (%_) {
	$curr_w->insert("end", " " . join(" ", map { "$_='$_{$_}'" } keys %_));
    }
    $curr_w->insert("end", ">\n");
    $curr_w->{Indent} += 2;
}

sub Text {
    s/^\s+//;
    s/\s+$//;
    if ($_ ne "") {
	$curr_w->insert("end", $curr_w->_indent . $_ . "\n");
    }
}

sub EndTag {
    $curr_w->{Indent} -= 2;
    $curr_w->insert("end", $curr_w->_indent . "</$_[1]>\n");
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
