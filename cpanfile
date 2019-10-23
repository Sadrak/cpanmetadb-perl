requires 'Plack', '1.0041';
requires 'Plack::Request';
requires 'Router::Simple';
requires 'Digest::SHA';
requires 'File::Slurper';
requires 'CPAN::Common::Index', '0.006';
requires 'CPAN::DistnameInfo';

requires 'DBI';
requires 'DBD::SQLite';
requires 'DBIx::Simple';

requires 'Starman', 0.4015;
requires 'Server::Starter', 0.14;
requires 'Net::Server::SS::PreFork';

requires 'CPAN::DistnameInfo';

on test => sub {
    requires 'YAML';
};
