use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use utf8;

# 1. Setup the API URL (Current House of Commons Members)
my $url = 'https://members-api.parliament.uk/api/Members/Search?House=1&IsCurrentMember=true&take=650';

my $ua = LWP::UserAgent->new;
$ua->agent("ParliamentPortalFetcher/1.0");

print "Fetching data from Parliament API...\n";
my $response = $ua->get($url);

if ($response->is_success) {
    # 2. Decode the incoming JSON
    my $raw_data = decode_json($response->decoded_content);
    my @mps;

    # 3. Simplify the data (ETL)
    # We only want what's necessary for the chart to keep the file small
    foreach my $item (@{$raw_data->{items}}) {
        my $value = $item->{value};
        push @mps, {
            id           => $value->{id},
            name         => $value->{nameDisplayAs},
            party        => $value->{latestParty}->{name},
            party_color  => $value->{latestParty}->{colour},
            constituency => $value->{latestHouseMembership}->{membershipFrom},
        };
    }

    # 4. Save to a local JSON file for the website to use
    my $json_out = encode_json(\@mps);
    open(my $fh, '>', 'public/members.json') or die "Could not open file: $!";
    print $fh $json_out;
    close $fh;

    print "Success! members.json updated with " . scalar(@mps) . " MPs.\n";
} else {
    die "API Request failed: " . $response->status_line;
}
