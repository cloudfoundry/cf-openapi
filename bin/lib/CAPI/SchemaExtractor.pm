package CAPI::SchemaExtractor;

use v5.20;
use strict;
use warnings;
use Mojo::JSON qw(decode_json);
use Data::Dumper;

sub new {
    my $class = shift;
    my $self = {
        schemas => {},
        schema_counter => 0
    };
    bless $self, $class;
    return $self;
}

sub extract_and_reference_schema {
    my ($self, $example, $name_hint) = @_;
    
    return { type => 'null' } unless defined $example;
    
    # Generate schema from example
    my $schema = $self->infer_schema($example);
    
    # For complex objects, consider extracting as reusable schema
    if (ref $example eq 'HASH' && keys %$example > 3) {
        # Check if this looks like a resource object
        if ($example->{guid} && $example->{created_at} && $example->{updated_at}) {
            # This is likely a resource, extract it
            my $schema_name = $self->_generate_schema_name($name_hint, $example);
            $self->{schemas}{$schema_name} = $schema;
            
            return { '$ref' => "#/components/schemas/$schema_name" };
        }
    }
    
    return $schema;
}

sub infer_schema {
    my ($self, $example) = @_;
    
    return { type => 'null' } unless defined $example;
    
    if (ref $example eq 'HASH') {
        my $properties = {};
        my $required = [];
        
        for my $key (sort keys %$example) {
            $properties->{$key} = $self->infer_schema($example->{$key});
            
            # Consider field required if it's not null
            if (defined $example->{$key} && 
                (!ref $example->{$key} || 
                 (ref $example->{$key} eq 'HASH' && keys %{$example->{$key}}) ||
                 (ref $example->{$key} eq 'ARRAY' && @{$example->{$key}}))) {
                push @$required, $key;
            }
        }
        
        my $schema = {
            type => 'object',
            properties => $properties
        };
        
        $schema->{required} = $required if @$required;
        
        return $schema;
    }
    elsif (ref $example eq 'ARRAY') {
        if (@$example) {
            # Infer items schema from first element
            my $items_schema = $self->infer_schema($example->[0]);
            
            # Check if all items have same structure
            if (@$example > 1) {
                # Could implement more sophisticated array item type checking here
            }
            
            return {
                type => 'array',
                items => $items_schema
            };
        } else {
            return {
                type => 'array',
                items => { type => 'object' }
            };
        }
    }
    elsif (!defined $example) {
        return { type => 'null' };
    }
    elsif ($example =~ /^\d+$/) {
        return { type => 'integer' };
    }
    elsif ($example =~ /^-?\d+\.\d+$/) {
        return { type => 'number' };
    }
    elsif ($example =~ /^(true|false)$/i) {
        return { type => 'boolean' };
    }
    else {
        my $schema = { type => 'string' };
        
        # Add format hints based on patterns
        if ($example =~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z?$/) {
            $schema->{format} = 'date-time';
        }
        elsif ($example =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i) {
            $schema->{format} = 'uuid';
        }
        elsif ($example =~ /^https?:\/\//) {
            $schema->{format} = 'uri';
        }
        elsif ($example =~ /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/) {
            $schema->{format} = 'email';
        }
        
        # Add enum if the value looks like a constant
        if ($example =~ /^[A-Z][A-Z_]+$/) {
            # This might be an enum value
            # We could collect these and create proper enums later
        }
        
        return $schema;
    }
}

sub _generate_schema_name {
    my ($self, $hint, $example) = @_;
    
    # Try to determine a good name for the schema
    if ($hint && $hint =~ /^(get|post|patch|put|delete)_(.+)$/) {
        my $resource = $2;
        $resource =~ s/_/ /g;
        $resource =~ s/\b(\w)/uc($1)/eg;
        $resource =~ s/ //g;
        return $resource;
    }
    
    # Look for type hints in the object
    if ($example->{entity_type}) {
        return $self->_to_pascal_case($example->{entity_type});
    }
    
    if ($example->{type}) {
        return $self->_to_pascal_case($example->{type});
    }
    
    # Fallback to generic name
    $self->{schema_counter}++;
    return "Resource$self->{schema_counter}";
}

