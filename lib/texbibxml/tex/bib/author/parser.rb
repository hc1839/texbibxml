require "rexml"

require "texbibxml/tex/bib/author/token_stream"
require "texbibxml/tex/opaque_parser"
require "texbibxml/tex/parser"

module Texbibxml
  module Tex
    module Bib
      module Author
        # Parser of TeX bibliography `author` field.
        class Parser
          # @param opaque_parsers [Enumerable]
          #   Enumerable of {OpaqueParser}.
          def initialize(opaque_parsers = [])
            @opaque_parsers =
              opaque_parsers.map { |it| [it.left_command, it] }.to_h
            @token_stream = nil
            @tex_parser = Tex::Parser.new(opaque_parsers)
          end

          # Parse the given input and append its AST as a child node of the
          # given parent AST.
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
            author_ast = REXML::Element.new("author", parent_ast)
            @token_stream = TokenStream.new(input)
            until @token_stream.eof?
              self.append_member_ast!(author_ast)
            end
            self.reset!
          end

          private

          # Reset the parser.
          #
          # @return [void]
          def reset!
            @token_stream = nil
          end

          # Append the AST of the author member at the current position as a
          # child node of the given parent AST.
          #
          # @param parent_ast [REXML::Element]
          #   Parent AST to have the parsed AST appended as a child node.
          #
          # @return [void]
          def append_member_ast!(parent_ast)
            member_ast = REXML::Element.new("member", parent_ast)
            member_tokens = []
            until @token_stream.eof? ||
                    @token_stream.match?(type: "word", value: "and")
              member_tokens << @token_stream.get!
            end
            @token_stream.get! unless @token_stream.eof?
            is_surname_front = member_tokens.any? do |it|
              it == { type: "punctuation",  value: "," }
            end
            surname = ""
            first_name = ""
            if is_surname_front
              member_tokens.each do |token|
                case token[:type]
                when "punctuation"
                  break if token[:value] == ","
                when "whitespace"
                  surname += " "
                else
                  surname += token[:value]
                end
              end
              member_tokens.reverse_each do |token|
                case token[:type]
                when "punctuation"
                  break if token[:value] == ","
                when "whitespace"
                  first_name = " " + first_name
                else
                  first_name = token[:value] + first_name
                end
              end
            else
              if member_tokens.last == { type: "bracket", value: "}" }
                member_tokens.pop
                surname = member_tokens.pop[:value]
                member_tokens.pop
              else
                surname = member_tokens.pop[:value]
              end
              member_tokens = member_tokens.find_all do |it|
                %w[word string].include?(it[:type])
              end
              first_name =
                member_tokens.map { |it| it[:value].strip }.join(" ")
            end
            surname.strip!
            first_name.strip!
            surname_ast = REXML::Element.new("surname", member_ast)
            @tex_parser.append_ast(surname, surname_ast)
            first_name_ast = REXML::Element.new("first-name", member_ast)
            @tex_parser.append_ast(first_name, first_name_ast)
          end
        end
      end
    end
  end
end
