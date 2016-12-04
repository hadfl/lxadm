package LXadm::Config;

use strict;
use warnings;

use Illumos::Zones;
use Data::Processor;
use LXadm::Images;

# constants/programs
my $TEMPLATE = {
    zonename  => '',
    zonepath  => '',
    brand     => 'lx',
    'ip-type' => 'exclusive',
    net       => [
        {
            physical => '',
            gateway => '',
            ips      => [
                '',
            ],
            primary  => 'true',
        },
    ],
    attr      => [
        {
            name  => 'dns-domain',
            type  => 'string',
            value => '',
        },
        {
            name  => 'resolvers',
            type  => 'string',
            value => '',
        },
        {
            name  => 'kernel-version',
            type  => 'string',
            value => '',
        },
    ],
};

# constructor
sub new {
    my $class = shift;
    my $self = { @_ };

    $self->{zone} = Illumos::Zones->new(debug => $self->{debug});
    $self->{imgs} = LXadm::Images->new(debug => $self->{debug});

    my $schema    = $self->{zone}->schema;

    $self->{cfg}  = Data::Processor->new($schema); 
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

    my $zoneState = $self->{zone}->zoneState($lxName);

    $zoneState eq 'running'
        and die "ERROR: zone '$lxName' still running. use 'lxadm stop $lxName' to stop it first...\n";

    $zoneState ne 'configured' && $self->{zone}->uninstallZone($lxName);
    $self->{zone}->deleteZone($lxName);
}

sub writeConfig {
    my $self   = shift;
    my $lxName = shift;
    my $uuid   = shift;
    my $config = shift;

    $self->checkConfig($config);

    $self->{zone}->setZoneProperties($lxName, $config, ($uuid ? LXadm::Images->new()->cachePath . "/$uuid.gz" : ()));

    return 1;
}

sub readConfig {
    my $self   = shift;
    my $lxName = shift;

    my $config = $self->{zone}->getZoneProperties($lxName);

    return $config;
}

1;

