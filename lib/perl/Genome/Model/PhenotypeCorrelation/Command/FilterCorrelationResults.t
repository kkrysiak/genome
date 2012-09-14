#!/usr/bin/env genome-perl

use File::Temp qw/tempdir/;
use Test::More;
use above 'Genome';

use warnings;
use strict;
BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

#This module based on SplitVariantMatrix.t

my $pkg = 'Genome::Model::PhenotypeCorrelation::Command::FilterCorrelationResults';
use_ok($pkg);


#This is crappy but use heredocs to make our files
my $persitedata = <<PERSITE;
Chrom	Pos	Ref	Alt	ByAltTransition	TotalTransitions	TotalTransversions	ByAltNovel	TotalNovel	TotalKnown	GenotypeDist	AlleleDistBySample	AlleleDist	ByAltAlleleFreq	MAF
1	69270	A	G	1	1	0	1	1	0	30,3,7	33,10	63,17	0.7875,0.2125	0.2125
1	69761	A	T	0	0	1	0	0	1	44,3,2	47,5	91,7	0.928571,0.0714286	0.0714286
1	879431	T	C	1	1	0	0	0	1	45,3,1	48,4	93,5	0.94898,0.0510204	0.0510204
1	879481	G	C	0	0	1	0	0	1	46,3,0	49,3	95,3	0.969388,0.0306122	0.0306122
1	879576	C	T	1	1	0	0	0	1	47,2,0	49,2	96,2	0.979592,0.0204082	0.0204082
1	879911	G	A	1	1	0	0	0	1	46,1,0	47,1	93,1	0.989362,0.0106383	0.0106383
1	1887092	G	C,A	0,1	1	1	1,0	1	1	46,0,1,1,0,0	47,1,1	93,2,1	0.96875,0.0208333,0.0104167	0.0104167
PERSITE

my $correlation = <<CORR;
y	y_type	x	degrees_freedom	deviance	residual_degrees_freedom	residual_deviance	p-value	covariants	memo
Invasiveness	B	X1_69270_A_G	2	0.898110889671109	37	53.6502578087916	0.638230711115925	Race + Gender	NA
Invasiveness	B	X1_69761_A_T	2	0.319388493446141	46	67.5886256212838	0.852404374557522	Race + Gender	NA
Invasiveness	B	X1_879431_T_C	2	1.72790655878502	46	66.180107555945	0.42149250670187	Race + Gender	NA
Invasiveness	B	X1_879481_G_C	1	0.406372432431652	47	67.5016416822983	0.523816481649023	Race + Gender	NA
Invasiveness	B	X1_879576_C_T	1	0.000868621186967289	47	67.907145493543	0.976487846880672	Race + Gender	NA
Invasiveness	B	X1_879911_G_A	1	1.54294017301254	45	63.421275196557	0.214180696345052	Race + Gender	NA
Invasiveness	B	X1_1887092_G_C.A	2	2.77258846667096	45	63.7695408670838	0.250000031946105	Race + Gender	NA
CORR

my $expected = <<FILTEREDCORR;
y	y_type	x	degrees_freedom	deviance	residual_degrees_freedom	residual_deviance	p-value	covariants	memo
Invasiveness	B	X1_69270_A_G	2	0.898110889671109	37	53.6502578087916	0.638230711115925	Race + Gender	NA
Invasiveness	B	X1_69761_A_T	2	0.319388493446141	46	67.5886256212838	0.852404374557522	Race + Gender	NA
Invasiveness	B	X1_879431_T_C	2	1.72790655878502	46	66.180107555945	0.42149250670187	Race + Gender	NA
Invasiveness	B	X1_879481_G_C	1	0.406372432431652	47	67.5016416822983	0.523816481649023	Race + Gender	NA
FILTEREDCORR

my $tmpdir = tempdir(
    't-FilterCorrelationResults-XXXXX',
    DIR => "$ENV{GENOME_TEST_TEMP}",
    CLEANUP => 1
);
my $original_corr = "$tmpdir/orig.txt";
my $expected_corr = "$tmpdir/expected.txt";
my $output = "$tmpdir/output.txt";
my $persite = "$tmpdir/persite.txt";

#create some files
write_test_data($original_corr, $correlation);
write_test_data($expected_corr, $expected);
write_test_data($persite, $persitedata);

# LET THE TESTING BEGIN!
my $cmd = $pkg->create(
    input_file => $original_corr,
    minimum_maf => 0.03,
    output_file => $output,
    per_site_report_file => $persite,
);
ok($cmd, "Created command object");
my $results = $cmd->execute;
ok($results, "Executed command");
ok(-s $output, "Got non-empty output");

# CHECK RESULTS
my $diff = Genome::Sys->diff_file_vs_file($expected_corr, $output);
ok(!$diff, 'File filtered as expected') or diag("diff results:\n" . $diff);

done_testing(); 

sub write_test_data {
    my ($filename, $data) = @_;
    #create a file. This will throw if it fails
    my $fh = Genome::Sys->open_file_for_writing($filename);
    print $fh $data;
    $fh->close;
    return;
}

