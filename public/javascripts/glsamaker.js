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

function addCommentDialog(glsaid) {
  Modalbox.show("/glsa/"+glsaid+"/addcomment", {title: "Add comments", width: 600});
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
  if ($('bug-' + bug).className == 'delbug') return;
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

function generateResolution() {
  $('resolution').value = "";
  var resolution = "";
  var unaffected_atoms = new Array();
  var name, atom, comp, version;
  
  // First find and list all upgrade paths...
  for (i = 0; i < $('packages_table_unaffected').select('.entry').length; i++) {
    if ($('packages_table_unaffected').down(".entry", i).select('input[type=hidden][value=ignore]').length > 0)
      continue;
    
    atom = $('packages_table_unaffected').down(".entry", i).down("#glsa_package__atom").value;
    name = atom.split("/")[1];
    if (name == undefined)
      name = "UNDEFINED";
    comp = $('packages_table_unaffected').down(".entry", i).down("#glsa_package__comp").value;
    version = $('packages_table_unaffected').down(".entry", i).down("#glsa_package__version").value;
       
    resolution += "All " + name + " users should upgrade to the latest version:\n\n\
<code>\n\
# emerge --sync\n\
# emerge --ask --oneshot --verbose \"" + comp + atom + "-" + version + "\"</code>\n\n";

    unaffected_atoms.push(atom);
  }
	
  // Check if there are any packages that only have vulnerable entries.
  // These need to be unmerged.
  for (i = 0; i < $('packages_table_vulnerable').select('.entry').length; i++) {
    if ($('packages_table_vulnerable').down(".entry", i).select('input[type=hidden][value=ignore]').length > 0) 
      continue;

    atom = $('packages_table_vulnerable').down(".entry", i).down("#glsa_package__atom").value;
    if (unaffected_atoms.indexOf(atom) == -1) {
      name = atom.split("/")[1];
      if (name == undefined)
        name = "UNDEFINED";
      
      resolution += "We recommend that users unmerge " + name + ":\n\n\
<code>\n\
# emerge --unmerge \"" + atom + "\"</code>";
    }
  }

  $('resolution').value = resolution;
}

function generateDescription() {
  // This code is pretty ugly. You have been warned.
  // cnt is the number of 'entry's
  // act_cnt is cnt minus the number of to be ignored 'entry's
  // i is used to walk down into the i'th entry element
  // act_i is used to keep track of how many packages have been / will be added
  
  var name = "";
  var cnt = $('packages_table_vulnerable').select('.entry').length;
  var act_cnt = cnt - $('packages_table_vulnerable').select('.entry input[type=hidden][value=ignore]').length;
  
  var act_i = 0;
  for (var i = 0; i < cnt; i++) {
    if ($('packages_table_vulnerable').down(".entry", i).select('input[type=hidden][value=ignore]').length > 0)
      continue;
    
    var atom = $('packages_table_vulnerable').down(".entry", i).down("#glsa_package__atom").value;
		
    if (act_cnt > 1 && act_i == act_cnt - 1) {
      name += ", and ";
    } else if (act_cnt > 1 && act_i != 0) {
      name += ", ";
    }
    act_i++;
    name += atom.split("/")[1];
  }
  
  if (name == "undefined")
    name = "UNDEFINED";
    
  $('description').value = "Multiple vulnerabilities have been discovered in " + name + ". Please view the CVE identifiers referenced below for details.";
}

function toggleCommentRead(comment) {
    if ($('commentread-' + comment).value == "true") {
        $('commentread-' + comment).value = "false";
        $('commentflag-' + comment).update('<img src="/images/icons/flag.png" alt="Todo" />');
    }
    else {
        $('commentread-' + comment).value = "true";
        $('commentflag-' + comment).update('<img src="/images/icons/flag-green.png" alt="Done." />');        
    }    
}

function cveinfo(cveid) {
  Modalbox.show("/cve/info/" + cveid, {title: cveid, width: 800});
}

function cvepopup(cveid) {
  window.open("/cve/info/" + cveid, "cvepopup-" + cveid, "width=500, height=400,status=no,menubar=no,toolbar=no,resizable=no");
}

//document.observe('dom:loaded', function() {
                        
//});
