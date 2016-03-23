#!/usr/bin/env genome-perl

use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT}               = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use above "Genome";
use File::Spec;
use Test::More;
use Genome::Utility::Test qw(compare_ok);

use_ok('Genome::Model::ClinSeq::Command::MicroarrayCnv') or die;

subtest "somatic mode" => sub {
    #Define the test where expected results are stored
    my $expected_output_dir =
        Genome::Utility::Test->data_dir_ok('Genome::Model::ClinSeq::Command::MicroarrayCnv', '2015-05-28/somatic');

    #Run MicroarrayCNV on the 'apipe-test-clinseq-wer' model in somatic-mode
    my $somatic_opdir = Genome::Sys->create_temp_directory();
    ok($somatic_opdir, "created temp directory: $somatic_opdir") or die;
    my $clinseq_model = Genome::Model->get(name => 'apipe-test-clinseq-wer');
    my $somatic_microarray_cnv = Genome::Model::ClinSeq::Command::MicroarrayCnv->create(
        outdir        => $somatic_opdir,
        clinseq_model => $clinseq_model,
        test          => 1,
        min_cnv_diff  => 0.1
    );
    $somatic_microarray_cnv->queue_status_messages(1);
    $somatic_microarray_cnv->execute();

    #Dump the output to a log file
    my @output1  = $somatic_microarray_cnv->status_messages();
    my $log_file = File::Spec->join($somatic_opdir, "RunMicroarrayCnv.log.txt");
    my $log      = IO::File->new(">$log_file");
    $log->print(join("\n", @output1));
    $log->close();
    ok(-e $log_file, "Wrote message file from microarray-cnv to a log file: $log_file");

    #Perform a diff between the stored results and those generated by this test
    my @diff =
        `diff -r -x '*.log.txt' -x '*.pdf' -x '*.stderr' -x '*.stdout' -x '*.jpeg' $expected_output_dir $somatic_opdir`;
    my $ok = ok(@diff == 0, "Found only expected number of differences between expected results and test results");
    unless ($ok) {
        diag("expected: $expected_output_dir\nactual: $somatic_opdir\n");
        diag("differences are:");
        diag(@diff);
        my $diff_line_count = scalar(@diff);
        print "\n\nFound $diff_line_count differing lines\n\n";
        Genome::Sys->shellcmd(cmd => "rm -fr /tmp/last-run-microarray-cnview-somatic/");
        Genome::Sys->shellcmd(cmd => "mv $somatic_opdir /tmp/last-run-microarray-cnview-somatic/");
    }
};

subtest "single-sample mode" => sub {
    #Define the test where expected results are stored
    my $expected_output_dir =
        Genome::Utility::Test->data_dir_ok('Genome::Model::ClinSeq::Command::MicroarrayCnv', '2015-05-28/single');

    #Run MicroarrayCNV on the 'apipe-test-clinseq-wer' model in single-sample mode
    my $single_opdir = Genome::Sys->create_temp_directory();
    ok($single_opdir, "created temp directory: $single_opdir") or die;
    my $clinseq_model  = Genome::Model->get(name => 'apipe-test-clinseq-wer');
    my $ma_model       = $clinseq_model->wgs_model->tumor_model->genotype_microarray_model;
    my $cancer_db      = Genome::Db->get("tgi/cancer-annotation/human/build37-20150205.1");
    my $microarray_cnv = Genome::Model::ClinSeq::Command::MicroarrayCnv->create(
        outdir                  => $single_opdir,
        microarray_model_single => $ma_model,
        test                    => 1,
        cancer_annotation_db    => $cancer_db,
    );
    $microarray_cnv->queue_status_messages(1);
    $microarray_cnv->execute();

    #Dump the output to a log file
    my @output1  = $microarray_cnv->status_messages();
    my $log_file = File::Spec->join($single_opdir, "RunMicroarrayCnv.log.txt");
    my $log      = IO::File->new(">$log_file");
    $log->print(join("\n", @output1));
    $log->close();
    ok(-e $log_file, "Wrote message file from microarray-cnv to a log file: $log_file");

    #Perform a diff between the stored results and those generated by this test
    my @diff =
        `diff -r -x '*.log.txt' -x '*.pdf' -x '*.stderr' -x '*.stdout' -x '*.jpeg' $expected_output_dir $single_opdir`;
    my $ok = ok(@diff == 0, "Found only expected number of differences between expected results and test results");
    unless ($ok) {
        diag("expected: $expected_output_dir\nactual: $single_opdir\n");
        diag("differences are:");
        diag(@diff);
        my $diff_line_count = scalar(@diff);
        print "\n\nFound $diff_line_count differing lines\n\n";
        Genome::Sys->shellcmd(cmd => "rm -fr /tmp/last-run-microarray-cnview-single/");
        Genome::Sys->shellcmd(cmd => "mv $single_opdir /tmp/last-run-microarray-cnview-single");
    }
};

done_testing();
