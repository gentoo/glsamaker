/**
 * GLSAMaker 2
 * Draft editing JS
 */

if (typeof GLSAMaker == "undefined" || !GLSAMaker) {
  var GLSAMaker = {};
}

if (typeof GLSAMaker.editing == "undefined" || !GLSAMaker.editing) {
  GLSAMaker.editing = function() {
    return {};
  }();
}

GLSAMaker.editing.bugs = function() {
  return {
    /**
     * Removes a bug from a draft being edited
     */
    del : function(bug_id) {
      // no such bug, or already removed
      if (!$('bug-' + bug_id)) {
        return;
      }

      Effect.Fade('bug-' + bug_id, {
        duration: .75,
        afterFinish: function(e) {
          $('bug-' + bug_id).remove();
        }
      });
    }
  };
}();
