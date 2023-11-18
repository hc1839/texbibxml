Gem::Specification.new do |s|
  s.name = "texbibxml"
  s.version = "0.1.0"
  s.summary = "Parsing of TeX bibliography as abstract syntax tree in XML."
  s.authors = ["hc1839"]
  s.executables << "texbibxml"
  s.files = [
    "lib/texbibxml.rb",
    "lib/texbibxml/bracket_matching.rb",
    "lib/texbibxml/input_stream.rb",
    "lib/texbibxml/input_stream/character.rb",
    "lib/texbibxml/input_stream/token.rb",
    "lib/texbibxml/tex.rb",
    "lib/texbibxml/tex/bib.rb",
    "lib/texbibxml/tex/bib/author.rb",
    "lib/texbibxml/tex/bib/author/parser.rb",
    "lib/texbibxml/tex/bib/author/token_stream.rb",
    "lib/texbibxml/tex/bib/parser.rb",
    "lib/texbibxml/tex/bib/token_stream.rb",
    "lib/texbibxml/tex/opaque_parser.rb",
    "lib/texbibxml/tex/parser.rb",
    "lib/texbibxml/tex/token_stream.rb"
  ]
  s.homepage = "https://github.com/hc1839/texbibxml"
  s.license = "Apache-2.0"
end
