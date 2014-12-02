package Genome::VariantReporting::Framework::Component::Reporter::SingleFile;

use strict;
use warnings FATAL => 'all';
use Genome;

class Genome::VariantReporting::Framework::Component::Reporter::SingleFile {
    is => 'Genome::VariantReporting::Framework::Component::Reporter',
    is_abstract => 1,
    has_transient_optional => [
        _output_fh => {
            is_structural => 1,
        },
    ],
};

sub can_be_combined {
    return 0;
}

sub combine_parameters {
    return {};
}

sub file_name {
    return 'report.txt';
}

sub report_path {
    my $self = shift;
    return File::Spec->join($self->output_dir, $self->file_name);
}

sub initialize {
    my $self = shift;
    $self->SUPER::initialize(@_);

    my $fh = Genome::Sys->open_file_for_writing(
        File::Spec->join($self->temp_staging_directory, $self->file_name));
    $self->_output_fh($fh);
    return;
}

sub finalize {
    my $self = shift;
    $self->SUPER::finalize(@_);

    $self->_output_fh->close;
    return;
}

1;
