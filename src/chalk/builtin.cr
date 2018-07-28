module Chalk
  class BuiltinFunction
      getter param_count : Int32

      def initialize(@param_count)
      end

      def generate!(into)
      end
  end

  class InlineFunction
      getter param_count : Int32
      
      def initialize(@param_count)
      end

      def generate!(codegen, params, table, target, free)
      end
  end
end