sub _to_pascal_case {
    my ($self, $str) = @_;
    $str =~ s/[_\s]+/ /g;
    $str =~ s/\b(\w)/uc($1)/eg;
    $str =~ s/ //g;
    return $str;
}

sub extract_common_schemas {
    my ($self, $endpoints) = @_;
    
    # Extract common patterns from endpoints
    my %field_patterns;
    my %object_patterns;
    
    for my $endpoint (@$endpoints) {
        # Analyze response schemas
        for my $status (keys %{$endpoint->{responses}}) {
            my $response = $endpoint->{responses}{$status};
            if ($response->{content} && $response->{content}{'application/json'}) {
                my $schema = $response->{content}{'application/json'}{schema};
                $self->_analyze_schema_patterns($schema, \%field_patterns, \%object_patterns);
            }
        }
    }
    
    # Create common schemas based on patterns
    $self->_create_common_schemas(\%field_patterns, \%object_patterns);
}

sub _analyze_schema_patterns {
    my ($self, $schema, $field_patterns, $object_patterns) = @_;
    
    return unless ref $schema eq 'HASH';
    
    if ($schema->{type} && $schema->{type} eq 'object' && $schema->{properties}) {
        my $props = $schema->{properties};
        
        # Check for common resource patterns
        if ($props->{guid} && $props->{created_at} && $props->{updated_at}) {
            # This looks like a resource
            my $signature = join(',', sort keys %$props);
            $object_patterns->{$signature}++;
        }
        
        # Track field patterns
        for my $field (keys %$props) {
            $field_patterns->{$field}++;
        }
        
        # Recurse into nested objects
        for my $prop (values %$props) {
            $self->_analyze_schema_patterns($prop, $field_patterns, $object_patterns);
        }
    }
    elsif ($schema->{type} && $schema->{type} eq 'array' && $schema->{items}) {
        $self->_analyze_schema_patterns($schema->{items}, $field_patterns, $object_patterns);
    }
}

sub _create_common_schemas {
    my ($self, $field_patterns, $object_patterns) = @_;
    
    # Create base resource schema if we see the pattern frequently
    if ($field_patterns->{guid} && $field_patterns->{guid} > 5) {
        $self->{schemas}{BaseResource} = {
            type => 'object',
            properties => {
                guid => { type => 'string', format => 'uuid' },
                created_at => { type => 'string', format => 'date-time' },
                updated_at => { type => 'string', format => 'date-time' }
            },
            required => ['guid', 'created_at', 'updated_at']
        };
    }
    
    # Create pagination schema if we see pagination patterns
    if ($field_patterns->{pagination} && $field_patterns->{pagination} > 3) {
        $self->{schemas}{Pagination} = {
            type => 'object',
            properties => {
                total_results => { type => 'integer' },
                total_pages => { type => 'integer' },
                first => {
                    type => 'object',
                    properties => {
                        href => { type => 'string', format => 'uri' }
                    }
                },
                last => {
                    type => 'object',
                    properties => {
                        href => { type => 'string', format => 'uri' }
                    }
                },
                next => {
                    type => 'object',
                    properties => {
                        href => { type => 'string', format => 'uri' }
                    }
                },
                previous => {
                    type => 'object',
                    properties => {
                        href => { type => 'string', format => 'uri' }
                    }
                }
            }
        };
    }
    
    # Create links schema
    if ($field_patterns->{links} && $field_patterns->{links} > 5) {
        $self->{schemas}{Links} = {
            type => 'object',
            properties => {
                self => {
                    type => 'object',
                    properties => {
                        href => { type => 'string', format => 'uri' }
                    }
                }
            },
            additionalProperties => {
                type => 'object',
                properties => {
                    href => { type => 'string', format => 'uri' },
                    method => { type => 'string', enum => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'] }
                }
            }
        };
    }
    
    # Create metadata schema
    if ($field_patterns->{metadata} && $field_patterns->{metadata} > 5) {
        $self->{schemas}{Metadata} = {
            type => 'object',
            properties => {
                labels => {
                    type => 'object',
                    additionalProperties => { type => 'string' }
                },
                annotations => {
                    type => 'object',
                    additionalProperties => { type => 'string' }
                }
            }
        };
    }
}

sub get_schemas {
    my $self = shift;
    return $self->{schemas};
}

1;