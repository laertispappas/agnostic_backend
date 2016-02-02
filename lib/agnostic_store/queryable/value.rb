module AgnosticStore
  module Queryable
    class Value < TreeNode
      include AgnosticStore::Utilities

      attr_accessor :value
      attr_reader :parent

      def initialize(value, parent: parent, context: context)
        super([], context)
        @value, @parent = value, parent
      end

      def ==(o)
        super && o.value == value
      end

      def type
        associated_attribute = parent.attribute if parent.respond_to? :attribute
        value_for_key(parent.context.index.schema, associated_attribute.name).try(:type) if associated_attribute
      end
    end
  end
end