require "minitest/autorun"

require "texbibxml"

module Texbibxml
  module Tex
    module Bib
      class TestTokenStream < Minitest::Test
        def test_texbib_entry
          entry = <<-'EOF'
            @article{
              bjorck-1994,
              author = "Bj{\"{o}}rck, {\r{A}}",
              title = {Numerics of Gram-Schmidt Orthogonalization},
              journal = {Linear Algebra and its Applications},
              year = "1994",
              volume = "197--198",
              pages = "297--316"
            }
EOF
          token_stream = TokenStream.new(entry)
          self.assert_equal(
            token_stream.get!,
            { type: "entry_type", value: "@article" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "bracket", value: "{" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "identifier", value: "bjorck-1994" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "punctuation", value: "," }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "identifier", value: "author" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "operator", value: "=" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "punctuation", value: "\"" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "string", value: 'Bj{\"{o}}rck, {\r{A}}' }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "punctuation", value: "\"" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "punctuation", value: "," }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "identifier", value: "title" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "operator", value: "=" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "bracket", value: "{" }
          )
          self.assert_equal(
            token_stream.get!,
            {
              type: "string",
              value: "Numerics of Gram-Schmidt Orthogonalization"
            }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "bracket", value: "}" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "punctuation", value: "," }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "identifier", value: "journal" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "operator", value: "=" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "bracket", value: "{" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "string", value: "Linear Algebra and its Applications" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "bracket", value: "}" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "punctuation", value: "," }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "identifier", value: "year" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "operator", value: "=" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "punctuation", value: "\"" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "string", value: "1994" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "punctuation", value: "\"" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "punctuation", value: "," }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "identifier", value: "volume" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "operator", value: "=" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "punctuation", value: "\"" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "string", value: "197--198" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "punctuation", value: "\"" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "punctuation", value: "," }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "identifier", value: "pages" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "operator", value: "=" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "punctuation", value: "\"" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "string", value: "297--316" }
          )
          self.assert_equal(
            token_stream.get!,
            { type: "punctuation", value: "\"" }
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
