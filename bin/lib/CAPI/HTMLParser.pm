package CAPI::HTMLParser;

use v5.20;
use strict;
use warnings;
use Mojo::DOM;
use Mojo::JSON qw(decode_json);
use Data::Dumper;

sub new {
    my ($class, $html_content) = @_;
    my $self = {
        dom => Mojo::DOM->new($html_content),
        endpoints => [],
        components => {
            schemas => {},
            parameters => {},
            responses => {},
            securitySchemes => {}
        }
    };
    bless $self, $class;
    return $self;
}

sub _clean_text {
    my ($self, $text) = @_;
    return '' unless defined $text;
    
    # Replace smart quotes and other problematic characters with Unicode codes
    $text =~ s/\x{2019}/'/g;  # Right single quotation mark (')
    $text =~ s/\x{2018}/'/g;  # Left single quotation mark (')
    $text =~ s/\x{201C}/"/g;  # Left double quotation mark (")
    $text =~ s/\x{201D}/"/g;  # Right double quotation mark (")
    $text =~ s/\x{2014}/-/g;  # Em dash (—)
    $text =~ s/\x{2013}/-/g;  # En dash (–)
    $text =~ s/\x{2026}/.../g; # Ellipsis (…)
    
    # Also try with literal characters as fallback
    $text =~ s/'/'/g;
    $text =~ s/'/'/g;
    $text =~ s/"/"/g;
    $text =~ s/"/"/g;
    
    # Trim whitespace
    $text =~ s/^\s+|\s+$//g;
    
    return $text;
}

sub parse {
    my $self = shift;
    
    # Extract all endpoint sections
    $self->_extract_endpoints();
    
    # Extract common components
    $self->_extract_error_schemas();
    $self->_extract_common_parameters();
    
    return {
        endpoints => $self->{endpoints},
        components => $self->{components}
    };
}

sub _extract_endpoints {
    my $self = shift;
    my $dom = $self->{dom};
    
    # Find all definition h4 tags
    for my $def_h4 ($dom->find('h4')->each) {
        next unless $def_h4->attr('id') && $def_h4->attr('id') eq 'definition';
        
        # Get the resource name from the parent section
        my $resource_name = $self->_find_resource_name($def_h4);
        
        my $endpoint = $self->_parse_endpoint($def_h4, $resource_name);
        push @{$self->{endpoints}}, $endpoint if $endpoint;
    }
}

sub _find_resource_name {
    my ($self, $def_h4) = @_;
    
    # Walk up to find the h2 or h3 that contains the resource name
    my $current = $def_h4;
    while ($current = $current->parent) {
        # Check if there's an h2 in this section
        my $h2 = $current->at('h2');
        if ($h2 && $h2->attr('id') && $h2->attr('id') !~ /^(concepts|introduction|resources)$/) {
            return $self->_clean_text($h2->text);
        }
    }
    
    return 'Unknown';
}

sub _parse_endpoint {
    my ($self, $def_h4, $resource_name) = @_;
    
    # Get the method and path
    my $def_p = $def_h4->next;
    return unless $def_p && $def_p->tag eq 'p';
    
    my $code = $def_p->at('code.prettyprint');
    return unless $code;
    
    my $def_text = $self->_clean_text($code->text);
    my ($method, $path) = split /\s+/, $def_text, 2;
    return unless $method && $path;
    
    # Skip non-v3 paths (but keep /v3 itself)
    return if $path !~ m{^/v3} && $path ne '/';
    
    # Convert :param to {param} format
    $path =~ s/:([a-z_]+)/{$1}/g;
    
    my $endpoint = {
        method => lc($method),
        path => $path,
        resource => $resource_name,
        summary => $self->_find_summary($def_h4),
        description => $self->_find_description($def_h4),
        parameters => [],
        requestBody => undef,
        responses => {},
        security => [],
        tags => [$resource_name]
    };
    
    # Extract operation details
    $self->_extract_parameters($def_h4, $endpoint);
    $self->_extract_request_body($def_h4, $endpoint);
    $self->_extract_responses($def_h4, $endpoint);
    $self->_extract_security($def_h4, $endpoint);
    
    return $endpoint;
}

