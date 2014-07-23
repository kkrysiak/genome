#!/usr/bin/env genome-perl

BEGIN { 
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::More;
use Genome::Utility::Test qw(compare_ok);
use Genome::File::Vcf::Differ;

my $pkg = 'Genome::Model::Tools::Vcf::AnnotateWithReadcounts';

use_ok($pkg);
my $data_dir = Genome::Utility::Test->data_dir_ok($pkg, "v2");

subtest "output vcf" => sub {
    my $out = Genome::Sys->create_temp_file_path;
    run($out);
    my $expected_out = File::Spec->join($data_dir, "expected.vcf");
    compare_ok($expected_out, $out, "Vcf was written correctly");
};

subtest "output gzipped vcf" => sub {
    my $out = Genome::Sys->create_temp_file_path . '.gz';
    run($out);

    my $expected_out = File::Spec->join($data_dir, "expected.vcf.gz");
    my $differ = Genome::File::Vcf::Differ->new($out, $expected_out);
    my $diff = $differ->diff;
    is($diff, undef, "Found No differences between $out and (expected) $expected_out") ||
       diag $diff->to_string;
};

subtest "output indel vcf" => sub {
    my $out = Genome::Sys->create_temp_file_path . '_indel.gz';
    run_indel($out);

    my $expected_out = File::Spec->join($data_dir, "expected_indel.vcf.gz");
    my $differ = Genome::File::Vcf::Differ->new($out, $expected_out);
    my $diff = $differ->diff;
    is($diff, undef, "Found No differences between $out and (expected) $expected_out") ||
       diag $diff->to_string;
    
};


done_testing;

sub run_indel {
    my $out = shift;

    my $cmd = $pkg->create(
        vcf_file => File::Spec->join($data_dir, "2.vcf.gz"),
        readcount_file_and_sample_idx => [
            sprintf("%s:0", File::Spec->join($data_dir, 'test3.rc.tsv')),
        ],
        output_file => $out,
    );
    ok($cmd->isa($pkg), "Command created ok");
    ok($cmd->execute, "Command executed ok");
}

sub run {
    my $out = shift;

    my $cmd = $pkg->create(
        vcf_file => File::Spec->join($data_dir, "1.vcf.gz"),
        readcount_file_and_sample_idx => [
            sprintf("%s:0", File::Spec->join($data_dir, 'test1.rc.tsv')),
            sprintf("%s:2", File::Spec->join($data_dir, 'test2.rc.tsv')),
        ],
        output_file => $out,
    );
    ok($cmd->isa($pkg), "Command created ok");
    ok($cmd->execute, "Command executed ok");
}

