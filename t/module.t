# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $^W = 1; $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tk;
use Tk::XMLViewer;
use XML::Parser;
$loaded = 1;
my $ok = 1;
print "ok " . $ok++ . "\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

#$file = "/oo/kunden/vi/ecollateral2/in/ecollateral_Aero_Orea_de.xml";
$file = "test.xml";

$top = new MainWindow;
$t2 = $top->Toplevel;
$t2->withdraw;

$xmlwidget = $top->Scrolled('XMLViewer',
			    -tagcolor => 'blue',
			    -scrollbars => "osoe")->pack;

$xmlwidget->tagConfigure('xml_comment', -foreground => "white",
			 -background => "red", -font => "Helvetica 6");

$xmlwidget->insertXML(-file => $file);
$xmlwidget->XMLMenu;

my $xml_string1 = $xmlwidget->DumpXML;
if ($xml_string1 eq '') { print "not " } print "ok ". $ok++ . "\n";

my $xmlwidget2 = $t2->XMLViewer->pack;
if (!$xmlwidget2->isa('Tk::XMLViewer')) {print "not "} print "ok ".$ok++."\n";

$xmlwidget2->insertXML(-text => <<EOF);
<?xml version="1.0" encoding="ISO-8859-1" ?>
<!DOCTYPE ecollateral SYSTEM "test.dtd">
<book title="test">
</book>
EOF
$xmlwidget2->destroy;

# test internals

$xmlwidget->ShowHideRegion(1, -open => 0);
$xmlwidget->ShowHideRegion(1, -open => 1);
$xmlwidget->OpenCloseDepth(1, 0);
$xmlwidget->OpenCloseDepth(1, 1);
$xmlwidget->ShowToDepth(0);
$xmlwidget->ShowToDepth(undef);
if (!defined &Tk::XMLViewer::_convert_from_unicode) {
    print "not ";
}
print "ok " . $ok++ . "\n";

my %info = %{ $xmlwidget->GetInfo };
if ($info{Version} ne "1.0")         { print "not " } print "ok ". $ok++ ."\n";
if ($info{Encoding} ne "ISO-8859-1") { print "not " } print "ok ". $ok++ ."\n";
if ($info{Name} ne "ecollateral")    { print "not " } print "ok ". $ok++ ."\n";
if ($info{Sysid} ne "test.dtd")      { print "not " } print "ok ". $ok++ ."\n";

# definitions for interactive use...

$top->bind("<P>" => sub {
    require Config;
    my $perldir = $Config::Config{'scriptdir'};
    require "$perldir/ptksh";
});

$depth=10;
$f=$top->Frame->pack;
$f->Label(-text => "Depth",
	 #  -command => sub {
	 #      $xmlwidget->ShowToDepth($depth);
	 #  }
	 )->pack(-side => "left");
$f->Scale(-variable => \$depth,
	  -from => 1,
	  -command => sub {
	      $xmlwidget->ShowToDepth($depth);
	  },
	  -to => 10,
	  -orient => 'horiz')->pack(-side => "left");
$f->Button(-text => "Dump Tk::Text as XML",
	   -command => sub {
	       my $s = $xmlwidget->DumpXML;
	       #warn $s;
	       $t = $top->Toplevel;
	       $xmlwidget2 = $t->Scrolled('XMLViewer',
					  -scrollbars => "osoe")->pack;
	       $xmlwidget2->insertXML(-text => $s);
	       $xmlwidget2->XMLMenu;
	   })->pack(-side => "left");
my $okb = $f->Button(-text => "OK",
		     -command => sub { $not = ""; })->pack(-side => "left");
$okb->focus;
$f->Button(-text => "Not OK",
	   -command => sub { $not = "not "; })->pack(-side => "left");

if ($ENV{BATCH}) {
    $top->after(1000, sub { $not = "" });
}

$top->update;
$top->waitVariable(\$not);

$t2->destroy;

#MainLoop;

print "${not}ok " . $ok++ . "\n";
