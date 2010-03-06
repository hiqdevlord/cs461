module CompaniesHelper
  require 'syntax/convertors/html'

  def syn(f)
    convertor = Syntax::Convertors::HTML.for_syntax "ruby"
    convertor.convert( f )
  end
end
