#!/usr/bin/env perl

use Test::Simple tests => 25;

use Compress::SelfExtracting 'compress';
require Compress::SelfExtracting::Filter;

ok(1);

use strict;
$|++;

my $test_output = "Hello, compressed world";
my $test = <<END;
#!/usr/bin/perl
use strict;

print '$test_output';
END

my $tmp = "test.$$.plz";
for my $type (qw/BWT LZW LZSS LZ77 Huffman/) {
    for my $uu (0, 1) {
	for my $sa (0, 1) {
	    if ($type eq 'LZW') {
		for my $bits (12, 16) {
		    test_it(type => $type, uu => $uu, bits => $bits,
			    standalone => $sa);
		}
	    } else {
		test_it(type => $type, uu => $uu, standalone => $sa);
	    }
	}
    }
}

unlink "test.$$";

sub test_it
{
    my $err = '';
    open(SCRIPT, ">$tmp.pl") or die "$tmp.pl: $!";
    my $script;
    print SCRIPT ($script = compress $test, @_);
    close SCRIPT;
    open(O, ">$tmp") or die "$tmp: $!";
    my $saveout = select O;
    my $res;
    {
	local $^W = 0;
	no strict;

	# why?!  (1) The standalone calls exit() at the end of its
	# begin, which causes us to exit.  (2) If we forked another
	# Perl to handle this, we'd have to fiddle with its @INC
	# (since the modules aren't installed).
	if ($standalone) {
	    eval $script;
	} else {
	    do $script;
	}
    }
    $err = $@;
    close O;
    select $saveout;
    if (open I, "<$tmp") {
	$res = <I>;
	close I;
    } else {
	$err = "$tmp: $!";
    }
    unlink $tmp, "$tmp.pl";
    ok($res ne $test_output);
}
