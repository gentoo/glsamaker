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
    },
    /**
     * Opens a dialog to add bugs
     */
    add_dialog : function(glsa_id) {
      Modalbox.show("/glsas/" + glsa_id + "/bugs/new", {title: "Add bugs", width: 600});
    }
  };
}();

GLSAMaker.editing.references = function() {
  return {
    /**
     * Removes a reference from a draft being edited
     */
    del : function(ref) {
      // no such reference, or already removed
      if (!ref) {
        return;
      }
      
      var td = ref.up(".entry")

      Effect.Fade(td, {
        duration: .75,
        afterFinish: function(e) {
          td.remove();
        }
      });
    },
    /**
     * Opens a dialog to import references from external data
     */
    import_dialog : function(glsa_id) {
      Modalbox.show("/glsa/import_references/" + glsa_id, {title: "Import references", width: 800});
    }
  };
}();

GLSAMaker.editing.packages = function() {
  return {
    /**
     * Removes a reference from a draft being edited
     */
    del : function(ref) {
      // no such reference, or already removed
      if (!ref) {
        return;
      }
      
      var td = ref.up(".entry")

      Effect.Fade(td, {
        duration: .75,
        afterFinish: function(e) {
          td.remove();
        }
      });
    }
  };
}();