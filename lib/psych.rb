# frozen_string_literal: true
require 'psych/versions'
case RUBY_ENGINE
when 'jruby'
  require 'psych_jars'
  if JRuby::Util.respond_to?(:load_ext)
    JRuby::Util.load_ext('org.jruby.ext.psych.PsychLibrary')
  else
    require 'java'; require 'jruby'
    org.jruby.ext.psych.PsychLibrary.new.load(JRuby.runtime, false)
  end
else
  require 'psych.so'
end
require 'psych/nodes'
require 'psych/streaming'
require 'psych/visitors'
require 'psych/handler'
require 'psych/tree_builder'
require 'psych/parser'
require 'psych/omap'
require 'psych/set'
require 'psych/coder'
require 'psych/core_ext'
require 'psych/stream'
require 'psych/json/tree_builder'
require 'psych/json/stream'
require 'psych/handlers/document_stream'
require 'psych/class_loader'

# = \YAML
#
# \YAML is a human- and machine-readable text format for data structures.
#
# Details available at website yaml.org:
# - {Specification for YAML version 1.2}[https://yaml.org/spec/1.2/spec.html].
# - {Conversion}[https://yaml.org/YAML_for_ruby.html] between \YAML and Ruby.
#
# = Overview
#
# \Psych is a \YAML parser and emitter.
# that leverages {LibYAML}[https://pyyaml.org/wiki/LibYAML] for its \YAML parsing
# and emitting capabilities:
# - \Psych parsing can de-serializes \YAML documents into Ruby objects.
# - \Psych emitting can serialize Ruby objects into \YAML documents.
#
#
# = I NEED TO PARSE OR EMIT YAML RIGHT NOW!
#
#   # Parse some YAML
#   Psych.load("--- foo") # => "foo"
#
#   # Emit some YAML
#   Psych.dump("foo")     # => "--- foo\n...\n"
#   { :a => 'b'}.to_yaml  # => "---\n:a: b\n"
#
# = \Psych
#
# \Psych provides a range of interfaces for parsing and emitting \YAML:
# - {High-level API}[#module-Psych-label-High-level+API]: ability to convert directly between \YAML and Ruby objects.
# - {Mid-level API}[#module-Psych-label-Mid-level+API]: access to the raw \YAML AST (Abstract Syntax Tree).
# - {Low-level API}[#module-Psych-label-Low-level+API]: access to the event-based parser and emitter.
#
# == High-level API
#
# The high-level \Psych API supports direct conversion between \YAML and Ruby objects.
#
# === Parsing
#
# Assume:
#   yaml = <<-EOT
#   ---
#   - foo
#   - bar
#   - baz
#   EOT
#
# Use method Psych.load to convert a \YAML \String to Ruby objects:
#   Psych.load(yaml) # => ["foo", "bar", "baz"]
#
# Use method Psych.load_file to parse \File content to Ruby objects:
#   File.write('t.yml', yaml)
#   Psych.load_file('t.yml') # => ["foo", "bar", "baz"]
#
# There is also a method for parsing multiple \YAML documents in a single \String.
# See Psych.load_stream.
#
# === Emitting
#
# Assume:
#   ruby = ["foo", "bar", "baz"]
#
# Use method Psych.dump to convert Ruby objects to a \YAML \String:
#   Psych.dump(ruby) # => "---\n- foo\n- bar\n- baz\n"
#
# An optional second argument can direct the output to an \IO stream:
#   File.open('t.yml', 'w') do |file|
#     Psych.dump(ruby, file)
#   end
#   File.read('t.yml') # => "---\n- foo\n- bar\n- baz\n"
#
# There are options available for formatting the \YAML output.
# See Psych.dump.
#
# There is no direct API for dumping \YAML data to a file,
# but you can do this:
#   File.open('t.yml', 'w') do |file|
#     file.write(Psych.dump(ruby))
#   end
#   File.read('t.yml')
#
# There is also a method for emitting multiple Ruby objects
# as separate \YAML documents in a single document stream.
# See Psych.dump_stream.
#
# == Mid-level API
#
# === Parsing
#
# Psych provides access to an AST produced from parsing a YAML document.  This
# tree is built using the Psych::Parser and Psych::TreeBuilder.  The AST can
# be examined and manipulated freely.  Please see Psych::parse_stream,
# Psych::Nodes, and Psych::Nodes::Node for more information on dealing with
# YAML syntax trees.
#
# ==== Reading from a string
#
#   # Returns Psych::Nodes::Stream
#   Psych.parse_stream("---\n - a\n - b")
#
#   # Returns Psych::Nodes::Document
#   Psych.parse("---\n - a\n - b")
#
# ==== Reading from a file
#
#   # Returns Psych::Nodes::Stream
#   Psych.parse_stream(File.read('database.yml'))
#
#   # Returns Psych::Nodes::Document
#   Psych.parse_file('database.yml')
#
# ==== Exception handling
#
#   begin
#     # The second argument changes only the exception contents
#     Psych.parse("--- `", "file.txt")
#   rescue Psych::SyntaxError => ex
#     ex.file    # => 'file.txt'
#     ex.message # => "(file.txt): found character that cannot start any token"
#   end
#
# === Emitting
#
# At the mid level is building an AST.  This AST is exactly the same as the AST
# used when parsing a YAML document.  Users can build an AST by hand and the
# AST knows how to emit itself as a YAML document.  See Psych::Nodes,
# Psych::Nodes::Node, and Psych::TreeBuilder for more information on building
# a YAML AST.
#
# ==== Writing to a string
#
#   # We need Psych::Nodes::Stream (not Psych::Nodes::Document)
#   stream = Psych.parse_stream("---\n - a\n - b")
#
#   stream.to_yaml # => "---\n- a\n- b\n"
#
# ==== Writing to a file
#
#   # We need Psych::Nodes::Stream (not Psych::Nodes::Document)
#   stream = Psych.parse_stream(File.read('database.yml'))
#
#   File.open('database.yml', 'w') do |file|
#     file.write(stream.to_yaml)
#   end
#
# == Low-level API
#
# === Parsing
#
# The lowest level parser should be used when the YAML input is already known,
# and the developer does not want to pay the price of building an AST or
# automatic detection and conversion to Ruby objects.  See Psych::Parser for
# more information on using the event based parser.
#
# ==== Reading to Psych::Nodes::Stream structure
#
#   parser = Psych::Parser.new(TreeBuilder.new) # => #<Psych::Parser>
#   parser = Psych.parser                       # it's an alias for the above
#
#   parser.parse("---\n - a\n - b")             # => #<Psych::Parser>
#   parser.handler                              # => #<Psych::TreeBuilder>
#   parser.handler.root                         # => #<Psych::Nodes::Stream>
#
# ==== Receiving an events stream
#
#   recorder = Psych::Handlers::Recorder.new
#   parser = Psych::Parser.new(recorder)
#
#   parser.parse("---\n - a\n - b")
#   recorder.events # => [list of [event, args] lists]
#                   # event is one of: Psych::Handler::EVENTS
#                   # args are the arguments passed to the event
#
# === Emitting
#
# The lowest level emitter is an event based system.  Events are sent to a
# Psych::Emitter object.  That object knows how to convert the events to a YAML
# document.  This interface should be used when document format is known in
# advance or speed is a concern.  See Psych::Emitter for more information.
#
# ==== Writing to a Ruby structure
#
#   Psych.parser.parse("--- a")       # => #<Psych::Parser>
#
#   parser.handler.first              # => #<Psych::Nodes::Stream>
#   parser.handler.first.to_ruby      # => ["a"]
#
#   parser.handler.root.first         # => #<Psych::Nodes::Document>
#   parser.handler.root.first.to_ruby # => "a"
#
#   # You can instantiate an Emitter manually
#   Psych::Visitors::ToRuby.new.accept(parser.handler.root.first)
#   # => "a"

