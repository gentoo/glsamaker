
var BUGZILLA_URL = 'https://bugs.gentoo.org';

$( "#bugs" ).on('textInput input', refreshBugs);

function refreshBugs(){
    $("#bug-refresh-ok").hide();
    $("#bug-refresh-failed").hide();
    $("#bug-spinner").show();

    var bugIds = $("#bugs").val();

    console.log(BUGZILLA_URL +  "/rest/bug?id=" + bugIds);

    // validate data
    var valid = true;
    bugIds.split(",").forEach(function(bugID) {
        if( bugIds == "" || isNaN(bugID) || !(bugID.length == 0 || bugID.length == 6 || bugID.length == 7) ){
            $( "#bug-spinner" ).hide();
            $( "#bug-refresh-failed" ).show();
            valid = false;
        }
    });

    if(valid){
        $.getJSON( BUGZILLA_URL +  "/rest/bug?id=" + bugIds, function( data ) {

            if(data.bugs.length != bugIds.split(",").length){
                $( "#bug-spinner" ).hide();
                $( "#bug-refresh-failed" ).show();
                return
            }

            bugReady = true;
            title = "";
            data.bugs.forEach(function(bug) {
                title = title == "" ? bug.summary : title;
                bugReady = bugReady && bug.whiteboard.includes("[glsa");
            });

            if(bugReady){
                $(".badge-notbugready").hide();
                $(".badge-bugready").show();
            } else {
                $(".badge-bugready").hide();
                $(".badge-notbugready").show();
            }

            if($("#title").val() == ""){
                $("#title").val(title);
            }

            $("#bug-spinner").hide();
            $("#bug-refresh-ok").show();

        });
    }
}
