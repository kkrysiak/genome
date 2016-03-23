#!/usr/bin/env perl
use strict;
use warnings;
use above "Genome";
use Test::More tests => 9;

#Define the expected result
my $expected_out = Genome::Config::get('test_inputs') . '/Genome-Model-ClinSeq-Command-Converge-DocmReport/2014-10-16/';
ok(-d $expected_out, "directory of expected output exists: $expected_out") or die;

#Obtain two clin-seq build objects
my $clinseq_build_id1 = '4b7539bb10cc4b9c97577cf11f4c79a2';
my $clinseq_build1    = Genome::Model::Build->get($clinseq_build_id1);
ok($clinseq_build1, "Got clinseq build from id1: $clinseq_build_id1") or die;

my $clinseq_build_id2 = 'cdca0edf526c4fe193d3054627a5871b';
my $clinseq_build2    = Genome::Model::Build->get($clinseq_build_id2);
ok($clinseq_build2, "Got clinseq build from id2: $clinseq_build_id2") or die;

my @builds = ($clinseq_build1, $clinseq_build2);

#Obtain a cancer-annotation db object and associated DOCM db file
my $cancer_annotation_db_id = 'tgi/cancer-annotation/human/build37-20140205.1';
my $docm_version            = "0.1";
my $cancer_annotation_db    = Genome::Db::Tgi::CancerAnnotation->get($cancer_annotation_db_id);
ok($cancer_annotation_db, "Got cancer annotation db: $cancer_annotation_db_id") or die;

my $docm_variants_file = $cancer_annotation_db->data_directory . "/DOCM/DOCM_v" . "$docm_version" . ".tsv";
ok(-e $docm_variants_file, "docm variants file exists: $docm_variants_file") or die;

#Create a temp dir for results
my $temp_dir = Genome::Sys->create_temp_directory();
ok($temp_dir, "created temp directory: $temp_dir");

#Create the docm-report command and run it
my $cmd = Genome::Model::ClinSeq::Command::Converge::DocmReport->create(
    builds                => \@builds,
    outdir                => $temp_dir,
    test                  => 10,
    chromosome            => '1',
    docm_variants_file    => $docm_variants_file,
    bam_readcount_version => 0.6,
    bq                    => 0,
    mq                    => 1,
);
$cmd->queue_status_messages(1);
my $r1 = $cmd->execute();
is($r1, 1, 'Testing for successful execution.  Expecting 1.  Got: ' . $r1);

#Dump the output to a log file
my @output   = $cmd->status_messages();
my $log_file = $temp_dir . "/DocmReport.log.txt";
my $log      = IO::File->new(">$log_file");
$log->print(join("\n", @output));
ok(-e $log_file, "Wrote message file from docm-report to a log file: $log_file");

#The first time we run this we will need to save our initial result to diff against
#Genome::Sys->shellcmd(cmd => "cp -r -L $temp_dir/* $expected_out");

#Perform a diff between the stored results and those generated by this test
my @diff = `diff -r -x '*.log.txt' -x '*.xls' $expected_out $temp_dir`;
my $ok = ok(@diff == 0, "Found only expected number of differences between expected results and test results");
unless ($ok) {
    diag("expected: $expected_out\nactual: $temp_dir\n");
    diag("differences are:");
    diag(@diff);
    my $diff_line_count = scalar(@diff);
    print "\n\nFound $diff_line_count differing lines\n\n";
    Genome::Sys->shellcmd(cmd => "rm -fr /tmp/last-docm-report/");
    Genome::Sys->shellcmd(cmd => "mv $temp_dir /tmp/last-docm-report");
}
