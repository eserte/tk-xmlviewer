use Tk;
use Tk::XMLViewer;
use XML::Parser;
use FindBin;
use Getopt::Long;
use Test::More tests => 10;

my $demo = 0;
GetOptions("demo!" => \$demo) or die "usage!";

my $use_unicode = ($Tk::VERSION >= 803); # unicode enabled
if ($use_unicode) {
    $file = "$FindBin::RealBin/testutf8.xml";
} else {
    $file = "$FindBin::RealBin/test.xml";
}

$top = new MainWindow;
$t2 = $top->Toplevel;
$t2->withdraw;

$xmlwidget = $top->Scrolled('XMLViewer',
			    -tagcolor => 'blue',
			    -scrollbars => "osoe")->pack;
ok($xmlwidget);
ok(UNIVERSAL::isa($xmlwidget->Subwidget("scrolled"), "Tk::XMLViewer"));

$xmlwidget->tagConfigure('xml_comment', -foreground => "white",
			 -background => "red", -font => "Helvetica 15");

$xmlwidget->insertXML(-file => $file);
$xmlwidget->XMLMenu;

my $xml_string1 = $xmlwidget->DumpXML;
isnt($xml_string1, '');

my $xmlwidget2 = $t2->XMLViewer->pack;
ok($xmlwidget2->isa('Tk::XMLViewer'));

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
ok(defined &Tk::XMLViewer::_convert_from_unicode);

my %info = %{ $xmlwidget->GetInfo };
is($info{Version}, "1.0");
if ($use_unicode) {
    is($info{Encoding}, "utf-8");
} else {
    is($info{Encoding}, "ISO-8859-1");
}
is($info{Name}, "ecollateral");
is($info{Sysid}, "test.dtd");

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

if (!$demo || $ENV{BATCH}) {
    $top->repeat(100, sub { $not = "" }); # repeat instead of after here
}

$top->update;
$top->waitVariable(\$not);

$t2->destroy;

#MainLoop;

is($not, "");
