require "minitest/autorun"

require "texbibxml"

module Texbibxml
  module Tex
    class TestTokenStream < Minitest::Test
      def test_author
        author = 'Bj{\"{o}}rck, {\r{A}}'
        token_stream = TokenStream.new(author)
        self.assert_equal(
          token_stream.get!,
          { type: "word", value: "Bj" }
        )
        self.assert_equal(
          token_stream.get!,
          { type: "bracket", value: "{" }
        )
        self.assert_equal(
          token_stream.get!,
          { type: "command", value: "\\\"" }
        )
        self.assert_equal(
          token_stream.get!,
          { type: "bracket", value: "{" }
        )
        self.assert_equal(
          token_stream.get!,
          { type: "word", value: "o" }
        )
        self.assert_equal(
          token_stream.get!,
          { type: "bracket", value: "}" }
        )
        self.assert_equal(
          token_stream.get!,
          { type: "bracket", value: "}" }
        )
        self.assert_equal(
          token_stream.get!,
          { type: "word", value: "rck" }
        )
        self.assert_equal(
          token_stream.get!,
          { type: "punctuation", value: "," }
        )
        self.assert_equal(
          token_stream.get!,
          { type: "whitespace", value: " " }
        )
        self.assert_equal(
          token_stream.get!,
          { type: "bracket", value: "{" }
        )
        self.assert_equal(
          token_stream.get!,
          { type: "command", value: "\\r" }
        )
        self.assert_equal(
          token_stream.get!,
          { type: "bracket", value: "{" }
        )
        self.assert_equal(
          token_stream.get!,
          { type: "word", value: "A" }
        )
        self.assert_equal(
          token_stream.get!,
          { type: "bracket", value: "}" }
        )
        self.assert_equal(
          token_stream.get!,
          { type: "bracket", value: "}" }
        )
        self.assert(token_stream.eof?)
      end
    end
  end
end
