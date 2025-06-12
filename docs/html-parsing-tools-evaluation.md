# HTML Parsing Tools Evaluation

## Overview

This document evaluates HTML parsing tools for extracting API documentation from CAPI HTML files and generating OpenAPI specifications. The evaluation considers the project's current Perl-based toolchain and the specific requirements of parsing CAPI documentation.

## Evaluation Criteria

1. **Language Compatibility**: Integration with existing Perl toolchain
2. **HTML Parsing Capabilities**: Ability to handle complex HTML structures
3. **CSS Selector Support**: For targeting specific elements
4. **JSON Handling**: Parse and generate JSON from examples
5. **Performance**: Speed with large HTML files (~3MB)
6. **Error Handling**: Robustness and debugging features
7. **Extensibility**: Custom logic implementation
8. **Community Support**: Documentation and maintenance
9. **Learning Curve**: Ease of implementation

## Tool Analysis

### 1. Perl-Based Solutions

#### HTML::TreeBuilder + HTML::Element
**Pros**:
- Native Perl integration with existing toolchain
- Mature and stable library
- Good tree manipulation capabilities
- Part of HTML::Tree distribution

**Cons**:
- Verbose API for complex selections
- Limited CSS selector support without additional modules
- Manual JSON parsing required

**Score**: 7/10

#### Web::Scraper
**Pros**:
- Perl-native with DSL for scraping
- CSS selector support built-in
- Chainable operations
- Good for structured extraction

**Cons**:
- Less flexible for complex transformations
- Smaller community than HTML::TreeBuilder

**Score**: 8/10

#### Mojo::DOM
**Pros**:
- Modern Perl web toolkit
- Excellent CSS selector support
- jQuery-like API
- Built-in JSON support
- Fast C-based parser

**Cons**:
- Requires Mojolicious framework
- Larger dependency footprint

**Score**: 9/10

### 2. Python-Based Solutions

#### BeautifulSoup4
**Pros**:
- Most popular HTML parsing library
- Excellent documentation
- Multiple parser backends (lxml, html.parser)
- Forgiving with malformed HTML
- Great CSS selector support

**Cons**:
- Requires Python environment
- Integration overhead with Perl pipeline
- Slower than lxml for large files

**Score**: 8/10 (minus 2 for integration overhead)

#### lxml
**Pros**:
- Very fast (C-based)
- XPath and CSS selector support
- Standards compliant
- Good for large files

**Cons**:
- Requires Python environment
- Less forgiving with malformed HTML
- Steeper learning curve

**Score**: 7/10 (minus 2 for integration overhead)

### 3. Node.js-Based Solutions

#### Cheerio
**Pros**:
- jQuery-like server-side DOM manipulation
- Excellent CSS selector support
- Fast and lightweight
- Great for web developers
- Built-in JSON handling

**Cons**:
- Requires Node.js environment
- Integration overhead with Perl
- Not a full DOM implementation

**Score**: 8/10 (minus 2 for integration overhead)

#### Puppeteer
**Pros**:
- Full browser automation
- Handles JavaScript-rendered content
- Modern API

**Cons**:
- Overkill for static HTML
- Heavy resource usage
- Complex integration

**Score**: 4/10

### 4. Go-Based Solutions

#### goquery
**Pros**:
- jQuery-like syntax
- Fast performance
- Good for building CLI tools
- Could align with Go SDK generation

**Cons**:
- Requires Go environment
- Less mature ecosystem for web scraping
- Integration complexity

**Score**: 6/10

## Specific CAPI Requirements Analysis

### Required Capabilities:
1. **CSS Selectors**: 
   - `h4#definition + p code.prettyprint` for endpoint definitions
   - `div.highlight pre.highlight.json code` for JSON examples
   - Complex table parsing for parameters

2. **JSON Parsing**:
   - Extract and parse embedded JSON examples
   - Preserve structure for schema generation

3. **Text Processing**:
   - Extract method and path from definition
   - Parse parameter tables with type information
   - Handle nested HTML in descriptions

4. **Performance**:
   - Parse 3MB+ HTML files efficiently
   - Process ~200+ endpoints per file

## Recommendation

### Primary Choice: **Mojo::DOM** (Perl)

**Justification**:
1. **Native Perl Integration**: No additional language runtime needed
2. **Modern API**: jQuery-like selectors make code readable
3. **Performance**: C-based parser handles large files well
4. **JSON Support**: Built-in JSON modules
5. **Active Development**: Part of actively maintained Mojolicious
6. **Minimal Changes**: Can be integrated into existing `bin/gen` script

**Implementation Example**:
```perl
use Mojo::DOM;
use Mojo::JSON qw(decode_json);

my $dom = Mojo::DOM->new($html_content);

# Find all endpoints
$dom->find('h4#definition')->each(sub {
    my $definition = $_->next->find('code.prettyprint')->first->text;
    my ($method, $path) = split ' ', $definition;
    
    # Extract parameters
    my $params_table = $_->parent->find('table')->first;
    # ... process parameters
});
```

### Alternative Choice: **Web::Scraper** (Perl)

**When to Use**:
- If Mojolicious dependency is too heavy
- For simpler extraction patterns
- When DSL approach is preferred

### Hybrid Approach Consideration

For complex schema extraction from JSON examples, consider:
1. Use Mojo::DOM for HTML parsing
2. Use dedicated JSON Schema inference library
3. Keep all logic in Perl for consistency

## Migration Path

1. **Phase 1**: Implement Mojo::DOM parser alongside existing code
2. **Phase 2**: Test on single endpoint extraction
3. **Phase 3**: Expand to full document parsing
4. **Phase 4**: Integrate with schema generation
5. **Phase 5**: Add validation and error handling

## Conclusion

Mojo::DOM provides the best balance of:
- Integration ease with existing Perl toolchain
- Modern parsing capabilities
- Performance requirements
- Maintainability

This choice minimizes architectural changes while providing powerful parsing capabilities needed for accurate OpenAPI generation from CAPI HTML documentation.