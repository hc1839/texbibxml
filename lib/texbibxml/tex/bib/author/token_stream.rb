require "texbibxml/bracket_matching"
require "texbibxml/input_stream/character"
require "texbibxml/input_stream/token"

module Texbibxml
  module Tex
    module Bib
      module Author
        # Token stream of TeX bibliography `author` field.
        class TokenStream
          include Texbibxml::InputStream::Token

          # @param input [String]
          #   Input to tokenize.
          def initialize(input)
            @input = InputStream::Character.new(input)
            @unshifted_tokens = []
          end

          private

          # Whether the given character is a punctuation.
          #
          # Recognized punctuation is `,`.
          #
          # @param character [String]
          #   Character to validate.
          #
          # @return [Boolean]
          #   `true` if `character` is a punctuation, otherwise `false`.
          def punctuation?(character)
            %w[,].include?(character)
          end

          # Read the punctuation, and advance the stream past it.
          #
          # @return [Hash]
          #   Token as a hash with `:type` and `:value` keys. `:type` has the
          #   string value `punctuation`, and `:value` is the punctuation.
          def read_punctuation!
            unless self.punctuation?(self.input.peek)
              self.croak("Not a punctuation.")
            end
            { type: "punctuation", value: self.input.get! }
          end

          # Read the word, and advance the stream past it.
          #
          # @return [Hash]
          #   Token as a hash with `:type` and `:value` keys. `:type` has the
          #   string value `word`, and `:value` is the word.
          def read_word!
            value = self.input.get_while! do |character|
              !%w[{ }].include?(character) &&
                !self.punctuation?(character) &&
                !character.match?(/^(\s|\\)$/)
            end
            case self.input.peek
            when "{"
              value += self.input.get!
              value += self.read_bracketed_string!("}")[:value]
              value += self.input.get!(value: "}")
              value += self.read_word![:value] unless self.input.eof?
            when "}"
              self.croak("Unexpected right brace.")
            when "\\"
              value += self.input.get!
              value += self.read_word![:value] unless self.input.eof?
            end
            { type: "word", value: value }
          end

          # Overrides {Texbibxml::InputStream::Token#read_next!}.
          def read_next!
            return {} if self.input.eof?
            if BracketMatching.bracket?(self.input.peek)
              token = self.read_bracket!
              @is_braced_string = token[:value] == "{"
              token
            elsif self.punctuation?(self.input.peek)
              self.read_punctuation!
            elsif @is_braced_string
              @is_braced_string = false
              self.read_bracketed_string!("}")
            elsif self.input.peek.match?(/^\s$/)
              self.read_whitespace!
            else
              token = self.read_word!
              self.croak("Failed to tokenize.") if token[:value].empty?
              token
            end
          end
        end
      end
    end
  end
end