sub _find_summary {
    my ($self, $def_h4) = @_;
    
    # Look backwards for the h3 tag that contains the operation name
    my $current = $def_h4;
    while ($current = $current->previous) {
        if ($current->tag && $current->tag eq 'h3') {
            return $self->_clean_text($current->text);
        }
        # Stop if we hit another definition
        last if $current->tag && $current->tag eq 'h4' && 
                $current->attr('id') && $current->attr('id') eq 'definition';
    }
    
    return '';
}

sub _find_description {
    my ($self, $def_h4) = @_;
    
    # Find description paragraphs between h3 and definition
    my $desc = '';
    my $current = $def_h4;
    my @desc_parts;
    
    while ($current = $current->previous) {
        if ($current->tag) {
            if ($current->tag eq 'p') {
                unshift @desc_parts, $self->_clean_text($current->text);
            }
            elsif ($current->tag eq 'h3') {
                last;
            }
        }
    }
    
    return join(' ', @desc_parts);
}

sub _extract_parameters {
    my ($self, $def_h4, $endpoint) = @_;
    
    # Extract path parameters from the path
    while ($endpoint->{path} =~ /{([^}]+)}/g) {
        push @{$endpoint->{parameters}}, {
            name => $1,
            in => 'path',
            required => JSON::XS::true,
            schema => { type => 'string' },
            description => "The $1 identifier"
        };
    }
    
    # Find query parameters section
    my $current = $def_h4;
    while ($current = $current->next) {
        # Stop at next definition or major section
        last if $current->tag && $current->tag eq 'h4' && 
                $current->attr('id') && $current->attr('id') eq 'definition';
        last if $current->tag && $current->tag =~ /^h[123]$/;
        
        if ($current->tag && $current->tag eq 'h4') {
            my $text = $self->_clean_text($current->text || '');
            if ($text =~ /query parameters/i) {
                my $table = $current->next;
                while ($table && $table->tag ne 'table') {
                    $table = $table->next;
                }
                if ($table && $table->tag eq 'table') {
                    $self->_parse_parameter_table($table, 'query', $endpoint);
                }
            }
        }
    }
}

sub _extract_request_body {
    my ($self, $def_h4, $endpoint) = @_;
    
    # Skip GET requests
    return if $endpoint->{method} eq 'get';
    
    my $properties = {};
    my $required = [];
    
    my $current = $def_h4;
    while ($current = $current->next) {
        # Stop at next definition or major section
        last if $current->tag && $current->tag eq 'h4' && 
                $current->attr('id') && $current->attr('id') eq 'definition';
        last if $current->tag && $current->tag =~ /^h[123]$/;
        
        if ($current->tag && $current->tag eq 'h4') {
            my $text = $self->_clean_text($current->text || '');
            
            # Find required parameters
            if ($text =~ /required parameters/i) {
                my $table = $current->next;
                while ($table && $table->tag ne 'table') {
                    $table = $table->next;
                }
                if ($table && $table->tag eq 'table') {
                    $self->_parse_body_table($table, $properties, $required, 1);
                }
            }
            # Find optional parameters
            elsif ($text =~ /optional parameters/i) {
                my $table = $current->next;
                while ($table && $table->tag ne 'table') {
                    $table = $table->next;
                }
                if ($table && $table->tag eq 'table') {
                    $self->_parse_body_table($table, $properties, $required, 0);
                }
            }
        }
    }
    
    if (keys %$properties) {
        # Find example request
        my $example = $self->_find_request_example($def_h4);
        
        $endpoint->{requestBody} = {
            required => scalar(@$required) > 0 ? JSON::XS::true : JSON::XS::false,
            content => {
                'application/json' => {
                    schema => {
                        type => 'object',
                        properties => $properties,
                        required => $required
                    }
                }
            }
        };
        
        if ($example) {
            $endpoint->{requestBody}{content}{'application/json'}{example} = $example;
        }
    }
}

