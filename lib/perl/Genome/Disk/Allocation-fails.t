#!/usr/bin/env genome-perl

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_COMMAND_DUMP_STATUS_MESSAGES} = 1;
    $ENV{UR_COMMAND_DUMP_DEBUG_MESSAGES} = 1;
};

use strict;
use warnings;

use above 'Genome';

use Test::Exception;
use Test::More tests => 2;

use_ok('Genome::Disk::Allocation') or die;

subtest 'fail to create in archive group' => sub{
    plan tests => 1;

    my $disk_group_name = 'mckinley';
    my $group = Genome::Disk::Group->__define__(disk_group_name => $disk_group_name);
    my @guard = Genome::Config::set_env('disk_group_archive', $disk_group_name);
    throws_ok(
        sub{ Genome::Disk::Allocation->create(mount_path => '/tmp', disk_group_name => $disk_group_name); },
        qr/Cannot create disk allocation in an archive group: $disk_group_name/,
        'failed to create in archive group',
    );

};

done_testing();
