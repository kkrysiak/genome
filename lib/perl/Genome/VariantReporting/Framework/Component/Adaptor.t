#!/usr/bin/env genome-perl

BEGIN { 
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::More;
use Test::Exception;
use Genome::VariantReporting::Framework::Plan::MasterPlan;
use Sub::Override;

my $pkg = 'Genome::VariantReporting::Framework::Component::Adaptor';
use_ok($pkg);

my $test_data_dir = __FILE__ . '.d';



subtest 'without translations needed - without translations provided' => sub {
    my $resource_provider = resource_provider_without_translations();
    my $adaptor = adaptor_without_translations($resource_provider);
    lives_ok { $adaptor->resolve_plan_attributes } 'resolve_plan_attributes execute successfully';
    is($adaptor->__planned__, 'foo', 'Value of __planned__ is as expected');
};

subtest 'without translations needed - with translations provided' => sub {
    my $resource_provider = resource_provider_with_translations();
    my $adaptor = adaptor_without_translations($resource_provider);
    lives_ok { $adaptor->resolve_plan_attributes } 'resolve_plan_attributes execute successfully';
    is($adaptor->__planned__, 'foo', 'Value of __planned__ is as expected');
};

subtest 'with translations needed - without translations provided' => sub {
    my $resource_provider = resource_provider_without_translations();
    my $adaptor = adaptor_with_translations($resource_provider);
    throws_ok(sub { $adaptor->resolve_plan_attributes }, 'NoTranslationsException', 'resolve_plan_attributes throws a NoTranslationsException error');
};

subtest 'with translations needed - with translations provided' => sub {
    my $resource_provider = resource_provider_with_translations();
    my $adaptor = adaptor_with_translations($resource_provider);
    lives_ok { $adaptor->resolve_plan_attributes } 'resolve_plan_attributes execute successfully';
    is($adaptor->__planned__, 'test sample name', 'Value of __planned__ is as expected');
};

subtest 'rethrow' => sub {
    my $override = Sub::Override->new(
        'Genome::VariantReporting::Framework::Component::RuntimeTranslations::_get_attribute',
        sub {
            use Exception::Class ('OtherNamedException');
            OtherNamedException->throw(error => 'some error message');
        }
    );

    my $resource_provider = resource_provider_with_translations();
    my $adaptor = adaptor_with_translations($resource_provider);
    throws_ok(sub { $adaptor->resolve_plan_attributes }, 'OtherNamedException', 'resolve_plan_attributes throws a OtherNamedException error');

    $override->restore;
};

subtest 'die' => sub {
    my $override = Sub::Override->new(
        'Genome::VariantReporting::Framework::Component::RuntimeTranslations::_get_attribute',
        sub {
            die 'some error message'
        }
    );

    my $resource_provider = resource_provider_with_translations();
    my $adaptor = adaptor_with_translations($resource_provider);
    throws_ok(sub { $adaptor->resolve_plan_attributes }, qr/some error message/, 'resolve_plan_attributes dies with correct error message');

    $override->restore;
};

done_testing;

sub resource_provider_with_translations {
    return Genome::VariantReporting::Framework::Component::RuntimeTranslations->create(
        attributes => {
            translations => { tumor => 'test sample name', __provided__ => '__provided__'},
        },
    );
}

sub resource_provider_without_translations {
    return Genome::VariantReporting::Framework::Component::RuntimeTranslations->create(
        attributes => {},
    );
}

sub adaptor_with_translations {
    my $resource_provider = shift;

    my $plan_with_translations = File::Spec->join($test_data_dir, 'with_translations_plan.yaml');
    return Genome::VariantReporting::Framework::Test::WithTranslationsAdaptor->create(
        provider_json => $resource_provider->as_json,
        plan_json => Genome::VariantReporting::Framework::Plan::MasterPlan->create_from_file($plan_with_translations)->as_json,
    );
}

sub adaptor_without_translations {
    my $resource_provider = shift;

    my $plan_without_translations = File::Spec->join($test_data_dir, 'plan.yaml');
    return Genome::VariantReporting::Framework::Test::Adaptor->create(
        provider_json => $resource_provider->as_json,
        plan_json => Genome::VariantReporting::Framework::Plan::MasterPlan->create_from_file($plan_without_translations)->as_json,
    );
}
