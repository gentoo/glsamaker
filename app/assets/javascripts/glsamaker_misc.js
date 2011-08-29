/**
 * GLSAMaker 2
 * Draft editing JS
 */

if (typeof GLSAMaker == "undefined" || !GLSAMaker) {
  var GLSAMaker = {};
}

if (typeof GLSAMaker.misc == "undefined" || !GLSAMaker.misc) {
  GLSAMaker.misc = function() {
    return {
      /**
       * Find out the selection position in a text field
       * via: http://stackoverflow.com/questions/4928586/get-caret-position-in-html-input
       *
       * @param el
       */
      getInputSelection : function(el) {
        var start = 0, end = 0, normalizedValue, range,
          textInputRange, len, endRange;

        if (typeof el.selectionStart == "number" && typeof el.selectionEnd == "number") {
          start = el.selectionStart;
          end = el.selectionEnd;
        } else {
          range = document.selection.createRange();

          if (range && range.parentElement() == el) {
            len = el.value.length;
            normalizedValue = el.value.replace(/\r\n/g, "\n");

            // Create a working TextRange that lives only in the input
            textInputRange = el.createTextRange();
            textInputRange.moveToBookmark(range.getBookmark());

            // Check if the start and end of the selection are at the very end
            // of the input, since moveStart/moveEnd doesn't return what we want
            // in those cases
            endRange = el.createTextRange();
            endRange.collapse(false);

            if (textInputRange.compareEndPoints("StartToEnd", endRange) > -1) {
              start = end = len;
            } else {
              start = -textInputRange.moveStart("character", -len);
              start += normalizedValue.slice(0, start).split("\n").length - 1;

              if (textInputRange.compareEndPoints("EndToEnd", endRange) > -1) {
                end = len;
              } else {
                end = -textInputRange.moveEnd("character", -len);
                end += normalizedValue.slice(0, end).split("\n").length - 1;
              }
            }
          }
        }

        return {
          start: start,
          end: end
        };
      },
      /**
       * Sets the caret position of a control
       * @param ctrl
       * @param pos
       */
      setInputSelection: function (ctrl, data) {
        if (ctrl.setSelectionRange) {
          ctrl.focus();
          ctrl.setSelectionRange(data.start, data.end);
        }
        else if (ctrl.createTextRange) {
          var range = ctrl.createTextRange();
          range.collapse(true);
          range.moveEnd('character', data.end);
          range.moveStart('character', data.start);
          range.select();
        }
      },
      escapeRegExp : function(text) {
        return text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
      }
    };
  }();
}

GLSAMaker.misc.ui = function() {
  return {
    /**
     * Docks an element to the right
     */
    dock : function(elem) {
      if (!elem) {
        return;
      }

      elem.toggleClassName('docked-right');
    }
  };
}();
