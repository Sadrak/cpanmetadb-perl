use strict;

use CPANMetaDB;
use CPAN::Common::Index::LocalPackage;
use CPAN::DistnameInfo;
use Plack::App::File;
use DBI;
use DBIx::Simple;
use DBD::SQLite;
use YAML;

my $base_ttl = 3600 * 24 * 3;
my $cache_dir = $ENV{CACHE} || './cache';
my $data_dir  = $ENV{DATA}  || './data';

my $root = Plack::App::File->new(file => "public/index.html")->to_app;
my $version = Plack::App::File->new(file => "public/versions/index.html")->to_app;

get '/' => [ $root ];
get '/versions/' => [ $version ];

get '/v1.0/package/:package' => sub {
    my($req, $params) = @_;

    my $ttl = $base_ttl + int(rand(3600 * 24));

    my $package = $params->{package};

    my $db = DBIx::Simple->connect("dbi:SQLite:dbname=$data_dir/metadb.sqlite3");
    my $res = $db->query(
        "SELECT package,version,distfile FROM packages WHERE distfile IN " .
        "(SELECT distfile FROM packages WHERE package=? LIMIT 1)",
        $package,
    );

    my @results = $res->hashes;
    $db->disconnect;

    my($result) = grep { $_->{package} eq $package } @results;

    unless ($result) {
        my $res = Plack::Response->new(404);
        $res->content_type('text/plain');
        $res->body("Not found\n");
        return $res;
    }

    my $dist = CPAN::DistnameInfo->new($result->{distfile})->dist;

    my $data = {
        distfile => $result->{distfile},
        version  => $result->{version},
        provides => {},
    };

    for my $row (@results) {
        $data->{provides}{$row->{package}} = $row->{version};
    }

    my $res = Plack::Response->new(200);
    $res->content_type('text/yaml');
    $res->header('Cache-Control' => 'max-age=1800');
    $res->body(YAML::Dump($data));
    $res;
};

sub _format_line {
    my(@row) = @_;

    # from PAUSE::mldistwatch::rewrite02
    my $one = 30;
    my $two = 8;
    if (length $row[0] > $one) {
        $one += 8 - length $row[1];
        $two = length $row[1];
    }

    sprintf "%-${one}s %${two}s  %s\n", @row;
}

get '/v1.0/history/:package' => sub {
    my($req, $params) = @_;

    my $package = $params->{package};

    my $db = DBIx::Simple->connect("dbi:SQLite:dbname=$data_dir/metadb.sqlite3");
    my $res = $db->query("SELECT package,version,distfile FROM packages_history WHERE package=?", $package);

    my $data = '';

    my @rows = $res->arrays;
    for my $row (@rows) {
        $data .= _format_line(@$row);
    }

    $db->disconnect;

    unless ($data) {
        my $res = Plack::Response->new(404);
        $res->content_type('text/plain');
        $res->body("Not found\n");
        return $res;
    }

    my $distfile = $rows[-1][2];
    my $dist = CPAN::DistnameInfo->new($distfile)->dist;

    my $res = Plack::Response->new(200);
    $res->content_type('text/plain');
    $res->header('Cache-Control' => 'max-age=1800');
    $res->body($data);
    $res;
};

use Plack::Builder;

builder {
    enable "Static",
      path => qr{\.(?:css|js|html)$}, root => 'public';
    app;
}
