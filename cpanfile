# Perl dependencies for CAPI OpenAPI generator

requires 'Mojolicious', '>= 9.0';
requires 'YAML::XS';
requires 'JSON::XS';
requires 'File::Slurp';
requires 'Data::Dumper';

# Additional dependencies for testing
requires 'JSON::Schema';
requires 'JSON::Schema::Modern';
requires 'LWP::UserAgent';
requires 'LWP::Protocol::https';
requires 'URI';
requires 'HTTP::Request';
requires 'Term::ANSIColor';