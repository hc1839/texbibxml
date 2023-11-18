require "minitest/autorun"

require "texbibxml"

module Texbibxml
  module Tex
    module Bib
      module Author
        class TestTokenStream < Minitest::Test
          def test_author
            author = 'Bj{\"{o}}rck, {\r{A}}'
            token_stream = TokenStream.new(author)
            self.assert_equal(
              token_stream.get!,
              { type: "word", value: 'Bj{\"{o}}rck' }
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
              { type: "string", value: '\r{A}' }
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
  end
end
