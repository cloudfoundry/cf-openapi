package CAPI::EdgeCaseHandler;

use v5.20;
use strict;
use warnings;
use Data::Dumper;

sub new {
    my $class = shift;
    my $self = {
        # Map of endpoints that need special handling
        polymorphic_endpoints => {
            'POST /v3/service_credential_bindings' => {
                discriminator => 'type',
                schemas => ['AppCredentialBinding', 'KeyCredentialBinding']
            },
            'POST /v3/packages' => {
                discriminator => 'type',
                schemas => ['BitsPackage', 'DockerPackage']
            }
        },
        # Endpoints with conditional parameters
        conditional_params => {
            'POST /v3/roles' => {
                user_specification => ['guid', 'username', 'username_and_origin']
            }
        },
        # Query parameters with special semantics
        special_query_params => {
            'label_selector' => {
                description => 'Label selector filter (comma-separated list uses AND logic, not OR)',
                type => 'string'
            },
            'stacks' => {
                description => 'Stack filter (use empty value to filter for NULL stacks)',
                allowEmptyValue => 1
            }
        },
        # Custom headers for specific endpoints
        custom_headers => {
            'POST /v3/packages/{guid}/upload' => [
                {
                    name => 'Content-Type',
                    in => 'header',
                    required => JSON::XS::true,
                    description => 'Must be multipart/form-data',
                    schema => {
                        type => 'string',
                        enum => ['multipart/form-data']
                    }
                }
            ],
            'POST /v3/apps/{guid}/actions/apply_manifest' => [
                {
                    name => 'Content-Type', 
                    in => 'header',
                    required => JSON::XS::true,
                    description => 'Must be application/x-yaml',
                    schema => {
                        type => 'string',
                        enum => ['application/x-yaml']
                    }
                }
            ]
        },
        # Endpoints with special request body handling
        special_request_bodies => {
            'POST /v3/packages/{guid}/upload' => {
                content => {
                    'multipart/form-data' => {
                        schema => {
                            type => 'object',
                            properties => {
                                bits => {
                                    type => 'string',
                                    format => 'binary',
                                    description => 'A binary zip file containing the package bits'
                                },
                                resources => {
                                    type => 'string',
                                    description => 'JSON array of cached resources'
                                }
                            },
                            required => ['bits']
                        }
                    }
                }
            },
            'POST /v3/apps/{guid}/actions/apply_manifest' => {
                content => {
                    'application/x-yaml' => {
                        schema => {
                            type => 'string',
                            description => 'YAML manifest content'
                        }
                    }
                }
            }
        }
    };
    bless $self, $class;
    return $self;
}

sub apply_edge_cases {
    my ($self, $endpoints, $components) = @_;
    
    for my $endpoint (@$endpoints) {
        my $key = uc($endpoint->{method}) . ' ' . $endpoint->{path};
        
        # Handle polymorphic endpoints
        if ($self->{polymorphic_endpoints}{$key}) {
            $self->_apply_polymorphic_schema($endpoint, $self->{polymorphic_endpoints}{$key}, $components);
        }
        
        # Handle conditional parameters
        if ($self->{conditional_params}{$key}) {
            $self->_apply_conditional_params($endpoint, $self->{conditional_params}{$key});
        }
        
        # Handle special query parameters
        $self->_apply_special_query_params($endpoint);
        
        # Handle timestamp parameters
        $self->_handle_timestamp_params($endpoint);
        
        # Handle custom headers
        $self->_apply_custom_headers($endpoint, $key);
        
        # Handle special request bodies
        $self->_apply_special_request_bodies($endpoint, $key);
    }
    
    # Create polymorphic schemas in components
    $self->_create_polymorphic_schemas($components);
}

sub _apply_polymorphic_schema {
    my ($self, $endpoint, $config, $components) = @_;
    
    return unless $endpoint->{requestBody};
    
    my $schema = $endpoint->{requestBody}{content}{'application/json'}{schema};
    return unless $schema;
    
    # Create oneOf schema with discriminator
    my @schemas;
    for my $schema_name (@{$config->{schemas}}) {
        push @schemas, { '$ref' => "#/components/schemas/$schema_name" };
    }
    
    $endpoint->{requestBody}{content}{'application/json'}{schema} = {
        oneOf => \@schemas,
        discriminator => {
            propertyName => $config->{discriminator}
        }
    };
}

sub _apply_conditional_params {
    my ($self, $endpoint, $config) = @_;
    
    # Add note about conditional parameters in description
    if ($endpoint->{description}) {
        $endpoint->{description} .= "\n\nNote: User can be specified by " . 
            join(', ', @{$config->{user_specification}}) . " (see parameter descriptions for details).";
    }
}

sub _apply_special_query_params {
    my ($self, $endpoint) = @_;
    
    return unless $endpoint->{parameters};
    
    for my $param (@{$endpoint->{parameters}}) {
        next unless $param->{in} eq 'query';
        
        if ($self->{special_query_params}{$param->{name}}) {
            my $special = $self->{special_query_params}{$param->{name}};
            
            # Override description and properties
            for my $key (keys %$special) {
                if ($key eq 'type') {
                    # Type goes in schema, not at parameter level
                    $param->{schema}{type} = $special->{$key};
                } else {
                    $param->{$key} = $special->{$key};
                }
            }
        }
    }
}

