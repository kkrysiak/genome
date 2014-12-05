#!/usr/bin/env genome-perl

BEGIN { 
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
    $ENV{NO_LSF} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::More;
use Sub::Install qw(reinstall_sub);
use File::Basename qw(basename);
use Genome::VariantReporting::Command::Wrappers::TestHelpers qw(get_build succeed_build compare_directories);
use Genome::VariantReporting::Framework::TestHelpers qw(test_xml);

my $pkg = "Genome::VariantReporting::Command::Wrappers::Trio";
use_ok($pkg);
my $test_dir = __FILE__.".d";

my $roi_name = "test roi";
my $tumor_sample1 = Genome::Test::Factory::Sample->setup_object(name => "TEST-patient1-somval_tumor1");
my $tumor_sample2 = Genome::Test::Factory::Sample->setup_object(name => "TEST-patient1-somval_tumor2");
my $normal_sample1 = Genome::Test::Factory::Sample->setup_object(name => "TEST-patient1-somval_normal1");
my $discovery_build = get_build($roi_name, $tumor_sample1, $normal_sample1);
my $followup_build = get_build($roi_name, $tumor_sample2, $normal_sample1);
my $normal_build = get_build($roi_name, $normal_sample1, undef);
succeed_build($discovery_build);
succeed_build($followup_build);
succeed_build($normal_build);

use Genome::Model::SomaticValidation::Command::AlignmentStatsSummary;
reinstall_sub( {
        into => "Genome::Model::SomaticValidation::Command::AlignmentStatsSummary",
        as => "_execute_body",
        code => sub {
            return 1;
        },
    }
);
use Genome::Model::SomaticValidation::Command::CoverageStatsSummary;
reinstall_sub( {
        into => "Genome::Model::SomaticValidation::Command::CoverageStatsSummary",
        as => "_execute_body",
        code => sub {
            return 1;
        },
    }
);

my $cmd = $pkg->create(
    models => [$discovery_build->model, $followup_build->model, $normal_build->model],
    coverage_models => [$discovery_build->model, $followup_build->model, $normal_build->model],
    tumor_sample => $tumor_sample1,
    followup_sample => $tumor_sample2,
    normal_sample => $normal_sample1,
);

my $p = $cmd->execute();
isa_ok($p, 'Genome::VariantReporting::Process::Trio');

test_xml($p->workflow_file, __FILE__);


=cut
my $expected_params = {
};
#is_deeply($expected_params, $cmd->params_for_execute, "params were created correctly");
ok($cmd->execute);
compare_directories($test_dir, $output_dir);
=cut
done_testing;

