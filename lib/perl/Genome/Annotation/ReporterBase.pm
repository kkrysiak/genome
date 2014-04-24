package Genome::Annotation::ReporterBase;

use strict;
use warnings FATAL => 'all';
use Genome;

class Genome::Annotation::ReporterBase {
    is => 'Genome::Annotation::ComponentBase',
    is_abstract => 1,
    has_transient_optional => [
        _output_fh => {},
    ],
};

sub name {
    die "abstract";
}

sub requires_interpreters {
    die "abstract - must return a list of one or more interpreter names";
}

sub initialize {
    my $self = shift;
    my $output_dir = shift;
    my $fh = Genome::Sys->open_file_for_writing(File::Spec->join($output_dir, $self->name));
    $self->_output_fh($fh);
    $self->print_headers;
}

sub finalize {
    my $self = shift;
    $self->_output_fh->close;
}

sub print_headers {
    #implement in subclass if you want to print a header
}
1;
