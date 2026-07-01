# Psych

* https://github.com/ruby/psych
* https://docs.ruby-lang.org/en/master/Psych.html

## Description

Psych is a YAML parser and emitter.  Psych leverages
[libyaml](https://pyyaml.org/wiki/LibYAML) for its YAML parsing and emitting
capabilities.  In addition to wrapping libyaml, Psych also knows how to
serialize and de-serialize most Ruby objects to and from the YAML format.

## Examples

```ruby
# Safely load YAML in to a Ruby object
Psych.safe_load('--- foo') # => 'foo'

# Emit YAML from a Ruby object
Psych.dump("foo")     # => "--- foo\n...\n"
```

## Dependencies

* libyaml
* libfyaml (optional, only for the experimental `--enable-libfyaml` backend)

## Installation

Psych has been included with MRI since 1.9.2, and has been the default YAML parser
since 1.9.3.

If you want a newer gem release of Psych, you can use RubyGems:

```bash
gem install psych
```

Psych supported the static build with specific version of libyaml sources. You can build psych with libyaml-0.2.5 like this.

```bash
gem install psych -- --with-libyaml-source-dir=/path/to/libyaml-0.2.5
```

In order to use the gem release in your app, and not the stdlib version,
you'll need the following:

```ruby
gem 'psych'
require 'psych'
```

Or if you use Bundler add this to your `Gemfile`:

```ruby
gem 'psych'
```

JRuby ships with a pure Java implementation of Psych.

## Experimental libfyaml backend

Psych ships an experimental, opt-in backend built on
[libfyaml](https://github.com/pantoniou/libfyaml), a fully YAML 1.2 compliant
parser and emitter. It is compiled only when you explicitly pass
`--enable-libfyaml` at build time. Without the flag the default libyaml
backend is used and nothing changes.

```bash
# libfyaml and pkg-config must be installed first, for example:
#   apt-get install libfyaml-dev   # Debian/Ubuntu
#   brew install libfyaml          # macOS
gem install psych -- --enable-libfyaml
```

This backend is not supported on Windows.

Because libfyaml follows YAML 1.2, the YAML 1.1 booleans `yes`, `no`, `on`, and
`off` load as plain strings instead of `true`/`false` (only `true`/`false` are
booleans). This resolves the so-called "Norway problem", where the country
code `no` was parsed as `false`:

```ruby
Psych.load("country: no") # => {"country" => "no"}
```

You can check which backend is active:

```ruby
Psych::BACKEND         # => "libfyaml" (or "libyaml")
Psych.libfyaml_version # => "0.9.6"
```

The backend is experimental. Its output is valid YAML but is formatted
differently from libyaml in places, and a few emitter edge cases are not yet
matched. The default libyaml backend remains the supported choice.

Two more differences are worth knowing. Scalars emitted with the default
(`ANY`) style may be quoted or laid out differently from libyaml, so
byte-for-byte output is not guaranteed to match. On a parse error,
`Psych::SyntaxError#problem` carries libfyaml's full diagnostic message and
`Psych::SyntaxError#context` is always `nil`, whereas libyaml splits the
description across `#problem` and `#context`.

This backend targets YAML 1.2 compliance, not speed. In a rough
single-machine benchmark that loads and dumps in-memory documents, parsing
was roughly on par with libyaml (sometimes faster on string-heavy input),
while emitting was about 1.7x to 1.9x slower. Your numbers will vary, but the
shape holds: libfyaml is competitive at parsing and slower at emitting. Use
this backend when you need YAML 1.2 semantics. If throughput is your priority,
keep using the default libyaml backend.

## Release

We used the trusted publisher and [rubygems/release-gem](https://github.com/rubygems/release-gem) workflow.

We can release the new version with:

```bash
git tag vXXX && git push origin vXXX
```

## License

Copyright 2009 Aaron Patterson, et al.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the 'Software'), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
