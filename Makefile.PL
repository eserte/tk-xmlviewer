use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Tk::XMLViewer',
    'VERSION_FROM' => 'XMLViewer.pm', # finds $VERSION
    'PREREQ_PM' => {'Tk'          => 0,
	            'XML::Parser' => 0,
	           },
    'dist'      => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => '.gz',
                    'POSTOP'=>'-$(CHMOD) 644 $(DISTVNAME).tar$(SUFFIX)'},
    'EXE_FILES' => ['tkxmlview'],
);