sub _handle_timestamp_params {
    my ($self, $endpoint) = @_;
    
    return unless $endpoint->{parameters};
    
    my @new_params;
    
    for my $param (@{$endpoint->{parameters}}) {
        if ($param->{name} =~ /^(.+_at)s?$/ && $param->{in} eq 'query') {
            my $base_name = $1;
            
            # Keep the original parameter for range format
            push @new_params, $param;
            
            # Add operator-based parameters
            for my $op (qw(gt gte lt lte)) {
                push @new_params, {
                    name => "${base_name}[$op]",
                    in => 'query',
                    description => "Filter by $base_name using $op operator",
                    schema => {
                        type => 'string',
                        format => 'date-time'
                    }
                };
            }
        } else {
            push @new_params, $param;
        }
    }
    
    $endpoint->{parameters} = \@new_params;
}

sub _apply_custom_headers {
    my ($self, $endpoint, $key) = @_;
    
    if ($self->{custom_headers}{$key}) {
        # Add custom headers to parameters
        $endpoint->{parameters} ||= [];
        push @{$endpoint->{parameters}}, @{$self->{custom_headers}{$key}};
    }
}

sub _apply_special_request_bodies {
    my ($self, $endpoint, $key) = @_;
    
    if ($self->{special_request_bodies}{$key}) {
        # Replace or set the request body
        $endpoint->{requestBody} = $self->{special_request_bodies}{$key};
    }
}

sub _create_polymorphic_schemas {
    my ($self, $components) = @_;
    
    # Create schema for AppCredentialBinding
    $components->{schemas}{AppCredentialBinding} = {
        type => 'object',
        required => ['type', 'relationships'],
        properties => {
            type => {
                type => 'string',
                enum => ['app'],
                description => 'Type of credential binding'
            },
            name => {
                type => 'string',
                description => 'Name of the service credential binding'
            },
            parameters => {
                type => 'object',
                description => 'Parameters to pass to the service broker'
            },
            relationships => {
                type => 'object',
                required => ['service_instance', 'app'],
                properties => {
                    service_instance => {
                        '$ref' => '#/components/schemas/ToOneRelationship'
                    },
                    app => {
                        '$ref' => '#/components/schemas/ToOneRelationship'
                    }
                }
            },
            metadata => {
                '$ref' => '#/components/schemas/Metadata'
            }
        }
    };
    
    # Create schema for KeyCredentialBinding
    $components->{schemas}{KeyCredentialBinding} = {
        type => 'object',
        required => ['type', 'relationships'],
        properties => {
            type => {
                type => 'string',
                enum => ['key'],
                description => 'Type of credential binding'
            },
            name => {
                type => 'string',
                description => 'Name of the service credential binding (required for key type)'
            },
            parameters => {
                type => 'object',
                description => 'Parameters to pass to the service broker'
            },
            relationships => {
                type => 'object',
                required => ['service_instance'],
                properties => {
                    service_instance => {
                        '$ref' => '#/components/schemas/ToOneRelationship'
                    },
                    app => {
                        '$ref' => '#/components/schemas/ToOneRelationship',
                        description => 'Optional app relationship for key bindings'
                    }
                }
            },
            metadata => {
                '$ref' => '#/components/schemas/Metadata'
            }
        }
    };
    
    # Create schema for BitsPackage
    $components->{schemas}{BitsPackage} = {
        type => 'object',
        required => ['type', 'relationships'],
        properties => {
            type => {
                type => 'string',
                enum => ['bits'],
                description => 'Package type for buildpack applications'
            },
            data => {
                type => 'object',
                description => 'Data for bits packages (usually empty)'
            },
            relationships => {
                type => 'object',
                required => ['app'],
                properties => {
                    app => {
                        '$ref' => '#/components/schemas/ToOneRelationship'
                    }
                }
            },
            metadata => {
                '$ref' => '#/components/schemas/Metadata'
            }
        }
    };
    
    # Create schema for DockerPackage
    $components->{schemas}{DockerPackage} = {
        type => 'object',
        required => ['type', 'data', 'relationships'],
        properties => {
            type => {
                type => 'string',
                enum => ['docker'],
                description => 'Package type for Docker images'
            },
            data => {
                type => 'object',
                required => ['image'],
                properties => {
                    image => {
                        type => 'string',
                        description => 'Docker image URL'
                    },
                    username => {
                        type => 'string',
                        description => 'Username for private Docker registry'
                    },
                    password => {
                        type => 'string',
                        description => 'Password for private Docker registry'
                    }
                }
            },
            relationships => {
                type => 'object',
                required => ['app'],
                properties => {
                    app => {
                        '$ref' => '#/components/schemas/ToOneRelationship'
                    }
                }
            },
            metadata => {
                '$ref' => '#/components/schemas/Metadata'
            }
        }
    };
    
    # Create helper schemas if not already present
    unless ($components->{schemas}{ToOneRelationship}) {
        $components->{schemas}{ToOneRelationship} = {
            type => 'object',
            required => ['data'],
            properties => {
                data => {
                    type => 'object',
                    required => ['guid'],
                    properties => {
                        guid => {
                            type => 'string',
                            format => 'uuid'
                        }
                    }
                }
            }
        };
    }
    
    unless ($components->{schemas}{Metadata}) {
        $components->{schemas}{Metadata} = {
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

1;