package Genome::InstrumentData::Gatk::BaseRecalibratorBamResult;

use strict;
use warnings;

use Genome;

use Genome::InstrumentData::Gatk::BaseRecalibratorResult;

# recalibrator result
#  bam [from indel realigner]
#  ref [fasta]
#  known_sites [knownSites]
#  > grp [gatk report file]
#
# print reads
#  bam [from indel realigner]
#  ref [fasta]
#  grp [from recalibrator]
#  > bam
class Genome::InstrumentData::Gatk::BaseRecalibratorBamResult { 
    is => 'Genome::InstrumentData::Gatk::BaseWithKnownSites',
    has_transient_optional => [
        base_recalibrator_result => { is => 'Genome::InstrumentData::Gatk::BaseRecalibratorResult', },
    ],
};

sub create {
    my $class = shift;

    my $self = $class->SUPER::create(@_);
    return if not $self;

    $self->status_message('Bam source: '.$self->bam_source->id);
    $self->status_message('Reference: '.$self->reference_build->id);
    $self->status_message('Knowns sites: '.$self->known_sites->id);

    my $base_recalibrator_result = $self->_get_or_crerate_base_recalibrator_result;
    return if not $base_recalibrator_result;

    my $print_reads = $self->_print_reads;
    return if not $print_reads;

    my $run_flagstat = $self->run_flagstat_on_output_bam_file;
    return if not $run_flagstat;

    my $allocation = $self->disk_allocations;
    eval { $allocation->reallocate };

    return $self;
}

sub _get_or_crerate_base_recalibrator_result {
    my $self = shift;
    $self->status_message('Get or create base recalibrator result...');

    my %base_recalibrator_params = (
        version => 2.4,
        bam_source => $self->bam_source,
        reference_build => $self->reference_build,
    );
    $base_recalibrator_params{known_sites} = [ $self->known_sites ] if $self->known_sites;

    my $base_recalibrator_result = Genome::InstrumentData::Gatk::BaseRecalibratorResult->get_or_create(%base_recalibrator_params);
    if ( not $base_recalibrator_result ) {
        $self->error_message('Failed to get or create base recalibrator result!');
        return;
    }
    $self->base_recalibrator_result($base_recalibrator_result);

    my $recalibration_table_file = $base_recalibrator_result->recalibration_table_file;
    if ( not -s $recalibration_table_file ) {
        $self->error_message('Got base recalibrator result, but failed to find the recalibration table file!');
        return;
    }
    $self->status_message('Recalibration table file: '.$recalibration_table_file);

    $self->status_message('Get or create base recalibrator result...done');
    return $base_recalibrator_result;
}

sub _print_reads {
    my $self = shift;
    $self->status_message('Print reads...');
            
    my $bam_file = $self->bam_file;
    my $print_reads = Genome::Model::Tools::Gatk::PrintReads->create(
        version => 2.4,
        input_bams => [ $self->input_bam_file ],
        reference_fasta => $self->reference_fasta,
        output_bam => $bam_file,
        bqsr => $self->base_recalibrator_result->recalibration_table_file,
    );
    if ( not $print_reads ) {
        $self->error_message('Failed to create print reads!');
        return;
    }
    if ( not $print_reads->execute ) {
        $self->error_message('Failed to execute print reads!');
        return;
    }

    if ( not -s $bam_file ) {
        $self->error_message('Ran print reads, but failed to create the output bam!');
        return;
    }
    $self->status_message('Bam file: '.$bam_file);

    $self->status_message('Print reads...done');
    return 1;
}

1;