sub _extract_responses {
    my ($self, $def_h4, $endpoint) = @_;
    
    # Find example response
    my $current = $def_h4;
    my $found_example = 0;
    
    while ($current = $current->next) {
        # Stop at next definition or major section
        last if $current->tag && $current->tag eq 'h4' && 
                $current->attr('id') && $current->attr('id') eq 'definition';
        last if $current->tag && $current->tag =~ /^h[123]$/;
        
        if ($current->tag && $current->tag eq 'div' && 
            $current->attr('class') && $current->attr('class') =~ /highlight/) {
            my $code = $current->at('code');
            if ($code && $self->_clean_text($code->text) =~ /Example Response/) {
                # Next highlight block should be the response
                my $response_block = $current->next;
                while ($response_block && (!$response_block->tag || $response_block->tag ne 'div' ||
                       !$response_block->attr('class') || $response_block->attr('class') !~ /highlight/)) {
                    $response_block = $response_block->next;
                }
                
                if ($response_block) {
                    my $response_code = $response_block->at('code');
                    if ($response_code) {
                        $self->_parse_response($response_code->text, $endpoint);
                        $found_example = 1;
                    }
                }
            }
        }
    }
    
    # Extract error responses
    $self->_extract_error_responses($def_h4, $endpoint);
    
    # Add default response if none found
    unless ($found_example || keys %{$endpoint->{responses}}) {
        $endpoint->{responses}{'200'} = {
            description => 'Success'
        };
    }
}

sub _parse_response {
    my ($self, $response_text, $endpoint) = @_;
    
    # Parse HTTP status and body
    if ($response_text =~ /HTTP\/\d+\.\d+\s+(\d+)\s+(.+?)[\r\n]/) {
        my $status = $1;
        my $status_text = $2;
        
        # Extract JSON body
        my $json_start = index($response_text, '{');
        if ($json_start >= 0) {
            my $json_text = substr($response_text, $json_start);
            # Try to parse JSON
            my $example = eval { decode_json($json_text) };
            
            if ($example) {
                $endpoint->{responses}{$status} = {
                    description => $status_text,
                    content => {
                        'application/json' => {
                            schema => $self->_infer_schema($example),
                            example => $example
                        }
                    }
                };
            } else {
                # Failed to parse, just add description
                $endpoint->{responses}{$status} = {
                    description => $status_text
                };
            }
        } else {
            # No JSON body
            $endpoint->{responses}{$status} = {
                description => $status_text
            };
        }
    }
}

sub _extract_error_responses {
    my ($self, $def_h4, $endpoint) = @_;
    
    my $current = $def_h4;
    while ($current = $current->next) {
        # Stop at next definition or major section
        last if $current->tag && $current->tag eq 'h4' && 
                $current->attr('id') && $current->attr('id') eq 'definition';
        last if $current->tag && $current->tag =~ /^h[123]$/;
        
        if ($current->tag && $current->tag eq 'h4') {
            my $text = $self->_clean_text($current->text || '');
            if ($text =~ /potential errors/i) {
                my $table = $current->next;
                while ($table && $table->tag ne 'table') {
                    $table = $table->next;
                }
                if ($table && $table->tag eq 'table') {
                    for my $tr ($table->find('tr')->each) {
                        my @cells = $tr->find('td')->each;
                        next unless @cells >= 3;
                        
                        my $title = $cells[0]->text;
                        my $code = $cells[1]->text;
                        my $status = $cells[2]->text;
                        my $desc = $cells[3] ? $cells[3]->text : '';
                        
                        $endpoint->{responses}{$status} ||= {
                            description => $desc || "Error: $title",
                            content => {
                                'application/json' => {
                                    schema => {
                                        '$ref' => '#/components/schemas/Error'
                                    }
                                }
                            }
                        };
                    }
                }
                last;
            }
        }
    }
}

