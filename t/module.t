# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tk;
use Tk::XMLViewer;
use XML::Parser;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

#$file = "/oo/kunden/vi/ecollateral2/in/ecollateral_Aero_Orea_de.xml";
$file = "test.xml";

$top = new MainWindow;
$xmlwidget = $top->Scrolled('XMLViewer',
			    -scrollbars => "osoe")->pack;
$xmlwidget->insertXML(-file => $file);
$xmlwidget->XMLMenu;

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

$top->update;
$top->waitVariable(\$not);
#MainLoop;

print "${not}ok 2\n";
