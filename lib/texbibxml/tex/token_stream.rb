require "texbibxml/bracket_matching"
require "texbibxml/input_stream/character"
require "texbibxml/input_stream/token"
require "texbibxml/tex/opaque_parser"

module Texbibxml
  module Tex
    # Token stream of TeX.
    class TokenStream
      include Texbibxml::InputStream::Token

      # @param input [String]
      #   Input to tokenize.
      #
      # @param opaque_commands [Hash]
      #   Hash of opaque commands without the leading backslash, where the key
      #   is the left opaque command and the value is the right opaque command.
      #   See {OpaqueParser} for the definition of an opaque command.
      def initialize(input, opaque_commands = {})
        @input = InputStream::Character.new(input)
        @opaque_commands = opaque_commands
        @unshifted_tokens = []
        @left_opaque_command = nil
      end

      private

      # Whether the given character is a punctuation.
      #
      # Recognized punctuations are `"`, `,`, `_`, and `^`.
      #
      # @param character [String]
      #   Character to validate.
      #
      # @return [Boolean]
      #   `true` if `character` is a punctuation, otherwise `false`.
      def punctuation?(character)
        %w[" , _ ^].include?(character)
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

      # Read the opaque string, and advance the stream past it.
      #
      # @param right_opaque_command [String]
      #   Right opaque command without the leading backslash.
      #
      # @return [Hash]
      #   Token as a hash with `:type` and `:value` keys. `:type` has the
      #   string value `opaque_string`, and `:value` is the opaque string.
      def read_opaque_string!(right_opaque_command)
        value = self.input.get_while! { |character| character != "\\" }
        if self.input.eof?
          self.croak(
            "Unexpected end of stream when searching "\
            "for the right opaque command: #{right_opaque_command}."
          )
        end
        if self.command?
          command = self.read_command![:value]
          if command[1..-1] == right_opaque_command
            self.input.unget!(command)
          else
            value +=
              command + self.read_opaque_string!(right_opaque_command)[:value]
          end
        elsif self.input.peek == "\\"
          value += self.input.get!
          value += self.read_opaque_string!(right_opaque_command)[:value]
        end
        { type: "opaque_string", value: value }
      end

      # Read the word, and advance the stream past it.
      #
      # @return [Hash]
      #   Token as a hash with `:type` and `:value` keys. `:type` has the
      #   string value `word`, and `:value` is the word.
      def read_word!
        self.croak("Start of a command.") if self.command?
        value = self.input.get_while! do |character|
          !BracketMatching.bracket?(character) &&
            !self.punctuation?(character) &&
            !character.match?(/^(\s|\\)$/)
        end
        if self.input.peek == "\\" && !self.command?
          self.input.get!
          value += "\\" + self.input.get!
          value += self.read_word![:value]
        end
        { type: "word", value: value }
      end

      # Overrides {Texbibxml::InputStream::Token#read_next!}.
      def read_next!
        return {} if self.input.eof?
        if BracketMatching.bracket?(self.input.peek)
          self.read_bracket!
        elsif self.punctuation?(self.input.peek)
          self.read_punctuation!
        elsif @left_opaque_command
          right_opaque_command = @opaque_commands[@left_opaque_command]
          @left_opaque_command = nil
          self.read_opaque_string!(right_opaque_command)
        elsif self.command?
          token = self.read_command!
          command = token[:value]
          if @opaque_commands.key?(command[1..-1])
            @left_opaque_command = command[1..-1]
          end
          token
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
