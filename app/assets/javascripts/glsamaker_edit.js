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
      
      var td = ref.up(".entry");

      Effect.Fade(td, {
        duration: .75,
        afterFinish: function(e) {
          td.remove();
        }
      });
    }
  };
}();

GLSAMaker.editing.templates = function() {
  return {
    /**
     * Displays a drop down menu to select a template to append
     */
    dropdown : function(button, target) {
      var div = $('templates-' + target);

      if (!div) {
        return;
      }

      // Close the popup if it's already open
      if (div.getStyle('display') != 'none') {
        GLSAMaker.editing.templates.close(div);
        return;
      }

      var btn_layout = button.getLayout();

      div.setStyle({
        position: 'absolute',
        right: btn_layout.get('right') + "px",
        top: btn_layout.get('top') + btn_layout.get('height') + 5 + "px"
      });

      Effect.SlideDown(div, {
        duration: .15
      });
    },
    /**
     * Closes a popup
     * 
     * @param target The popup to close
     */
    close : function(target) {
      Effect.SlideUp(target, {
          duration: .2
        });
    },
    /**
     * Observes a field for clicks into template fields and sets the 
     * @param elem
     */
    observeClick : function(elem) {
      elem.observe('click', function(event) {
        var before = '[';
        var after = ']';

        var selection_info = GLSAMaker.misc.getInputSelection(this);
        var text = this.getValue();

        // If the user clicked and did not select
        if (selection_info.start == selection_info.end) {
          var text_before = text.substring(0, selection_info.start);
          var text_after = text.substring(selection_info.end, text.length - 1);

          // check if there is any template before this
          var pos_prev = text_before.search(GLSAMaker.misc.escapeRegExp(after));
          var pos_comp = 0;

          while (pos_prev > 0) {
            pos_comp += pos_prev;
            text_before = text_before.slice(pos_prev);
            pos_prev = text_before.search(GLSAMaker.misc.escapeRegExp(after));
          }

          var pos_before = text_before.search(GLSAMaker.misc.escapeRegExp(before));
          if (pos_before == -1) {
            return;
          }

          // pos_before is our selection start.
          var pos_after = text_after.search(GLSAMaker.misc.escapeRegExp(after));
          if (pos_after == -1) {
            return;
          }

          pos_before += pos_comp;
          pos_after += selection_info.end + 1;

          GLSAMaker.misc.setInputSelection(this, {start: pos_before, end: pos_after});
        }
      })
    }
  };
}();