#!/usr/bin/env genome-perl

BEGIN { 
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::More;
use Genome::VariantReporting::Framework::Command::Wrappers::TestHelpers qw(get_build compare_directories);
use Test::MockObject::Extends;
use Genome::Test::Factory::ProcessingProfile::RnaSeq;
use Genome::Test::Factory::Model::RnaSeq;
use Genome::Test::Factory::Build;
use Genome::Utility::Test qw(compare_ok);
use Sub::Install qw(reinstall_sub);

my $pkg = "Genome::VariantReporting::Framework::Command::Wrappers::RnaSeq";

use_ok($pkg);

my $test_dir = __FILE__.".d";
my $expected_dir = File::Spec->join($test_dir, "expected");
my $output_dir = Genome::Sys->create_temp_directory;

my $roi_name = "test_roi"; #FIXME not actually needed for this test
my $tumor_sample = Genome::Test::Factory::Sample->setup_object(name => "TEST-patient1-somval_tumor1");
my $normal_sample = Genome::Test::Factory::Sample->setup_object(name => "TEST-patient1-somval_normal1", source_id => $tumor_sample->source_id);
my $somatic_build = get_build($roi_name, $tumor_sample, $normal_sample);

is($somatic_build->class, "Genome::Model::Build::SomaticValidation", 'Somatic build looks ok');
my $tumor_build = get_rnaseq_build($tumor_sample);

my $wrapper = $pkg->create(
    somatic_build => $somatic_build,
    tumor_build => $tumor_build,
    base_output_dir => $output_dir,
);
is($wrapper->class, $pkg, 'wrapper command looks ok');

# Turn off report running, as it's out of the scope/time for this test
reinstall_sub({
    into => "Genome::VariantReporting::Framework::Command::CreateReport",
    as => "execute",
    code => sub {return 1},
});

ok($wrapper->execute, 'wrapper executed');

compare_directories($expected_dir, $output_dir);

my $relative_yaml_path = File::Spec->join(qw(test_model_1 resource.yaml));
my $yaml = File::Spec->join($output_dir, $relative_yaml_path);
my $expected_yaml = File::Spec->join($expected_dir, $relative_yaml_path);
compare_ok(
    $yaml, $expected_yaml,
    'yaml looks as expected',
    filters => sub {
        my $o = shift;
        $o =~ s!fpkm_file: .+/genes.fpkm_tracking!fpkm_file: genes.fpkm_tracking!;
        return $o;
    }
);

done_testing;

sub get_rnaseq_build {
    my $tumor_sample = shift;

    my $pp = Genome::Test::Factory::ProcessingProfile::RnaSeq->setup_object();
    my $model = Genome::Test::Factory::Model::RnaSeq->setup_object(processing_profile_id => $pp->id);
    $model->subject($tumor_sample);
    my $build = Genome::Test::Factory::Build->setup_object(model_id => $model->id);
    is($build->class, "Genome::Model::Build::RnaSeq", 'rnaseq build looks ok');

    my $mock_build = Test::MockObject::Extends->new($build);
    $mock_build->mock('data_directory', sub {return $test_dir });
    return $mock_build;
}


