/**
  Sets the count of lines if more than 5 or less than 50.
*/
function lines(id, amount) {
//  if ($(id).rows > 0 && $(id).rows <= 50) {
      $(id).rows += amount;
//  }
}

/**
  Toggles extra-wide input fields
**/
function toggleWide(id) {
  if ($(id).style.width == "140%") {
    $(id).style.width = "";
    $(id + "-widebtn").childNodes[1].src = "/images/icons/more_width.png";
    $(id + "-widebtn").title = "More columns";
  } else {
    $(id).style.width = "140%";
    $(id + "-widebtn").childNodes[1].src = "/images/icons/less_width.png";
    $(id + "-widebtn").title = "Fewer columns";
  }
}

function addBugDialog(glsaid) {
  Modalbox.show("/glsa/"+glsaid+"/addbug", {title: "Add bugs", width: 600});
}

function backgroundDialog() {
  Modalbox.show("/tools/background/?id=dev-lang/ruby", {title: "Get background", width: 600});
}


function getClientWidth() {
  return document.compatMode=='CSS1Compat' && !window.opera?document.documentElement.clientWidth:document.body.clientWidth;
}

function buginfo(bugid) {
  Modalbox.show("/bug/" + bugid, {title: "Bug " + bugid, width: 800});
}

/** Marks a bug row as deleted **/
function markBugAsDeleted(bug) {
  $('bug-' + bug).className = 'delbug';
  
  var minus = new Image();
  minus.src = '/images/icons/minus-small.png';
  minus.alt = 'This bug will be removed when saving';
  
  $('bug-' + bug).getElementsByTagName('td')[0].appendChild(minus);
}

function markEntryAsDeleted(elem, type) {
  if (elem.up('.entry').hasClassName('delbug')) {
    elem.up('.entry').select('input[type=hidden][value=ignore]').each(function(s) { s.remove() });
  } else {
    var hiddenField = document.createElement("input");
    hiddenField.name = "glsa[" + type + "][][ignore]";
    hiddenField.type = "hidden";
    hiddenField.value = "ignore";
    elem.up('.entry').appendChild(hiddenField);
  }
  elem.up('.entry').toggleClassName("delbug");
}
//document.observe('dom:loaded', function() {
                        
//});
