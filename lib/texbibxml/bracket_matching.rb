module Texbibxml
  # Bracket types and matching.
  module BracketMatching
    # Matcher of bracket nesting.
    class Matcher
      # return [Array]
      #   Array of left brackets from top level to the current level.
      attr_reader :left_brackets

      def initialize
        @left_brackets = []
      end

      # Current bracket nesting level.
      #
      # @return [Integer]
      #   Level of the current bracket nesting starting from zero, which is no
      #   nesting.
      def level
        self.left_brackets.size
      end

      # Go down (deeper) one level in the bracket nesting.
      #
      # @param left_bracket [String]
      #   Left bracket.
      #
      # @return [void]
      def down!(left_bracket)
        unless BracketMatching.left_bracket?(left_bracket)
          raise ArgumentError.new("Not a left bracket: #{left_bracket}")
        end
        @left_brackets << left_bracket
      end

      # Go up (shallower) one level in the bracket nesting.
      #
      # @param right_bracket [String]
      #   Right bracket that must match the corresponding left bracket in the
      #   current nesting level.
      #
      # @return [void]
      def up!(right_bracket)
        unless BracketMatching.right_bracket?(right_bracket)
          raise ArgumentError.new("Not a right bracket: #{right_bracket}")
        end
        if self.left_brackets.empty?
          raise ArgumentError.new(
            "Not currently in a bracket nesting: #{right_bracket}"
          )
        elsif self.left_brackets.last !=
                BracketMatching.left_bracket_of(right_bracket)
          expected_right_bracket =
            BracketMatching.right_bracket_of(self.left_brackets.last)
          raise ArgumentError.new(
            "Right bracket does not match the current bracket nesting: "\
            "should be '#{expected_right_bracket}' but got '#{right_bracket}'."
          )
        else
          @left_brackets.pop
        end
      end

      # Update the bracket nesting based on the given bracket.
      #
      # @param bracket [String]
      #   Bracket that determines whether to call {#down!} or {#up!}.
      #
      # @return [void]
      def update!(bracket)
        if BracketMatching.left_bracket?(bracket)
          self.down!(bracket)
        elsif BracketMatching.right_bracket?(bracket)
          self.up!(bracket)
        else
          raise ArgumentError.new("Not a bracket: #{bracket}")
        end
      end

      # Reset the matcher by clearing the bracket nesting.
      #
      # @return [void]
      def reset!
        @left_brackets.clear
      end
    end

    # Array of left brackets.
    LEFT_BRACKETS = %w[( \[ { <]

    # Array of right brackets in corresponding order as {LEFT_BRACKETS}.
    RIGHT_BRACKETS = %w[) \] } >]

    # Whether the given character is a left bracket.
    #
    # Recognized left brackets are {LEFT_BRACKETS}.
    #
    # @param character [String]
    #   Character to validate.
    #
    # @return [Boolean]
    #   `true` if `character` is a left bracket, otherwise `false`.
    def self.left_bracket?(character)
      LEFT_BRACKETS.include?(character)
    end

    # Whether the given character is a right bracket.
    #
    # Recognized right brackets are {RIGHT_BRACKETS}.
    #
    # @param character [String]
    #   Character to validate.
    #
    # @return [Boolean]
    #   `true` if `character` is a right bracket, otherwise `false`.
    def self.right_bracket?(character)
      RIGHT_BRACKETS.include?(character)
    end

    # Whether the given character is a bracket.
    #
    # Recognized brackets are {LEFT_BRACKETS} and {RIGHT_BRACKETS}.
    #
    # @param character [String]
    #   Character to validate.
    #
    # @return [Boolean]
    #   `true` if `character` is a bracket, otherwise `false`.
    def self.bracket?(character)
      self.left_bracket?(character) || self.right_bracket?(character)
    end

    # Right bracket of the given corresponding left bracket.
    #
    # @param left_bracket [String]
    #   Left bracket that is in {LEFT_BRACKETS}.
    #
    # @return [Boolean]
    #   Right bracket of `left_bracket` or `nil` if `left_bracket` is
    #   unrecognized.
    def self.right_bracket_of(left_bracket)
      index = LEFT_BRACKETS.index(left_bracket)
      index ? RIGHT_BRACKETS[index] : nil
    end

    # Left bracket of the given corresponding right bracket.
    #
    # @param right_bracket [String]
    #   Right bracket that is in {RIGHT_BRACKETS}.
    #
    # @return [Boolean]
    #   Left bracket of `right_bracket` or `nil` if `right_bracket` is
    #   unrecognized.
    def self.left_bracket_of(right_bracket)
      index = RIGHT_BRACKETS.index(right_bracket)
      index ? LEFT_BRACKETS[index] : nil
    end
  end
end
