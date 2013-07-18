module Jekyll
  class Ruby < Liquid::Tag

    def initialize(tag_name, params, tokens)
    	super
    	params = params.split(' ')
		  @term = params[0]
  	  @annotation = params[1]

    end

    def render(context)
      if @term && @annotation
      	%(<ruby>#{@term}<rt>#{@annotation}</rt></ruby>)
  	  else
  	  	"Error processing input, expected syntax: {% ruby term annotation %}"
  	  end
    end
  end
end

Liquid::Template.register_tag('ruby', Jekyll::Ruby)