sub _extract_security {
    my ($self, $def_h4, $endpoint) = @_;
    
    my $current = $def_h4;
    while ($current = $current->next) {
        # Stop at next definition or major section
        last if $current->tag && $current->tag eq 'h4' && 
                $current->attr('id') && $current->attr('id') eq 'definition';
        last if $current->tag && $current->tag =~ /^h[123]$/;
        
        if ($current->tag && $current->tag eq 'h4') {
            my $text = $self->_clean_text($current->text || '');
            if ($text =~ /permitted roles/i) {
                my $table = $current->next;
                while ($table && $table->tag ne 'table') {
                    $table = $table->next;
                }
                if ($table && $table->tag eq 'table') {
                    my @roles;
                    for my $tr ($table->find('tr')->each) {
                        for my $td ($tr->find('td')->each) {
                            push @roles, $td->text;
                        }
                    }
                    
                    # Add bearer auth security
                    push @{$endpoint->{security}}, { bearerAuth => [] };
                    
                    # Store roles as custom extension
                    $endpoint->{'x-required-roles'} = \@roles if @roles;
                }
                last;
            }
        }
    }
}

sub _parse_parameter_table {
    my ($self, $table, $in_type, $endpoint) = @_;
    
    for my $tr ($table->find('tr')->each) {
        my @cells = $tr->find('td')->each;
        next unless @cells >= 2;
        
        my $name_elem = $cells[0]->at('strong');
        next unless $name_elem;
        
        my $name = $self->_clean_text($name_elem->text);
        my $type_elem = $cells[1]->at('em');
        my $type = $type_elem ? $self->_clean_text($type_elem->text) : 'string';
        
        my $param = {
            name => $name,
            in => $in_type,
            required => JSON::XS::false,
            schema => $self->_type_to_schema($type),
            description => $cells[2] ? $self->_clean_text($cells[2]->text) : ''
        };
        
        push @{$endpoint->{parameters}}, $param;
    }
}

sub _parse_body_table {
    my ($self, $table, $properties, $required, $is_required) = @_;
    
    for my $tr ($table->find('tr')->each) {
        my @cells = $tr->find('td')->each;
        next unless @cells >= 2;
        
        my $name_elem = $cells[0]->at('strong');
        next unless $name_elem;
        
        my $name = $self->_clean_text($name_elem->text);
        my $type_elem = $cells[1]->at('em');
        my $type = $type_elem ? $self->_clean_text($type_elem->text) : 'string';
        
        # Handle nested properties
        my @parts = split /\./, $name;
        my $current = $properties;
        
        for (my $i = 0; $i < @parts - 1; $i++) {
            $current->{$parts[$i]} ||= {
                type => 'object',
                properties => {}
            };
            $current = $current->{$parts[$i]}{properties};
        }
        
        my $prop_name = $parts[-1];
        $current->{$prop_name} = $self->_type_to_schema($type);
        $current->{$prop_name}{description} = $self->_clean_text($cells[2]->text) if $cells[2];
        
        if ($is_required && @parts == 1) {
            push @$required, $name;
        }
    }
}

sub _type_to_schema {
    my ($self, $type) = @_;
    
    # Handle common types
    my %type_map = (
        'string' => { type => 'string' },
        'integer' => { type => 'integer' },
        'number' => { type => 'number' },
        'boolean' => { type => 'boolean' },
        'object' => { type => 'object' },
        'array' => { type => 'array', items => { type => 'string' } },
        'datetime' => { type => 'string', format => 'date-time' },
        'uuid' => { type => 'string', format => 'uuid' },
        'to-one relationship' => {
            type => 'object',
            properties => {
                data => {
                    type => 'object',
                    properties => {
                        guid => { type => 'string', format => 'uuid' }
                    }
                }
            }
        },
        'to-many relationship' => {
            type => 'object',
            properties => {
                data => {
                    type => 'array',
                    items => {
                        type => 'object',
                        properties => {
                            guid => { type => 'string', format => 'uuid' }
                        }
                    }
                }
            }
        }
    );
    
    return $type_map{$type} || { type => 'string' };
}

