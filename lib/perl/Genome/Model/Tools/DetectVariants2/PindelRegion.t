#!/usr/bin/env genome-perl

use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
};

use above 'Genome';

use Test::More;
use Test::Exception;
use Genome::Utility::Test qw(compare_ok);
use Genome::File::Vcf::Differ;
use Genome::Test::Factory::SoftwareResult::User;

Genome::Config::set_env('workflow_builder_backend', 'inline');

my $pkg = 'Genome::Model::Tools::DetectVariants2::PindelRegion';
use_ok($pkg);

my $refbuild_id = 101947881;
my $ref_seq_build = Genome::Model::Build::ImportedReferenceSequence->get($refbuild_id);
ok($ref_seq_build, 'human36 reference sequence build') or die;

my $test_base_dir = Genome::Utility::Test->data_dir($pkg);
my $region_file   = File::Spec->join($test_base_dir, 'region_file.bed');

my $tumor  = File::Spec->join($test_base_dir, 'flank_tumor_sorted.bam');
my $normal = File::Spec->join($test_base_dir, 'flank_normal_sorted.bam');

my $test_working_dir = Genome::Sys->create_temp_directory();

my $result_users = Genome::Test::Factory::SoftwareResult::User->setup_user_hash(
    reference_sequence_build => $ref_seq_build,
);

my %params = (
    aligned_reads_input          => $tumor, 
    control_aligned_reads_input  => $normal,
    reference_build_id           => $refbuild_id,
    output_directory             => $test_working_dir,
    version                      => '0.2.5',
    params                       => $region_file,
    result_users                 => $result_users,
    aligned_reads_sample         => 'TEST',
    control_aligned_reads_sample => 'TEST_NORMAL',
);

subtest 'execute' => sub {
    my $cmd = $pkg->create(%params);
    ok($cmd, 'Command created');

    my $rv = $cmd->execute;
    is($rv, 1, 'Command executes ok');

    for my $output_basename qw(indels.hq indels.hq.bed) {
        compare_ok(
            File::Spec->join($test_base_dir, $output_basename),
            File::Spec->join($test_working_dir, $output_basename),
            "$output_basename as expected"
        );
    }
    my $differ = Genome::File::Vcf::Differ->new(
        File::Spec->join($test_base_dir, 'indels.vcf.gz'), 
        File::Spec->join($test_working_dir, 'indels.vcf.gz')
    );
    my $diff = $differ->diff;
    is($diff, undef, 'indels.vcf.gz as expected') || diag $diff->to_string;
};


subtest 'incompatible version' => sub {
    my %bad_params = %params;
    $bad_params{version} = '0.2.3';
    $bad_params{output_directory} = Genome::Sys->create_temp_directory();
    my $cmd = $pkg->create(%bad_params);
    ok($cmd, 'Command created');
    dies_ok(sub {$cmd->execute}, 'Command fails as expected');
};

subtest 'invalid region file' => sub {
    my %bad_params = %params;
    $bad_params{params} = 'bad_file';
    $bad_params{output_directory} = Genome::Sys->create_temp_directory();
    my $cmd = $pkg->create(%bad_params);
    ok($cmd, 'Command created');
    dies_ok(sub {$cmd->execute}, 'Command fails as expected');
};

done_testing();
