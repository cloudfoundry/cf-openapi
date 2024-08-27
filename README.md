# CF V3 API OpenAPI Specification Development

The rendered version can be accessed here: https://flothinkspi.github.io/cf-api-openapi-poc/

# Introduction

In this project, we are developing an OpenAPI Specification for the Cloud Foundry V3 API.
This is done outside the Cloud Foundry Foundation for now, but we aim to contribute the specification back to the foundation once in a usable/mature state.

The base specification is based on the [Cloud Foundry V3 API documentation](https://v3-apidocs.cloudfoundry.org/). 

## Conventions

1. We use lowerCamelCase for field names and operationIds as well as other yaml tokens.

# Development workflows

## Start a local development server

With below comand you can start a local development server that serves the OpenAPI Specification.
It supports hot reloading, so you can make changes to the `openapi.yaml` and see the changes immediately.
```bash
  yarn global add @lyra-network/openapi-dev-tool @redocly/cli
  # Linter
  redocly lint openapi.yaml 
  # Life reloading webui generated of the openapi.yaml(automatically restart on crash with while loop)
  while true; do openapi-dev-tool serve -c .openapi-dev-tool.config.json; done
```

## AI

To get a good query (to much tokens only usable with gemini-1.5-pro) for ai you can use the following command:
```bash
  cat ai/context.txt ai/CFV3Docu.txt openapi.yaml ai/command.txt | pbcopy
```

Then copy the resulting yaml to `tmp.yaml`
To merge snippets of OpenAPI Spec from `tmp.yaml` into `openapi.yaml`, run following command to merge it:
```bash
echo "$(yq eval '(.x-components) as $i ireduce({}; setpath($i | path; $i))' openapi.yaml | cat - tmp.yaml)" > tmp.yaml  && yq eval-all -i '. as $item ireduce ({}; . *+ $item)' openapi.yaml tmp.yaml &&  yq e -i '(... | select(type == "!!seq")) |= unique' openapi.yaml && echo "" > tmp.yaml && sed -i 's/!!merge //g' openapi.yaml
```
