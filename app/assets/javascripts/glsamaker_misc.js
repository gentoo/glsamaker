/**
 * GLSAMaker 2
 * Draft editing JS
 */

if (typeof GLSAMaker == "undefined" || !GLSAMaker) {
  var GLSAMaker = {};
}

if (typeof GLSAMaker.misc == "undefined" || !GLSAMaker.misc) {
  GLSAMaker.misc = function() {
    return {};
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
