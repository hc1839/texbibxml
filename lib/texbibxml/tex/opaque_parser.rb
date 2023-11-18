require "rexml"

module Texbibxml
  module Tex
    # Interface of an opaque parser.
    #
    # An opaque parser parses a text as a single string (called opaque string)
    # that is surrounded by a pair of TeX commands defined to be left and right
    # opaque commands. Left opaque command indicates the start of an opaque
    # string, and right opaque command indicates the end of an opaque string.
    module OpaqueParser
      # @return [String]
      #   Left opaque command without the leading backslash.
      attr_reader :left_command

      # @return [String]
      #   Right opaque command without the leading backslash.
      attr_reader :right_command

      # Parse the given input and append its AST as a child node of the given
      # parent AST.
      #
      # @param input [String]
      #   Input to parse.
      #
      # @param parent_ast [REXML::Element]
      #   Parent AST to append the AST of `input` as a child node.
      #
      # @return [void]
      #
      # @abstract
      def append_ast(input, parent_ast)
        raise RuntimeError.new("Tex::OpaqueParser#parse is not implemented.")
      end
    end
  end
end
