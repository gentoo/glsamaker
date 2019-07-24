module Kramdown
  module Converter
    class Xml < Html
      NOENTITY_MAP = {
        :mdash => '---',
        :ndash => '--',
        :hellip => '...',
        :laquo_space => '<< ',
        :raquo_space => ' >>',
        :laquo => '<',
        :raquo => '>'
      }

      # Overriding to do nothing. We don't want typographic symbols replaced
      def convert_typographic_sym(el, opts)
        NOENTITY_MAP[el.value]
      end
    end
  end
end