sub _find_request_example {
    my ($self, $def_h4) = @_;
    
    my $current = $def_h4;
    while ($current = $current->next) {
        # Stop at next definition or major section
        last if $current->tag && $current->tag eq 'h4' && 
                $current->attr('id') && $current->attr('id') eq 'definition';
        last if $current->tag && $current->tag =~ /^h[123]$/;
        
        if ($current->tag && $current->tag eq 'div' && 
            $current->attr('class') && $current->attr('class') =~ /highlight/) {
            my $code = $current->at('code');
            if ($code && $code->text =~ /Example Request/) {
                # Next highlight block should be the curl command
                my $curl_block = $current->next;
                while ($curl_block && (!$curl_block->tag || $curl_block->tag ne 'div' ||
                       !$curl_block->attr('class') || $curl_block->attr('class') !~ /highlight/)) {
                    $curl_block = $curl_block->next;
                }
                
                if ($curl_block) {
                    my $curl_code = $curl_block->at('code');
                    if ($curl_code) {
                        my $curl_text = $curl_code->text;
                        # Extract JSON from curl command
                        if ($curl_text =~ /-d\s*'({.+?})'/s) {
                            my $json_text = $1;
                            my $example = eval { decode_json($json_text) };
                            return $example if $example;
                        }
                    }
                }
            }
        }
    }
    
    return undef;
}

sub _infer_schema {
    my ($self, $example) = @_;
    
    return { type => 'null' } unless defined $example;
    
    if (ref $example eq 'HASH') {
        my $properties = {};
        my $required = [];
        
        for my $key (keys %$example) {
            $properties->{$key} = $self->_infer_schema($example->{$key});
            push @$required, $key if defined $example->{$key};
        }
        
        return {
            type => 'object',
            properties => $properties,
            required => $required
        };
    }
    elsif (ref $example eq 'ARRAY') {
        return {
            type => 'array',
            items => @$example ? $self->_infer_schema($example->[0]) : { type => 'string' }
        };
    }
    elsif ($example =~ /^\d+$/) {
        return { type => 'integer' };
    }
    elsif ($example =~ /^\d+\.\d+$/) {
        return { type => 'number' };
    }
    elsif ($example =~ /^(true|false)$/i) {
        return { type => 'boolean' };
    }
    else {
        my $schema = { type => 'string' };
        
        # Add format hints
        if ($example =~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/) {
            $schema->{format} = 'date-time';
        }
        elsif ($example =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i) {
            $schema->{format} = 'uuid';
        }
        
        return $schema;
    }
}

sub _extract_error_schemas {
    my $self = shift;
    
    # Define common error schema
    $self->{components}{schemas}{Error} = {
        type => 'object',
        properties => {
            errors => {
                type => 'array',
                items => {
                    type => 'object',
                    properties => {
                        code => { type => 'integer' },
                        title => { type => 'string' },
                        detail => { type => 'string' }
                    },
                    required => ['code', 'title', 'detail']
                }
            }
        },
        required => ['errors']
    };
}

sub _extract_common_parameters {
    my $self = shift;
    
    # Define common query parameters
    $self->{components}{parameters} = {
        Page => {
            name => 'page',
            in => 'query',
            description => 'Page number',
            schema => { type => 'integer', minimum => 1 }
        },
        PerPage => {
            name => 'per_page',
            in => 'query',
            description => 'Number of results per page',
            schema => { type => 'integer', minimum => 1, maximum => 5000 }
        },
        OrderBy => {
            name => 'order_by',
            in => 'query',
            description => 'Field to sort by',
            schema => { type => 'string' }
        },
        LabelSelector => {
            name => 'label_selector',
            in => 'query',
            description => 'Label selector (comma-separated list for AND)',
            schema => { type => 'string' }
        }
    };
}

1;