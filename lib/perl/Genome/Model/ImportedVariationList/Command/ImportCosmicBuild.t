#!/usr/bin/env genome-perl
use strict;
use warnings;
use above "Genome";
use Test::More;

use Genome::Test::Factory::AnalysisProject;

Genome::Report::Email->silent();

$ENV{UR_DBI_NO_COMMIT} = 1;
$ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;

use_ok("Genome::Model::ImportedVariationList::Command::ImportCosmicBuild");

Genome::Config::set_env('workflow_builder_backend', 'inline');
Genome::Test::Factory::AnalysisProject->setup_system_analysis_project;
my $reference_sequence_build = Genome::Model::Build::ReferenceSequence->get_by_name('g1k-human-build37');

my $version = 66;
my $data_url = Genome::Config::get('test_url').'/Genome-Db-Cosmic-Command-Import-Vcf/v1';
print "$data_url\n";
my $import_cosmic_build = Genome::Model::ImportedVariationList::Command::ImportCosmicBuild->create(
    vcf_file_urls => ["$data_url/Coding.vcf.gz","$data_url/NonCoding.vcf.gz"],
    version => $version,
    reference_sequence_build => $reference_sequence_build,
);

# The kB requested is hard-coded at 20GB but the test does not need
# to make a 20GB allocation.
*Genome::Model::ImportedVariationList::Command::ImportCosmicBuild::kilobytes_requested
    = sub { return 5_000 };

ok($import_cosmic_build->execute(), "Cosmic build import completed");

my $build = $import_cosmic_build->build;
isa_ok($build, "Genome::Model::Build::ImportedVariationList");

ok($build->snv_result, "The build has a snv result attached to it");
is($build->version, $version);
is($build->source_name, "cosmic", "Source name is set properly");
ok($build->snvs_vcf, "The build has a vcf");
ok(-s $build->snvs_vcf, "The snvs vcf has size");

done_testing();