module Psych
  # The version of libyaml Psych is using
  LIBYAML_VERSION = Psych.libyaml_version.join '.'
  # Deprecation guard
  NOT_GIVEN = Object.new
  private_constant :NOT_GIVEN

  # :call-seq:
  #   Psych.load(yaml_string, **options) -> object
  #
  # Returns the Ruby object created by converting the given +yaml_string+
  # to a Ruby object:
  #   Psych.load('--- a')             # => 'a'
  #   Psych.load("---\n - a\n - b")   # => ['a', 'b']
  #
  # Use option +fallback+ to specify a value to be returned if +yaml_string+ is empty;
  # the default is +false+:
  #   Psych.load('') # => false
  #   Psych.load('', fallback: nil) # => nil
  #
  # Use option +symbolize_names+ to specify that \Hash keys should be Symbols;
  # the default is +false+:
  #   Psych.load('foo: 0') # => {"foo"=>0}
  #   Psych.load('foo: 0', symbolize_names: true) # => {:foo=>0}
  #
  # Use option +freeze+ to specify that the returned object should be frozen;
  # the default is +false+:
  #   Psych.load('--- a').frozen? # => false
  #   Psych.load('--- a', freeze: true).frozen? # => true
  #
  # Use option +filename+ to specify a \String to be included in the message
  # for a raised exception:
  # the default is +nil+:
  #   begin
  #     Psych.load("--- `", filename: 'foo')
  #   rescue Psych::SyntaxError => ex
  #     p ex.file
  #     p ex.message
  #   end
  # Output:
  # "foo"
  # "(foo): found character that cannot start any token while scanning for the next token at line 1 column 5"
  #
  # Note: DO NOT use this method to parse untrusted documents, such as
  # \YAML documents that are supplied via user input.  Instead, use method Psych.safe_load.
  def self.load yaml, legacy_filename = NOT_GIVEN, filename: nil, fallback: false, symbolize_names: false, freeze: false
    if legacy_filename != NOT_GIVEN
      warn_with_uplevel 'Passing filename with the 2nd argument of Psych.load is deprecated. Use keyword argument like Psych.load(yaml, filename: ...) instead.', uplevel: 1 if $VERBOSE
      filename = legacy_filename
    end

    result = parse(yaml, filename: filename)
    return fallback unless result
    result = result.to_ruby(symbolize_names: symbolize_names, freeze: freeze) if result
    result
  end

  ###
  # Safely load the yaml string in +yaml+.  By default, only the following
  # classes are allowed to be deserialized:
  #
  # * TrueClass
  # * FalseClass
  # * NilClass
  # * Numeric
  # * String
  # * Array
  # * Hash
  #
  # Recursive data structures are not allowed by default.  Arbitrary classes
  # can be allowed by adding those classes to the +permitted_classes+ keyword argument.  They are
  # additive.  For example, to allow Date deserialization:
  #
  #   Psych.safe_load(yaml, permitted_classes: [Date])
  #
  # Now the Date class can be loaded in addition to the classes listed above.
  #
  # Aliases can be explicitly allowed by changing the +aliases+ keyword argument.
  # For example:
  #
  #   x = []
  #   x << x
  #   yaml = Psych.dump x
  #   Psych.safe_load yaml               # => raises an exception
  #   Psych.safe_load yaml, aliases: true # => loads the aliases
  #
  # A Psych::DisallowedClass exception will be raised if the yaml contains a
  # class that isn't in the +permitted_classes+ list.
  #
  # A Psych::BadAlias exception will be raised if the yaml contains aliases
  # but the +aliases+ keyword argument is set to false.
  #
  # +filename+ will be used in the exception message if any exception is raised
  # while parsing.
  #
  # When the optional +symbolize_names+ keyword argument is set to a
  # true value, returns symbols for keys in Hash objects (default: strings).
  #
  #   Psych.safe_load("---\n foo: bar")                         # => {"foo"=>"bar"}
  #   Psych.safe_load("---\n foo: bar", symbolize_names: true)  # => {:foo=>"bar"}
  #
  def self.safe_load yaml, legacy_permitted_classes = NOT_GIVEN, legacy_permitted_symbols = NOT_GIVEN, legacy_aliases = NOT_GIVEN, legacy_filename = NOT_GIVEN, permitted_classes: [], permitted_symbols: [], aliases: false, filename: nil, fallback: nil, symbolize_names: false, freeze: false
    if legacy_permitted_classes != NOT_GIVEN
      warn_with_uplevel 'Passing permitted_classes with the 2nd argument of Psych.safe_load is deprecated. Use keyword argument like Psych.safe_load(yaml, permitted_classes: ...) instead.', uplevel: 1 if $VERBOSE
      permitted_classes = legacy_permitted_classes
    end

    if legacy_permitted_symbols != NOT_GIVEN
      warn_with_uplevel 'Passing permitted_symbols with the 3rd argument of Psych.safe_load is deprecated. Use keyword argument like Psych.safe_load(yaml, permitted_symbols: ...) instead.', uplevel: 1 if $VERBOSE
      permitted_symbols = legacy_permitted_symbols
    end

    if legacy_aliases != NOT_GIVEN
      warn_with_uplevel 'Passing aliases with the 4th argument of Psych.safe_load is deprecated. Use keyword argument like Psych.safe_load(yaml, aliases: ...) instead.', uplevel: 1 if $VERBOSE
      aliases = legacy_aliases
    end

    if legacy_filename != NOT_GIVEN
      warn_with_uplevel 'Passing filename with the 5th argument of Psych.safe_load is deprecated. Use keyword argument like Psych.safe_load(yaml, filename: ...) instead.', uplevel: 1 if $VERBOSE
      filename = legacy_filename
    end

    result = parse(yaml, filename: filename)
    return fallback unless result

    class_loader = ClassLoader::Restricted.new(permitted_classes.map(&:to_s),
                                               permitted_symbols.map(&:to_s))
    scanner      = ScalarScanner.new class_loader
    visitor = if aliases
                Visitors::ToRuby.new scanner, class_loader, symbolize_names: symbolize_names, freeze: freeze
              else
                Visitors::NoAliasRuby.new scanner, class_loader, symbolize_names: symbolize_names, freeze: freeze
              end
    result = visitor.accept result
    result
  end

  ###
  # Parse a YAML string in +yaml+.  Returns the Psych::Nodes::Document.
  # +filename+ is used in the exception message if a Psych::SyntaxError is
  # raised.
  #
  # Raises a Psych::SyntaxError when a YAML syntax error is detected.
  #
  # Example:
  #
  #   Psych.parse("---\n - a\n - b") # => #<Psych::Nodes::Document:0x00>
  #
  #   begin
  #     Psych.parse("--- `", filename: "file.txt")
  #   rescue Psych::SyntaxError => ex
  #     ex.file    # => 'file.txt'
  #     ex.message # => "(file.txt): found character that cannot start any token"
  #   end
  #
  # See Psych::Nodes for more information about YAML AST.
  def self.parse yaml, legacy_filename = NOT_GIVEN, filename: nil, fallback: NOT_GIVEN
    if legacy_filename != NOT_GIVEN
      warn_with_uplevel 'Passing filename with the 2nd argument of Psych.parse is deprecated. Use keyword argument like Psych.parse(yaml, filename: ...) instead.', uplevel: 1 if $VERBOSE
      filename = legacy_filename
    end

    parse_stream(yaml, filename: filename) do |node|
      return node
    end

    if fallback != NOT_GIVEN
      warn_with_uplevel 'Passing the `fallback` keyword argument of Psych.parse is deprecated.', uplevel: 1 if $VERBOSE
      fallback
    else
      false
    end
  end

  ###
  # Parse a file at +filename+. Returns the Psych::Nodes::Document.
  #
  # Raises a Psych::SyntaxError when a YAML syntax error is detected.
  def self.parse_file filename, fallback: false
    result = File.open filename, 'r:bom|utf-8' do |f|
      parse f, filename: filename
    end
    result || fallback
  end

  ###
  # Returns a default parser
  def self.parser
    Psych::Parser.new(TreeBuilder.new)
  end

  ###
  # Parse a YAML string in +yaml+.  Returns the Psych::Nodes::Stream.
  # This method can handle multiple YAML documents contained in +yaml+.
  # +filename+ is used in the exception message if a Psych::SyntaxError is
  # raised.
  #
  # If a block is given, a Psych::Nodes::Document node will be yielded to the
  # block as it's being parsed.
  #
  # Raises a Psych::SyntaxError when a YAML syntax error is detected.
  #
  # Example:
  #
  #   Psych.parse_stream("---\n - a\n - b") # => #<Psych::Nodes::Stream:0x00>
  #
  #   Psych.parse_stream("--- a\n--- b") do |node|
  #     node # => #<Psych::Nodes::Document:0x00>
  #   end
  #
  #   begin
  #     Psych.parse_stream("--- `", filename: "file.txt")
  #   rescue Psych::SyntaxError => ex
  #     ex.file    # => 'file.txt'
  #     ex.message # => "(file.txt): found character that cannot start any token"
  #   end
  #
  # Raises a TypeError when NilClass is passed.
  #
  # See Psych::Nodes for more information about YAML AST.
  def self.parse_stream yaml, legacy_filename = NOT_GIVEN, filename: nil, &block
    if legacy_filename != NOT_GIVEN
      warn_with_uplevel 'Passing filename with the 2nd argument of Psych.parse_stream is deprecated. Use keyword argument like Psych.parse_stream(yaml, filename: ...) instead.', uplevel: 1 if $VERBOSE
      filename = legacy_filename
    end

    if block_given?
      parser = Psych::Parser.new(Handlers::DocumentStream.new(&block))
      parser.parse yaml, filename
    else
      parser = self.parser
      parser.parse yaml, filename
      parser.handler.root
    end
  end

  ###
  # call-seq:
  #   Psych.dump(o)               -> string of yaml
  #   Psych.dump(o, options)      -> string of yaml
  #   Psych.dump(o, io)           -> io object passed in
  #   Psych.dump(o, io, options)  -> io object passed in
  #
  # Dump Ruby object +o+ to a YAML string.  Optional +options+ may be passed in
  # to control the output format.  If an IO object is passed in, the YAML will
  # be dumped to that IO object.
  #
  # Currently supported options are:
  #
  # [<tt>:indentation</tt>]   Number of space characters used to indent.
  #                           Acceptable value should be in <tt>0..9</tt> range,
  #                           otherwise option is ignored.
  #
  #                           Default: <tt>2</tt>.
  # [<tt>:line_width</tt>]    Max character to wrap line at.
  #
  #                           Default: <tt>0</tt> (meaning "wrap at 81").
  # [<tt>:canonical</tt>]     Write "canonical" YAML form (very verbose, yet
  #                           strictly formal).
  #
  #                           Default: <tt>false</tt>.
  # [<tt>:header</tt>]        Write <tt>%YAML [version]</tt> at the beginning of document.
  #
  #                           Default: <tt>false</tt>.
  #
  # Example:
  #
  #   # Dump an array, get back a YAML string
  #   Psych.dump(['a', 'b'])  # => "---\n- a\n- b\n"
  #
  #   # Dump an array to an IO object
  #   Psych.dump(['a', 'b'], StringIO.new)  # => #<StringIO:0x000001009d0890>
  #
  #   # Dump an array with indentation set
  #   Psych.dump(['a', ['b']], indentation: 3) # => "---\n- a\n-  - b\n"
  #
  #   # Dump an array to an IO with indentation set
  #   Psych.dump(['a', ['b']], StringIO.new, indentation: 3)
  def self.dump o, io = nil, options = {}
    if Hash === io
      options = io
      io      = nil
    end

    visitor = Psych::Visitors::YAMLTree.create options
    visitor << o
    visitor.tree.yaml io, options
  end

  ###
  # Dump a list of objects as separate documents to a document stream.
  #
  # Example:
  #
  #   Psych.dump_stream("foo\n  ", {}) # => "--- ! \"foo\\n  \"\n--- {}\n"
  def self.dump_stream *objects
    visitor = Psych::Visitors::YAMLTree.create({})
    objects.each do |o|
      visitor << o
    end
    visitor.tree.yaml
  end

  ###
  # Dump Ruby +object+ to a JSON string.
  def self.to_json object
    visitor = Psych::Visitors::JSONTree.create
    visitor << object
    visitor.tree.yaml
  end

  ###
  # Load multiple documents given in +yaml+.  Returns the parsed documents
  # as a list.  If a block is given, each document will be converted to Ruby
  # and passed to the block during parsing
  #
  # Example:
  #
  #   Psych.load_stream("--- foo\n...\n--- bar\n...") # => ['foo', 'bar']
  #
  #   list = []
  #   Psych.load_stream("--- foo\n...\n--- bar\n...") do |ruby|
  #     list << ruby
  #   end
  #   list # => ['foo', 'bar']
  #
  def self.load_stream yaml, legacy_filename = NOT_GIVEN, filename: nil, fallback: [], **kwargs
    if legacy_filename != NOT_GIVEN
      warn_with_uplevel 'Passing filename with the 2nd argument of Psych.load_stream is deprecated. Use keyword argument like Psych.load_stream(yaml, filename: ...) instead.', uplevel: 1 if $VERBOSE
      filename = legacy_filename
    end

    result = if block_given?
               parse_stream(yaml, filename: filename) do |node|
                 yield node.to_ruby(**kwargs)
               end
             else
               parse_stream(yaml, filename: filename).children.map { |node| node.to_ruby(**kwargs) }
             end

    return fallback if result.is_a?(Array) && result.empty?
    result
  end

  ###
  # Load the document contained in +filename+.  Returns the yaml contained in
  # +filename+ as a Ruby object, or if the file is empty, it returns
  # the specified +fallback+ return value, which defaults to +false+.
  def self.load_file filename, **kwargs
    File.open(filename, 'r:bom|utf-8') { |f|
      self.load f, filename: filename, **kwargs
    }
  end

  # :stopdoc:
  @domain_types = {}
  def self.add_domain_type domain, type_tag, &block
    key = ['tag', domain, type_tag].join ':'
    @domain_types[key] = [key, block]
    @domain_types["tag:#{type_tag}"] = [key, block]
  end

  def self.add_builtin_type type_tag, &block
    domain = 'yaml.org,2002'
    key = ['tag', domain, type_tag].join ':'
    @domain_types[key] = [key, block]
  end

  def self.remove_type type_tag
    @domain_types.delete type_tag
  end

  @load_tags = {}
  @dump_tags = {}
  def self.add_tag tag, klass
    @load_tags[tag] = klass.name
    @dump_tags[klass] = tag
  end

  # Workaround for emulating `warn '...', uplevel: 1` in Ruby 2.4 or lower.
  def self.warn_with_uplevel(message, uplevel: 1)
    at = parse_caller(caller[uplevel]).join(':')
    warn "#{at}: #{message}"
  end

  def self.parse_caller(at)
    if /^(.+?):(\d+)(?::in `.*')?/ =~ at
      file = $1
      line = $2.to_i
      [file, line]
    end
  end
  private_class_method :warn_with_uplevel, :parse_caller

  class << self
    attr_accessor :load_tags
    attr_accessor :dump_tags
    attr_accessor :domain_types
  end
  # :startdoc:
end
