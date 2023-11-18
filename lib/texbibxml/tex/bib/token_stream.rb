require "texbibxml/bracket_matching"
require "texbibxml/input_stream/character"
require "texbibxml/input_stream/token"

module Texbibxml
  module Tex
    module Bib
      # Token stream of TeX bibliography.
      class TokenStream
        include Texbibxml::InputStream::Token

        # @param input [String]
        #   Input to tokenize.
        def initialize(input)
          @input = InputStream::Character.new(input)
          @unshifted_tokens = []
          @is_field_value = false
          @field_value_delimiter = nil
        end

        private

        # Whether the given character is the beginning of an entry type.
        #
        # @param character [String]
        #   Character to validate.
        #
        # @return [Boolean]
        #   `true` if `character` is the beginning of an entry type, otherwise
        #   `false`.
        def entry_type?(character)
          character == "@"
        end

        # Read the entry type, and advance the stream past it.
        #
        # @return [Hash]
        #   Token as a hash with `:type` and `:value` keys. `:type` has the
        #   string value `entry_type`, and `:value` is a string with the
        #   leading `@` character.
        def read_entry_type!
          unless self.entry_type?(self.input.peek)
            self.croak("Not an entry type.")
          end
          value = self.input.get_while! do |character|
            !character.match?(/\{|\s/)
          end
          { type: "entry_type", value: value }
        end

        # Whether the given character is a punctuation.
        #
        # Recognized punctuations are `"` and `,`.
        #
        # @param character [String]
        #   Character to validate.
        #
        # @return [Boolean]
        #   `true` if `character` is a punctuation, otherwise `false`.
        def punctuation?(character)
          %w[" ,].include?(character)
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

        # Whether the given character is a valid start of an identifier.
        #
        # @param character [String]
        #   Character to validate.
        #
        # @return [Boolean]
        #   `true` if `character` is a valid start of an identifier, otherwise
        #   `false`.
        def id_start?(character)
          character.match?(/^[a-zA-Z]$/)
        end

        # Whether the given character can be part of a valid identifier.
        #
        # @param character [String]
        #   Character to validate.
        #
        # @return [Boolean]
        #   `true` if `character` can be part of a valid identifier, otherwise
        #   `false`.
        def id_character?(character)
          character.match?(/^(\w|-)$/)
        end

        # Read the identifier, and advance the stream past it.
        #
        # @return [Hash]
        #   Token as a hash with `:type` and `:value` keys. `:type` has the
        #   string value `identifier`, and `:value` is the identifier.
        def read_id!
          unless self.id_start?(self.input.peek)
            self.croak("Not an identifier.")
          end
          value = self.input.get_while! do |character|
            self.id_character?(character)
          end
          { type: "identifier", value: value }
        end

        # Whether the given character can be part of an operator.
        #
        # Only the assignment operator, `=`, is recognized.
        #
        # @param character [String]
        #   Character to validate.
        #
        # @return [Boolean]
        #   `true` if `character` can be part of an operator, otherwise
        #   `false`.
        def operator_character?(character)
          character == "="
        end

        # Read the operator, and advance the stream past it.
        #
        # @return [Hash]
        #   Token as a hash with `:type` and `:value` keys. `:type` has the
        #   string value `operator`, and `:value` is the operator.
        def read_operator!
          unless self.operator_character?(self.input.peek)
            self.croak("Not an operator.")
          end
          value = self.input.get_while! do |character|
            self.operator_character?(character)
          end
          { type: "operator", value: value }
        end

        # Overrides {Texbibxml::InputStream::Token#read_next!}.
        def read_next!
          self.skip_whitespace!
          return {} if self.input.eof?
          if self.entry_type?(self.input.peek)
            self.read_entry_type!
          elsif self.operator_character?(self.input.peek)
            token = self.read_operator!
            @is_field_value = token[:value] == "="
            token
          elsif @is_field_value && @field_value_delimiter
            @is_field_value = false
            case @field_value_delimiter
            when "\""
              self.read_delimited_string!(@field_value_delimiter)
            when "{"
              self.read_bracketed_string!(
                BracketMatching.right_bracket_of(@field_value_delimiter)
              )
            else
              self.croak(
                "Unrecognized delimiter of a field value: "\
                "#{@field_value_delimiter}"
              )
            end
          elsif BracketMatching.bracket?(self.input.peek)
            token = self.read_bracket!
            @field_value_delimiter = @is_field_value ? token[:value] : nil
            token
          elsif self.punctuation?(self.input.peek)
            token = self.read_punctuation!
            @field_value_delimiter = @is_field_value ? token[:value] : nil
            token
          elsif self.id_start?(self.input.peek)
            self.read_id!
          else
            self.croak("Cannot handle character: #{self.input.peek}")
          end
        end
      end
    end
  end
end
