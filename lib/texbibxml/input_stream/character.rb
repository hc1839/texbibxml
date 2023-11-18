module Texbibxml
  module InputStream
    # Character stream.
    class Character
      # @param input [String]
      #   Input string. Any `\n\r` is treated as `\n`.
      def initialize(input)
        @input = input.gsub("\n\r", "\n")
        @unshifted_characters = []
        @position = 0
        @line = 1
        @column = 0
      end

      # Whether the stream is at the end.
      #
      # @return [Boolean]
      #   `true` if the stream is at the end, otherwise `false`.
      def eof?
        @unshifted_characters.empty? && @position == @input.size
      end

      # Get the next character with advancing the stream.
      #
      # @param value [String]
      #   Character to match and call {#croak} if it does not match. `nil`
      #   (default) if matching is not needed.
      #
      # @return [String]
      #   Next character in the stream or empty string if at the end of stream.
      def get!(value: nil)
        retval =
          if self.eof?
            ""
          elsif @unshifted_characters.empty?
            character = @input[@position]
            @position += 1
            if character == "\n"
              @line += 1
              @column = 0
            else
              @column += 1
            end
            character
          else
            @unshifted_characters.pop
          end
        if value && retval != value
          self.croak(
            "Character does not match: "\
            "should be '#{value}' but got '#{retval}'."
          )
        end
        retval
      end

      # Get the next escaped character with advancing the stream only if the
      # next character in the stream is a backslash.
      #
      # @param value [String]
      #   Character following the backslash to match and call {#croak} if it
      #   does not match. `nil` (default) if matching is not needed.
      #
      # @return [String]
      #   Character following the backslash, empty string if the backslash is
      #   the last character in the stream, or `nil` if the next character is
      #   not a backslash (including when the stream is at the end).
      def get_escaped!(value: nil)
        case self.peek
        when "\\"
          self.get!
          self.get!(value: value)
        else
          nil
        end
      end

      # Read and advance the character stream until the given predicate returns
      # `false` or the end of stream is reached.
      #
      # @param predicate [&]
      #   Predicate that returns whether to continue reading the character
      #   stream given the next character.
      #
      # @return [String]
      #   String from the character stream starting from the current position
      #   up to (but not including) the first character that `predicate`
      #   returns `false`.
      def get_while!(&predicate)
        retval = ""
        while !self.peek.empty? && yield(self.peek)
          retval += self.get!
        end
        retval
      end

      # Push back the given string onto the stream's buffer
      # character-by-character.
      #
      # @param string [String]
      #   String to push back character-by-character from the end.
      #
      # @return [void]
      def unget!(string)
        if string.size == 1
          @unshifted_characters << string
        else
          string.reverse.each_char { |character| self.unget!(character) }
        end
      end

      # Push back the given escaped character onto the character stream's
      # buffer.
      #
      # @param character [String]
      #   Character without the leading backslash to push back. If empty
      #   string, nothing is done.
      #
      # @return [void]
      def unget_escaped!(character)
        return if character.empty?
        unless character.size == 1
          raise ArgumentError.new("Not a character: #{character}")
        end
        self.unget!(character)
        self.unget!("\\")
      end

      # Get the next character without advancing the stream.
      #
      # @return [String]
      #   Next character in the stream or empty string if at the end of stream.
      def peek
        if @unshifted_characters.empty?
          @input[@position] || ""
        else
          @unshifted_characters.last
        end
      end

      # Get the next escaped character without advancing the stream.
      #
      # @return [String]
      #   Character following the backslash, empty string if the backslash is
      #   the last character in the stream, or `nil` if the next character is
      #   not a backslash (including when the stream is at the end).
      def peek_escaped
        case self.peek
        when "\\"
          self.get!
          retval = self.peek
          self.unget!("\\")
          retval
        else
          nil
        end
      end

      # Raise `RuntimeError` with the given message and the current position in
      # the stream.
      #
      # @param message [String]
      #   Exception message.
      #
      # @return [void]
      def croak(message)
        raise RuntimeError.new("#{message} (#{@line}:#{@column})")
      end
    end
  end
end
