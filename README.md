# greenstatic.dev Website
The source code to [https://greenstatic.dev](https://greenstatic.dev).

## Build
### Dependencies
* Hugo (>= v0.74.1)
* GNU Make

### How to Build
```shell
# Development
make dev-server

# Production build
make build-prod url="https://greenstatic.dev"

# Development build
make build-dev url="http://localhost:1313"

# Build artifacts (HTML) is in ./public dir
```


## Special Template Features
### Blockquote
```
{{< blockquote source="John Doe 2020" >}}
Foo bar. 
{{< /blockquote >}}
```

### Code Snippet
List of [language support](https://gohugo.io/content-management/syntax-highlighting/#list-of-chroma-highlighting-languages)
```
{{< highlight python3 >}}
def main():
  print("Hello world")
{{< /highlight >}}
```
