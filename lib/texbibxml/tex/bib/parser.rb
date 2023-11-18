require "rexml"

require "texbibxml/tex/token_stream"

module Texbibxml
  module Tex
    module Bib
      # Parser of TeX bibliography.
      class Parser
        # @param field_parsers [**]
        #   Key is the name of the field as a string. Value is the function
        #   that is given the field name (`String`), the field value
        #   (`String`), and the `entry` element (`REXML::Element`) to append
        #   the AST of the field value as a child node.
        #
        # @param default_field_parser [&]
        #   Function with the same signature as the functions in
        #   `field_parsers` for the field names not given in `field_parsers`.
        #   If omitted, a generic AST of the field value is appended.
        def initialize(**field_parsers, &default_field_parser)
          @field_parsers = field_parsers
          @field_parsers.default =
            if block_given?
              lambda default_field_parser
            else
              lambda do |field_name, field_value, entry_ast|
                field =
                  REXML::Element.new(field_name.gsub(/(_|\W)+/, "-"), entry_ast)
                field.add_text(field_value.strip)
              end
            end
          @token_stream = nil
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
          @token_stream = TokenStream.new(input)
          until @token_stream.eof?
            self.append_entry_ast!(parent_ast)
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
          REXML::Element.new("texbib", retval)
          self.append_ast(input, retval.root)
          retval
        end

        private

        # Reset the parser.
        #
        # @return [void]
        def reset!
          @token_stream = nil
        end

        # Append the AST of the entry at the current position as a child node
        # of the given parent AST.
        #
        # @param parent_ast [REXML::Element]
        #   Parent AST to have the parsed AST appended as a child node.
        #
        # @return [void]
        def append_entry_ast!(parent_ast)
          entry_ast = REXML::Element.new("entry", parent_ast)
          entry_ast.add_attribute(
            "type",
            @token_stream.get!(type: "entry_type")[:value][1..-1]
          )
          @token_stream.skip!(type: "bracket", value: "{")
          entry_ast.add_attribute(
            "xml:id",
            @token_stream.get!(type: "identifier")[:value]
          )
          @token_stream.skip!(type: "punctuation", value: ",")
          until @token_stream.match?(type: "bracket", value: "}")
            if @token_stream.eof?
              @token_stream.croak("Unexpected end of stream.")
            end
            self.append_field_ast!(entry_ast)
          end
          @token_stream.get!
        end

        # Append the AST of the field at the current position as a child node
        # of the given parent AST.
        #
        # @param parent_ast [REXML::Element]
        #   Parent AST to have the parsed AST appended as a child node.
        #
        # @return [void]
        def append_field_ast!(parent_ast)
          field_name = @token_stream.get!(type: "identifier")[:value]
          @token_stream.skip!(type: "operator", value: "=")
          delimiter_token = @token_stream.get!
          case delimiter_token[:type]
          when "bracket"
            unless delimiter_token[:value] == "{"
              @token_stream.croak(
                "Unexpected bracket: #{delimiter_token[:value]}"
              )
            end
          when "punctuation"
            unless delimiter_token[:value] == "\""
              @token_stream.croak(
                "Unexpected punctuation: #{delimiter_token[:value]}"
              )
            end
          else
            @token_stream.croak("Unexpected token: #{delimiter_token[:value]}")
          end
          field_value = @token_stream.get!(type: "string")[:value]
          @field_parsers[field_name].(field_name, field_value, parent_ast)
          @token_stream.get!
          if @token_stream.match?(type: "punctuation", value: ",")
            @token_stream.get!
          end
        end
      end
    end
  end
end
