# frozen_string_literal: false

require 'psych/visitors/to_ruby'


module Psych
  module Visitors

    ##
    ## Visitor class to generate custom object instead of Hash.
    ##
    ## Example1:
    ##
    ##     ## define custom classes
    ##     Team   = Struct.new('Team',   'name', 'members')
    ##     Member = Struct.new('Member', 'name', 'gender')
    ##     ## create visitor object
    ##     require 'psych'
    ##     require 'psych/visitors/custom_class'
    ##     classmap = {
    ##       "teams"   => Team,
    ##       "members" => Member,
    ##     }
    ##     visitor = Psych::Visitors::CustomClassVisitor.create(classmap)
    ##     ## sample YAML document
    ##     input = <<-'END'
    ##     teams:
    ##       - name: SOS Brigade
    ##         members:
    ##           - {name: Haruhi, gender: F}
    ##           - {name: Kyon,   gender: M}
    ##           - {name: Mikuru, gender: F}
    ##           - {name: Itsuki, gender: M}
    ##           - {name: Yuki,   gender: F}
    ##     END
    ##     ## parse YAML document with custom classes
    ##     tree = Psych.parse(input)
    ##     ydoc = visitor.accept(tree)
    ##     p ydoc['teams'][0].class                #=> Struct::Team
    ##     p ydoc['teams'][0]['members'][0].class  #=> Struct::Member
    ##     team = ydoc['teams'][0]
    ##     p team.name                #=> "SOS Brigade"
    ##     p team.members[0].name     #=> "Haruhi"
    ##     p team.members[0].gender   #=> "F"
    ##
    class CustomClassVisitor < ToRuby

      def self.create(classmap={})
        visitor = super()
        visitor.instance_variable_set('@classmap', classmap)
        visitor
      end

      attr_reader :classmap   # key: string, value: class object

      def initialize(*args)
        super
        @key_path = []     # ex: [] -> ['tables'] -> ['tables', 'columns']
      end

      private

      def accept_key(k)    # push keys
        key = super k
        @key_path << key
        key
      end

      def accept_value(v)  # pop keys
        value = super v
        @key_path.pop()
        value
      end

      def empty_mapping(o)  # generate custom object (or Hash object)
        klass = @classmap[@key_path.last]
        klass ? klass.new : super
      end

      def merge_mapping(hash, val)   # for '<<' (merge)
        val.each {|k, v| hash[k] = v }
      end

    end

  end
end
