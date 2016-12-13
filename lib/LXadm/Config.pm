package LXadm::Config;

use strict;
use warnings;

use Illumos::Zones;
use Data::Processor;
use LXadm::Images;
use LXadm::Utils;

use Data::Dumper;

# constants/programs
my $TEMPLATE = {
    zonename  => '',
    zonepath  => '',
    brand     => 'lx',
    'ip-type' => 'exclusive',
    net       => [
        {
            physical => '',
            gateway  => '',
            ips      => [
                '',
            ],
            primary  => 'true',
        },
    ],
    'dns-domain' => '',
    resolvers    => [
        '',
    ],
    'kernel-version' => '',
};

my @SPECIALRES = qw(dns-domain resolvers kernel-version);

my $SCHEMA = sub {
    my $sv = LXadm::Utils->new();

    return {
    net     => {
        members => {
            physical => {
                validator => $sv->nicName($sv->nicName(Illumos::Zones->isGZ)),
            },
            over    => {
                optional    => 1,
                description => 'physical nic where vnic traffic goes over',
                example     => '"over" : "igb0"',
                validator   => $sv->regexp(qr/^[-\w]+$/),
            },
        },
    },
    'dns-domain'    => {
        optional    => 1,
        description => 'DNS search domain',
        example     => '"dns-domain" : "example.com"',
        validator   => sub { return undef; },
    },
    resolvers       => {
        optional    => 1,
        array       => 1,
        description => 'DNS resolvers',
        example     => '"resolvers" : [ "8.8.8.8", "8.8.4.4" ]',
        validator   => sub { return undef; },
    },
    'kernel-version' => {
        description => 'Kernel version',
        validator   => sub { return undef; },
    }
    } # return
};

# private methods
my $decodeRes = sub {
    my $self = shift;
    my $cfg  = shift;

    my $schema = $SCHEMA->();

    for (my $i = $#{$cfg->{attr}}; $i >= 0; $i--) {
        my $name = $cfg->{attr}->[$i]->{name};
        next if !grep { $_ eq $name } @SPECIALRES;

        $cfg->{$name} = $schema->{$name}->{array} ? [ split /,/, $cfg->{attr}->[$i]->{value} ]
                      : $cfg->{attr}->[$i]->{value};

        splice @{$cfg->{attr}}, $i, 1;
    }
    # check if attr is empty. if so remove it
    delete $cfg->{attr} if !@{$cfg->{attr}};

    # add VNIC over property
    return if !exists $cfg->{net};
    for my $vnic (@{$cfg->{net}}) {
        my $over = $self->{util}->getVNicOver($vnic->{physical});
        $vnic->{over} = $over if $over;
    }
};

my $encodeRes = sub {
    my $self = shift;
    my $cfg  = shift;

    my $schema = $SCHEMA->();

    $cfg->{attr} //= [];

    for my $res (@SPECIALRES) {
        my %elem = (
            name => $res,
            type => 'string',
        );

        $elem{value} = ref $cfg->{$res} eq 'ARRAY' ? join (',', @{$cfg->{$res}})
                     : $cfg->{$res};

        push @{$cfg->{attr}}, { %elem };
        delete $cfg->{$res};
    }

    # remove vnic over property
    delete $_->{over} for (@{$cfg->{net}});
};

# constructor
sub new {
    my $class = shift;
    my $self = { @_ };

    $self->{zone} = Illumos::Zones->new(debug => $self->{debug});
    $self->{imgs} = LXadm::Images->new(debug => $self->{debug});
    $self->{util} = LXadm::Utils->new();

    $self->{cfg}  = Data::Processor->new($self->{zone}->schema); 
    $self->{cfg}->merge_schema($SCHEMA->());

    return bless $self, $class;
}

sub getTemplate {
    my $self = shift;

    return { %$TEMPLATE };
}

sub checkConfig {
    my $self   = shift;
    my $config = shift;

    my $ec = $self->{cfg}->validate($config);
    $ec->count and die join ("\n", map { $_->stringify } @{$ec->{errors}}) . "\n";

    return 1;
}

sub removeLX {
    my $self   = shift;
    my $lxName = shift;
    my $opts   = shift;

    my $config    = $self->readConfig($lxName);
    my $zoneState = $self->{zone}->zoneState($lxName);

    $zoneState eq 'running'
        and die "ERROR: zone '$lxName' still running. use 'lxadm stop $lxName' to stop it first...\n";

    for (keys %$opts) {
        /^vnic$/ && do {
            $self->{util}->purgeVnic($config);
            next;
        };
    }

    $zoneState ne 'configured' && $self->{zone}->uninstallZone($lxName);
    $self->{zone}->deleteZone($lxName);
}

sub writeConfig {
    my $self   = shift;
    my $lxName = shift;
    my $uuid   = shift;
    my $config = shift;

    $self->checkConfig($config);
    $self->$encodeRes($config);

    $self->{zone}->setZoneProperties($lxName, $config, ($uuid ? $self->{imgs}->cachePath . "/$uuid.gz" : ()));

    return 1;
}

sub readConfig {
    my $self   = shift;
    my $lxName = shift;

    my $config = $self->{zone}->getZoneProperties($lxName);
    $self->$decodeRes($config);

    return $config;
}

sub listLX {
    my $self   = shift;
    my $lxName = shift;

    my $lxZones = $lxName ? [ $lxName ] : [ map { $_->{zonename} } grep { $_->{brand} eq 'lx' } @{$self->{zone}->listZones} ];

    # save a copy of $_ in $key as $_ gets modified in function
    return { map { my $key = $_; $key => $self->readConfig($_) } @$lxZones };
}

1;

__END__

=head1 NAME

LXadm::Config - lxadm config class

=head1 SYNOPSIS

use LXadm::Config;

=head1 DESCRIPTION

reads, writes and checkes lxadm configuration

=head1 COPYRIGHT

Copyright (c) 2016 by OETIKER+PARTNER AG. All rights reserved.

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see L<http://www.gnu.org/licenses/>.

=head1 AUTHOR

S<Dominik Hassler E<lt>hadfl@cpan.orgE<gt>>,

=head1 HISTORY

2016-12-13 had Initial Version

=cut
