require "rexml"

require "texbibxml/bracket_matching"
require "texbibxml/tex/opaque_parser"
require "texbibxml/tex/token_stream"

module Texbibxml
  module Tex
    # Parser of TeX.
    class Parser
      # @param opaque_parsers [Enumerable]
      #   Enumerable of {OpaqueParser}.
      def initialize(opaque_parsers = [])
        @opaque_parsers =
          opaque_parsers.map { |it| [it.left_command, it] }.to_h
        @opaque_commands =
          opaque_parsers.map { |it| [it.left_command, it.right_command] }.to_h
        @token_stream = nil
        @bracket_matcher = BracketMatching::Matcher.new
      end

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
      def append_ast(input, parent_ast)
        self.reset!
        @token_stream = TokenStream.new(input, @opaque_commands)
        until @token_stream.eof?
          self.append_entity_ast!(parent_ast)
        end
        self.reset!
      end

      # Parse the given input.
      #
      # @param input [String]
      #   Input to parse.
      #
      # @return [REXML::Document]
      #   AST of `input`.
      def parse(input)
        retval = REXML::Document.new
        retval.add(REXML::XMLDecl.new("1.0", "UTF-8"))
        REXML::Element.new("tex", retval)
        self.append_ast(input, retval.root)
        retval
      end

      private

      # Reset the parser.
      #
      # @return [void]
      def reset!
        @bracket_matcher.reset!
        @token_stream = nil
      end

      # Append the AST of the TeX entity at the current position as a child
      # node of the given parent AST.
      #
      # @param parent_ast [REXML::Element]
      #   Parent AST to have the parsed AST appended as a child node.
      #
      # @return [void]
      def append_entity_ast!(parent_ast)
        @token_stream.croak("Unexpected end of stream.") if @token_stream.eof?
        case @token_stream.peek[:type]
        when "bracket"
          bracket = @token_stream.get![:value]
          @bracket_matcher.update!(bracket)
          parent_ast.add_text(bracket)
        when "command"
          self.append_command_ast!(parent_ast)
        else
          parent_ast.add_text(@token_stream.get![:value])
        end
      end

      # Append the AST of the command at the current position as a child node
      # of the given parent AST.
      #
      # @param parent_ast [REXML::Element]
      #   Parent AST to have the parsed AST appended as a child node.
      #
      # @return [void]
      def append_command_ast!(parent_ast)
        command_name = @token_stream.get!(type: "command")[:value][1..-1]
        command_ast = REXML::Element.new("command", parent_ast)
        if @opaque_parsers.key?(command_name)
          left_command_name = command_name
          right_command_name = @opaque_commands[left_command_name]
          command_ast.add_attribute("left-name", left_command_name)
          command_ast.add_attribute("right-name", right_command_name)
          @opaque_parsers[left_command_name].append_ast(
            @token_stream.get!(type: "opaque_string")[:value],
            command_ast
          )
          next_command_name =
            @token_stream.get!(type: "command")[:value][1..-1]
          unless next_command_name == right_command_name
            @token_stream.croak(
              "Unexpected right command: #{next_command_name}"
            )
          end
        elsif @token_stream.match?(type: "bracket", value: "{")
          command_ast.add_attribute("name", command_name)
          @bracket_matcher.update!(@token_stream.get![:value])
          command_argument_level = @bracket_matcher.level
          until @token_stream.match?(type: "bracket", value: "}") &&
                  @bracket_matcher.level == command_argument_level
            if @token_stream.eof?
              @token_stream.croak("Unexpected end of stream.")
            end
            self.append_entity_ast!(command_ast)
          end
          @bracket_matcher.update!(@token_stream.get![:value])
        else
          command_ast.add_attribute("name", command_name)
        end
      end
    end
  end
end
