# coding: US-ASCII
# frozen_string_literal: false
require 'psych/helper'
require 'psych/visitors/custom_class'

module Psych
  module Visitors
    class TestCustomClass < TestCase

      INPUT_STRING = <<-'END'
        teams:
          - name: SOS Brigade
            members:
              - {name: Haruhi, gender: F}
              - {name: Kyon,   gender: M}
              - {name: Mikuru, gender: F}
              - {name: Itsuki, gender: M}
              - {name: Yuki,   gender: F}
      END

      def test_custom_classes
        classmap = {
          "teams"   => Struct.new('Team', 'name', 'members'),
          "members" => Struct.new('Member', 'name', 'gender'),
        }
        #
        visitor = Psych::Visitors::CustomClassVisitor.create(classmap)
        tree = Psych.parse(INPUT_STRING)
        ydoc = visitor.accept(tree)
        #
        assert_kind_of Hash,       ydoc
        assert_kind_of classmap["teams"],   ydoc['teams'][0]
        assert_kind_of classmap["members"], ydoc['teams'][0]['members'][0]
        #
        team = ydoc['teams'][0]
        assert_equal 'SOS Brigade', team.name
        assert_equal 'Haruhi',      team.members[0].name
        assert_equal 'F',           team.members[0].gender
      end

      def test_default_class
        magic_hash_cls = Class.new(Hash) do
          def method_missing(method, *args)
            return super unless args.empty?
            return self[method.to_s]
          end
        end
        classmap = {'*' => magic_hash_cls}
        #
        visitor = Psych::Visitors::CustomClassVisitor.create(classmap)
        tree = Psych.parse(INPUT_STRING)
        ydoc = visitor.accept(tree)
        #
        assert_kind_of magic_hash_cls, ydoc
        assert_kind_of magic_hash_cls, ydoc['teams'][0]
        assert_kind_of magic_hash_cls, ydoc['teams'][0]['members'][0]
        #
        team = ydoc['teams'][0]
        assert_equal "SOS Brigade", team.name
        assert_equal "Haruhi",      team.members[0].name
        assert_equal "F",           team.members[0].gender
      end

      def test_merge_mapping
        input = <<-END
        column-defaults:
          - &id
            name  : id
            type  : int
            pkey  : true
        tables:
          - name  : admin_users
            columns:
              - <<: *id
                name:  user_id
        END
        #
        classmap = {
          "tables"  => Struct.new('Table', 'name', 'columns'),
          "columns" => Struct.new('Column', 'name', 'type', 'pkey', 'required'),
        }
        #
        visitor = Psych::Visitors::CustomClassVisitor.create(classmap)
        tree = Psych.parse(input)
        ydoc = visitor.accept(tree)
        #
        assert_kind_of classmap["tables"],  ydoc['tables'][0]
        assert_kind_of classmap["columns"], ydoc['tables'][0]['columns'][0]
        #
        table = ydoc['tables'][0]
        assert_equal "int",     table.columns[0].type   # merged
        assert_equal true,      table.columns[0].pkey   # merged
        assert_equal "user_id", table.columns[0].name   # ovrerwritten
      end

    end
  end
end
