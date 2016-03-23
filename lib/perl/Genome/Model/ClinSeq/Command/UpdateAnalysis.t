#!/usr/bin/env genome-perl

#Written by Malachi Griffith

use strict;
use warnings;
use File::Basename;
use Cwd 'abs_path';

BEGIN {
    $ENV{UR_DBI_NO_COMMIT}               = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use above "Genome";
use Test::More tests => 9;
use Data::Dumper;
use Genome::Utility::Test qw(compare_ok);

use_ok('Genome::Model::ClinSeq::Command::UpdateAnalysis') or die;
use_ok('Genome::Model::ClinSeq::TestData');

#Define the test where expected results are stored
my $expected_output_dir =
    Genome::Config::get('test_inputs') . "/Genome-Model-ClinSeq-Command-UpdateAnalysis/2015-08-06/";
ok(-e $expected_output_dir, "Found test dir: $expected_output_dir") or die;

#Create a temp dir for results
my $temp_dir = Genome::Sys->create_temp_directory();
ok($temp_dir, "created temp directory: $temp_dir");

#Load the test data
my %ids = %{Genome::Model::ClinSeq::TestData->load(
        exclude_normal_rnaseq_model => 1,
        exclude_exome_model         => 1,
        exclude_de_model            => 1
    )
    };
my $individual        = Genome::Individual->get($ids{TEST_INDIVIDUAL_ID});
my $normal_dna_sample = Genome::Sample->get($ids{NORMAL_DNA_SAMPLE});
my $tumor_dna_sample  = Genome::Sample->get($ids{TUMOR_DNA_SAMPLE});
my $tumor_rna_sample  = Genome::Sample->get($ids{TUMOR_RNA_SAMPLE});
my $ref_align_pp      = Genome::ProcessingProfile->get($ids{REFALIGN_PP});
my $wgs_pp            = Genome::ProcessingProfile->get($ids{WGS_PP});
my $exome_pp          = Genome::ProcessingProfile->get($ids{EXOME_PP});
my $rna_seq_pp        = Genome::ProcessingProfile->get($ids{RNASEQ_PP});
my $diff_ex_pp        = Genome::ProcessingProfile->get($ids{DIFFEXP_PP});
my $clin_seq_pp       = Genome::ProcessingProfile->get($ids{CLINSEQ_PP});
my $annotation_build  = Genome::Model::Build->get($ids{ANNOTATION_BUILD});
my $dbsnp_build       = Genome::Model::Build->get($ids{DBSNP_BUILD});
my $ref_seq_build     = Genome::Model::Build->get($ids{REFSEQ_BUILD});

#genome model clin-seq update-analysis  --individual='common_name=HG1'  --samples='id in [2874747197,2874769474,2875643613]'

#Create the update-analysis command for step 1
my $update_analysis_cmd1 = Genome::Model::ClinSeq::Command::UpdateAnalysis->create(display_defaults => 1);
$update_analysis_cmd1->queue_status_messages(1);
my $r1 = $update_analysis_cmd1->execute();
is($r1, 1, 'Testing for successful execution of step 1.  Expecting 1.  Got: ' . $r1);

#Create the update-analysis command for step 2
my $update_analysis_cmd2 = Genome::Model::ClinSeq::Command::UpdateAnalysis->create(
    individual                       => $individual,
    ref_align_pp                     => $ref_align_pp,
    wgs_somatic_variation_pp         => $wgs_pp,
    exome_somatic_variation_pp       => $exome_pp,
    rnaseq_pp                        => $rna_seq_pp,
    differential_expression_pp       => $diff_ex_pp,
    clinseq_pp                       => $clin_seq_pp,
    annotation_build                 => $annotation_build,
    dbsnp_build                      => $dbsnp_build,
    previously_discovered_variations => $dbsnp_build,
    reference_sequence_build         => $ref_seq_build,
);
$update_analysis_cmd2->queue_status_messages(1);
my $r2 = $update_analysis_cmd2->execute();
is($r2, 1, 'Testing for successful execution of step 2.  Expecting 1.  Got: ' . $r2);

#Create the update-analysis command for step 3
my $update_analysis_cmd3 = Genome::Model::ClinSeq::Command::UpdateAnalysis->create(
    individual                       => $individual,
    samples                          => [$normal_dna_sample, $tumor_dna_sample, $tumor_rna_sample],
    ref_align_pp                     => $ref_align_pp,
    wgs_somatic_variation_pp         => $wgs_pp,
    exome_somatic_variation_pp       => $exome_pp,
    rnaseq_pp                        => $rna_seq_pp,
    differential_expression_pp       => $diff_ex_pp,
    clinseq_pp                       => $clin_seq_pp,
    annotation_build                 => $annotation_build,
    dbsnp_build                      => $dbsnp_build,
    previously_discovered_variations => $dbsnp_build,
    reference_sequence_build         => $ref_seq_build,
);
$update_analysis_cmd3->queue_status_messages(1);
my $r3 = $update_analysis_cmd3->execute();
is($r3, 1, 'Testing for successful execution of step 3.  Expecting 1.  Got: ' . $r3);

#Dump the output of update-analysis to a log file
my @output1          = $update_analysis_cmd1->status_messages();
my @output2          = $update_analysis_cmd2->status_messages();
my @output3          = $update_analysis_cmd3->status_messages();
my $output_file_name = "UpdateAnalysis.log.txt";
my $log_file         = "$temp_dir/$output_file_name";

my $log = IO::File->new(">$log_file");
$log->print(join("\n", @output1));
$log->print(join("\n", @output2));
$log->print(join("\n", @output3));
$log->close;
ok(-e $log_file, "Wrote message file from update-analysis to a log file: $log_file");

#The first time we run this we will need to save our initial result to diff against
#Genome::Sys->shellcmd(cmd => "cp -r -L $temp_dir/* $expected_output_dir");
#Perform a diff between the stored results and those generated by this test
my $replace = format_replace_hash(\%ids);
my $cp_cmd  = "cp $log_file /tmp/$output_file_name";
compare_ok(
    $log_file, "$expected_output_dir/$output_file_name",
    replace => $replace,
    name    => "log files are the same"
) || system($cp_cmd);

sub format_replace_hash {
    my $hash_ref = shift;
    my %ids      = %{$hash_ref};
    my @replace;
    for my $key (keys %ids) {
        push @replace, [$key => $ids{$key}];
    }
    return \@replace;
}
