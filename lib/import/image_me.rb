# markdown normalizer to be used by importers
#
#
require 'htmlentities'
require 'nokogiri'
module Import; end
module Import::ImageMe

  def self.get_raw_post(raw)
    code = raw.dup

    # <p><a href="/wp-content/uploads/discussions/1-1000/948-1114ChameleonAC.JPG target="_self"><img src="/wp-content/uploads/discussions/1-1000/949-1114ChameleonAC.JPG?width=250" width="250" class="align-left"/></a></p><br />
    code.gsub!(/<a href="\/wp-content\/uploads\/\S+(jpg|JPG|png|PNG|jpeg|JPEG|gif|GIF|svg|SVG|bmp|BMP)".+>(.+)<\/a>/) {
      $2
    }

    code.gsub!(/<a href="\/wp-content\/uploads\/\S+(jpg|JPG|png|PNG|jpeg|JPEG|gif|GIF|svg|SVG|bmp|BMP)">(.+)<\/a>/) {
      $2
    }


    # ----------------------------------

    code.gsub!(/<a target="_self" href="\/wp-content\/uploads\/\S+(jpg|JPG|png|PNG|jpeg|JPEG|gif|GIF|svg|SVG|bmp|BMP)".+>(.+)<\/a>/) {
      $2
    }

    code.gsub!(/<a target="_self" href="\/wp-content\/uploads\/\S+(jpg|JPG|png|PNG|jpeg|JPEG|gif|GIF|svg|SVG|bmp|BMP)">(.+)<\/a>/) {
      $2
    }

    # ----------------------------------

    code.gsub!(/<a href="\/wp-content\/uploads\/\S+(jpg|JPG|png|PNG|jpeg|JPEG|gif|GIF|svg|SVG|bmp|BMP)".+>(.+) <\/a>/) {
      $2
    }

    code.gsub!(/<a href="\/wp-content\/uploads\/\S+(jpg|JPG|png|PNG|jpeg|JPEG|gif|GIF|svg|SVG|bmp|BMP)">(.+) <\/a>/) {
      $2
    }

    code.gsub!(/<a href="\/wp-content\/uploads\/\S+(jpg|JPG|png|PNG|jpeg|JPEG|gif|GIF|svg|SVG|bmp|BMP)".+> (.+)<\/a>/) {
      $2
    }

    code.gsub!(/<a href="\/wp-content\/uploads\/\S+(jpg|JPG|png|PNG|jpeg|JPEG|gif|GIF|svg|SVG|bmp|BMP)"> (.+)<\/a>/) {
      $2
    }


    ################################################################################

    code.gsub!(/<a href="http:\/\/dynamobim.com\/wp-content\/uploads\/\S+(jpg|JPG|png|PNG|jpeg|JPEG|gif|GIF|svg|SVG|bmp|BMP)".+>(.+)<\/a>/) {
      $2
    }

    code.gsub!(/<a href="http:\/\/dynamobim.com\/wp-content\/uploads\/\S+(jpg|JPG|png|PNG|jpeg|JPEG|gif|GIF|svg|SVG|bmp|BMP)">(.+)<\/a>/) {
      $2
    }

    code.gsub!(/<a href="http:\/\/dynamobim.org\/wp-content\/uploads\/\S+(jpg|JPG|png|PNG|jpeg|JPEG|gif|GIF|svg|SVG|bmp|BMP)".+>(.+)<\/a>/) {
      $2
    }

    code.gsub!(/<a href="http:\/\/dynamobim.org\/wp-content\/uploads\/\S+(jpg|JPG|png|PNG|jpeg|JPEG|gif|GIF|svg|SVG|bmp|BMP)">(.+)<\/a>/) {
      $2
    }

    # --------

    code.gsub!(/<a href="http:\/\/dynamobim.com\/wp-content\/uploads\/\S+(jpg|JPG|png|PNG|jpeg|JPEG|gif|GIF|svg|SVG|bmp|BMP)".+>(.+) <\/a>/) {
      $2
    }

    code.gsub!(/<a href="http:\/\/dynamobim.com\/wp-content\/uploads\/\S+(jpg|JPG|png|PNG|jpeg|JPEG|gif|GIF|svg|SVG|bmp|BMP)">(.+) <\/a>/) {
      $2
    }

    code.gsub!(/<a href="http:\/\/dynamobim.org\/wp-content\/uploads\/\S+(jpg|JPG|png|PNG|jpeg|JPEG|gif|GIF|svg|SVG|bmp|BMP)".+>(.+) <\/a>/) {
      $2
    }

    code.gsub!(/<a href="http:\/\/dynamobim.org\/wp-content\/uploads\/\S+(jpg|JPG|png|PNG|jpeg|JPEG|gif|GIF|svg|SVG|bmp|BMP)">(.+) <\/a>/) {
      $2
    }

    # --------

    code.gsub!(/<a href="http:\/\/dynamobim.com\/wp-content\/uploads\/\S+(jpg|JPG|png|PNG|jpeg|JPEG|gif|GIF|svg|SVG|bmp|BMP)".+> (.+)<\/a>/) {
      $2
    }

    code.gsub!(/<a href="http:\/\/dynamobim.com\/wp-content\/uploads\/\S+(jpg|JPG|png|PNG|jpeg|JPEG|gif|GIF|svg|SVG|bmp|BMP)"> (.+)<\/a>/) {
      $2
    }

    code.gsub!(/<a href="http:\/\/dynamobim.org\/wp-content\/uploads\/\S+(jpg|JPG|png|PNG|jpeg|JPEG|gif|GIF|svg|SVG|bmp|BMP).+> (.+)<\/a>/) {
      $2
    }

    code.gsub!(/<a href="http:\/\/dynamobim.org\/wp-content\/uploads\/\S+(jpg|JPG|png|PNG|jpeg|JPEG|gif|GIF|svg|SVG|bmp|BMP)> (.+)<\/a>/) {
      $2
    }

    ################################################################################

    # <img src="/wp-content/uploads/discussions/1-1000/798-Levels.png?width=750" width="750" class="align-left"/>>?>>xc>
    code.gsub!(/<img(?:.+)src="\/wp-content\/uploads\/(\S+)"(?:.*)\/>/) {
      "<img src='http://dynamobim.com/wp-content/uploads/#{$1}'/>"
    }

    code
  end

  def self.has_attachment(raw)

    if raw =~ /<a href="http:\/\/dynamobim.com\/wp-content\/uploads\/\S+(dyn|rvt|rfa|dyf|py|rft|rte|3ds|dwg|dxf|mp3|mp4|mpeg|mpg|pdf|ppt|pptx|rtf|sat|stl|swf|xls|xslx)".+>(.+)<\/a>/ ||
      raw =~ /<a href="http:\/\/dynamobim.org\/wp-content\/uploads\/\S+(dyn|rvt|rfa|dyf|py|rft|rte|3ds|dwg|dxf|mp3|mp4|mpeg|mpg|pdf|ppt|pptx|rtf|sat|stl|swf|xls|xslx)".+>(.+)<\/a>/ ||
      raw =~ /<a href="\/wp-content\/uploads\/\S+(dyn|rvt|rfa|dyf|py|rft|rte|3ds|dwg|dxf|mp3|mp4|mpeg|mpg|pdf|ppt|pptx|rtf|sat|stl|swf|xls|xslx)".+>(.+)<\/a>/
      return true
    else
      return false
    end

  end
end
