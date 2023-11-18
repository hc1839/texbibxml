require "texbibxml/bracket_matching"
require "texbibxml/input_stream/character"

module Texbibxml
  module InputStream
    # Token stream.
    module Token
      # Whether the stream is at the end.
      #
      # @return [Boolean]
      #   `true` if the stream is at the end, otherwise `false`.
      def eof?
        self.peek.empty?
      end

      # Get the next token with advancing the stream.
      #
      # @param type [String]
      #   Type of token to match and call {#croak} if it does not match. `nil`
      #   (default) if matching is not needed.
      #
      # @return [Hash]
      #   Next token in the stream or empty hash if at the end of stream.
      def get!(type: nil)
        retval = self.unshifted_tokens.pop || self.read_next!
        if type && retval[:type] != type
          self.croak(
            "Type of token does not match: "\
            "should be '#{type}' but got '#{retval[:type]}'."
          )
        end
        retval
      end

      # Skip the next token if it matches the given type and value, otherwise
      # call {#croak}.
      #
      # @param type [String]
      #   Type of token to match.
      #
      # @param value [String]
      #   Value of token to match.
      #
      # @return [void]
      def skip!(type:, value:)
        token = self.get!
        unless token[:type] == type
          self.croak(
            "Type of token does not match: "\
            "should be '#{type}' but got '#{token[:type]}'."
          )
        end
        unless token[:value] == value
          self.croak(
            "Value of token does not match: "\
            "should be '#{value}' but got '#{token[:value]}'."
          )
        end
      end

      # Push back the given token onto the stream's buffer.
      #
      # @param token [Hash]
      #   Token to push back.
      #
      # @return [void]
      def unget!(token)
        self.unshifted_tokens << token
      end

      # Get the next token without advancing the stream.
      #
      # @return [Hash]
      #   Next token in the stream or empty hash if at the end of stream.
      def peek
        self.unshifted_tokens << read_next! if self.unshifted_tokens.empty?
        self.unshifted_tokens.last or {}
      end

      # Whether the next token matches the given type and optionally the value.
      #
      # If the stream is at the end, {#croak} is called.
      #
      # @param type [String]
      #   Type of token to match.
      #
      # @param value [String]
      #   Value of token to match or `nil` (default) if matching is not needed.
      #
      # @return [Boolean]
      #   `true` if the next token matches, otherwise `false`.
      def match?(type:, value: nil)
        return false if self.eof?
        token = self.peek
        if token[:type] != type
          false
        elsif value && token[:value] != value
          false
        else
          true
        end
      end

      # Raise `RuntimeError` with the given message and the current position in
      # the character stream.
      #
      # @param message [String]
      #   Exception message.
      #
      # @return [void]
      def croak(message)
        self.input.croak(message)
      end

      protected

      # @return [Character]
      #   Character stream.
      attr_reader :input

      # @return [Array]
      #   Array of tokens that have been pushed back or empty array if there
      #   are none.
      attr_accessor :unshifted_tokens

      # Skip the next consecutive whitespaces.
      #
      # Nothing is done if the next character is not a whitespace.
      #
      # @return [void]
      def skip_whitespace!
        self.input.get_while! { |character| character.match?(/^\s$/) }
      end

      # Read the consecutive whitespaces, and advance the stream past it.
      #
      # @return [Hash]
      #   Token as a hash with `:type` and `:value` keys. `:type` has the
      #   string value `whitespace`, and `:value` is the consecutive
      #   whitespaces.
      def read_whitespace!
        self.croak("Not a whitespace.") unless self.input.peek.match?(/^\s$/)
        value = self.input.get_while! { |character| character.match?(/^\s$/) }
        { type: "whitespace", value: value }
      end

      # Read the bracket character, and advance the stream past it.
      #
      # @return [Hash]
      #   Token as a hash with `:type` and `:value` keys. `:type` has the
      #   string value `bracket`, and `:value` is the bracket character.
      def read_bracket!
        unless BracketMatching.bracket?(self.input.peek)
          self.croak("Not a bracket character.")
        end
        { type: "bracket", value: self.input.get! }
      end

      # Read the delimited string, and advance the stream past it.
      #
      # String to read begins on the character after the corresponding left
      # delimiter. Any character preceded by a backslash is ignored when
      # searching for the right delimiter.
      #
      # @param right_delimiter [String]
      #   Right delimiter.
      #
      # @return [Hash]
      #   Token as a hash with `:type` and `:value` keys. `:type` has the
      #   string value `string`, and `:value` is the string without the right
      #   delimiter.
      def read_delimited_string!(right_delimiter)
        is_backslashed = false
        value =
          self.input.get_while! do |character|
            if is_backslashed
              is_backslashed = false
              next true
            end
            case character
            when "\\"
              is_backslashed = true
              true
            when right_delimiter
              false
            else
              true
            end
          end
        unless self.input.peek == right_delimiter
          self.croak("Cannot find right delimiter: #{right_delimiter}")
        end
        { type: "string", value: value }
      end

      # Read the bracketed string, and advance the stream past it.
      #
      # String to read begins on the character after the given left bracket.
      # Any character preceded by a backslash is ignored when searching for the
      # right bracket.
      #
      # @param right_bracket [String]
      #   Right bracket.
      #
      # @return [Hash]
      #   Token as a hash with `:type` and `:value` keys. `:type` has the
      #   string value `string`, and `:value` is the string without the right
      #   bracket.
      def read_bracketed_string!(right_bracket)
        unless BracketMatching.right_bracket?(right_bracket)
          self.croak("Not a right bracket: #{right_bracket}")
        end
        left_bracket = BracketMatching.left_bracket_of(right_bracket)
        bracket_matcher = BracketMatching::Matcher.new
        bracket_matcher.update!(left_bracket)
        is_backslashed = false
        value =
          self.input.get_while! do |character|
            if is_backslashed
              is_backslashed = false
              next true
            end
            case character
            when "\\"
              is_backslashed = true
              true
            when left_bracket, right_bracket
              begin
                bracket_matcher.update!(character)
              rescue => e
                self.croak(e.message)
              end
              bracket_matcher.level != 0
            else
              true
            end
          end
        { type: "string", value: value }
      end

      # Whether the next character is the start of a command.
      #
      # Command starts with a backslash except `\{` and `\}`.
      #
      # @return [Boolean]
      #   `true` if the next character is the start of a command, otherwise
      #   `false`.
      def command?
        self.input.peek == "\\" && !%w[{ }].include?(self.input.peek_escaped)
      end

      # Read the command, and advance the stream past it.
      #
      # @return [Hash]
      #   Token as a hash with `:type` and `:value` keys. `:type` has the
      #   string value `command`, and `:value` is the command with the leading
      #   backslash.
      def read_command!
        self.croak("Not the start of a command.") unless self.command?
        value = self.input.get!
        value += self.input.get_while! do |character|
          !BracketMatching.bracket?(character) &&
            !character.match?(/^(\s|\\)$/)
        end
        value +=
          if %w[{ }].include?(self.input.peek)
            ""
          elsif BracketMatching.bracket?(self.input.peek)
            self.input.get!
          elsif self.input.peek == "\\" && !self.command?
            self.input.get!
            "\\" + self.input.get!
          else
            ""
          end
        { type: "command", value: value }
      end

      # Read the next token, and advance the stream past it.
      #
      # @return [Hash]
      #   Next token in the stream or empty hash if at the end of stream.
      #
      # @abstract
      def read_next!
        raise RuntimeError.new(
          "InputStream::Token#read_next! is not implemented."
        )
      end
    end
  end
end
