# OpenAPI Specification for CAPI

This directory contains the OpenAPI specification for the CAPI v3 API.

## Flow
1. **Preparation**: Download the CAPI & OpenAPI specs of the designated versions into `specs/{capi,openapi}/{version}.html`.
    ```bash
    make prepare
    ```
2. **Generate Stubs**: Generate stubs for each CAPI endpoint as defined in the specifications.

3. Merge stubs into the CAPI OpenAPI specification.
    ```bash
    make gen-openapi-spec
    ```
   This will generate the files `capi/{version}.openapi.yaml` and then `capi/{version}.openapi.json`.

4. Generate a client, ex:
    ```bash
    make gen-go-client
    ```


## Resources

Refer to the following files for more information on specific endpoints and their implementations:
- [CAPI v3.181.0 Spec](https://v3-apidocs.cloudfoundry.org/version/3.181.0/index.html)
- [OpenAPI Spec](https://spec.openapis.org/oas/v3.1.1.html)
- [Learn OpenAPI](https://learn.openapis.org/)


