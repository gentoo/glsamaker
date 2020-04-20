
var BUGZILLA_URL = 'https://bugs.gentoo.org';


function destroyDatatable(){
    while (window.dataTables.length !== 0) {
        window.dataTables.pop().destroy();
    }
}


function initDatatable(){
    if (window.dataTables.length === 0 && $('.data-table').length !== 0) {
        $('.data-table').each((_, element) => {

            var table = $(element).DataTable( {
                "processing": true,
                "serverSide": true,
                "ajax": "/cve/data",
                "order": [[ 0, "desc" ]],
                "columnDefs": [
                    {
                        "render": function ( data, type, row ) {
                            return '<b>' + data + '</b>'
                        },
                        "targets"  : 'render-bold',
                    },
                    {
                        "render": function ( data, type, row ) {
                            var bugs = ' <i>no assigned bugs</i>';
                            if(data!='' && JSON.parse(data) != null){
                                bugs = "";
                                JSON.parse(data).forEach(function(bug) {
                                    bugs = bugs + bug.id + ",";
                                });
                            }
                            return bugs;
                        },
                        "targets"  : 'render-bug',
                    },
                    {
                        "targets"  : 'no-sort',
                        "orderable": false,
                    },
                    {
                        "render": function ( data, type, row ) {
                            return renderState(data, row[0])
                        },
                        "targets"  : 'render-state',
                    },
                    {
                        "render": function ( data, type, row ) {
                            if(data == "0.0"){
                                return '<span class="badge badge-secondary">None</span>'
                            }else if(parseFloat(data) < 4.0) {
                                return '<span class="badge badge-success">' + data + '</span>'
                            }else if(parseFloat(data) < 7.0) {
                                return '<span class="badge badge-warning">' + data + '</span>'
                            }else if(parseFloat(data) < 9.0) {
                                return '<span class="badge badge-danger">' + data + '</span>'
                            }else if(parseFloat(data) < 10.0) {
                                return '<span class="badge badge-danger">' + data + '</span>'
                            }
                            return

                        },
                        "targets"  : 'render-basescore',
                    },
                    {
                        "targets": 'hide',
                        "visible": false
                    }],
                buttons: [
                    {
                        extend: 'colvis',
                        columns: ':not(.noVis)',
                        text: 'Columns',
                        className: 'btn-sm btn-outline-secondary colvis-btn'
                    },
                    {
                        text: 'Fullscreen',
                        className: 'btn-sm btn-outline-secondary colvis-btn fullscreen-btn',
                        action: function ( e, dt, node, config ) {
                            if(window.location.href.includes("fullscreen")){
                                Turbolinks.visit("/cve/tool");
                            } else {
                                Turbolinks.visit("/cve/tool/fullscreen");
                            }
                        }
                    },
                    {
                        text: 'New',
                        className: 'btn-sm btn-outline-secondary float-left colvis-btn new-btn',
                        action: function ( e, dt, node, config ) {
                            Turbolinks.visit("/cve/new");
                        }
                    },
                    {
                        text: 'State',
                        className: 'btn-sm btn-outline-secondary float-left colvis-btn mr-2 dropdown-toggle view-filter-state'
                    }
                ],
                "initComplete": function( settings, json ) {

                    $('#table_id_length').append( "<span class='ml-4'> Show </span>" );
                    table.buttons().container()
                        .appendTo( $('#table_id_length') );
                    $('.buttons-colvis').removeClass("btn-secondary");

                    $('#table_id_length').append( "<span class='ml-4'> Toggle </span>" );
                    $('.fullscreen-btn').appendTo( $('#table_id_length') );


                    $('#table_id_filter').prepend( '<div id="filterByStateDropdown" class="dropdown"> <div class="dropdown-menu" aria-labelledby="dropdownMenuButton"> <button id="filterByStateNew" class="dropdown-item"><span class="badge badge-danger state">New</span></button> <button id="filterByStateAssigned" class="dropdown-item"><span class="badge badge-success state">Assigned</span></button> <button id="filterByStateNFU" class="dropdown-item"><span class="badge badge-info state">NFU</span></button> <button id="filterByStateLater" class="dropdown-item"><span class="badge badge-warning state">Later</span></button> <button id="filterByStateInvalid" class="dropdown-item"><span class="badge badge-dark state">Invalid</span></button> <div class="dropdown-divider"></div> <button id="filterByStateAll" class="dropdown-item">All</button> </div> </div>' );
                    $('#table_id_filter').prepend( "<span class='m-1 ml-5 float-left'> Filter by </span>" );
                    $('.view-filter-state').prependTo( $('#filterByStateDropdown') );
                    document.querySelector(".view-filter-state").setAttribute('data-toggle', 'dropdown');

                    $('#table_id_filter').prepend( $('.new-btn') );
                    $('#table_id_filter').prepend( "<span class='m-1 float-left'> Create </span>" );

                    $("#filterByStateNew").on('click', function () {
                        $('.view-filter-state').text("New");
                        table.columns( 10 ).search(  "New" ).draw();
                    });

                    $("#filterByStateAssigned").on('click', function () {
                        $('.view-filter-state').text("Assigned");
                        table.columns( 10 ).search(  "Assigned" ).draw();
                    });

                    $("#filterByStateNFU").on('click', function () {
                        $('.view-filter-state').text("NFU");
                        table.columns( 10 ).search(  "NFU" ).draw();
                    });

                    $("#filterByStateLater").on('click', function () {
                        $('.view-filter-state').text("Later");
                        table.columns( 10 ).search(  "Later" ).draw();
                    });

                    $("#filterByStateInvalid").on('click', function () {
                        $('.view-filter-state').text("Invalid");
                        table.columns( 10 ).search(  "Invalid" ).draw();
                    });

                    $("#filterByStateAll").on('click', function () {
                        $('.view-filter-state').text("State");
                        table.columns( 10 ).search(  "" ).draw();
                    });

                },

            });

            window.dataTables.push(table);

            // Add event listener for opening and closing details
            $('#table_id tbody').on('click', 'td', function () {
                var tr = $(this).closest('tr');
                var row = table.row( tr );

                if ( row.child.isShown() ) {
                    // This row is already open - close it
                    row.child.hide();
                    tr.removeClass('shown');
                }
                else {
                    // Open this row
                    row.child( format(row.data()) ).show();
                    tr.addClass('shown');

                    registerCommentListener();

                    registerAssignBugListener();

                    registerChangeStateListener();

                }
            } );

        });
    }
}

function renderState( d, cveid ) {
    if(d == "New"){
        return '<span data-cveid="' + cveid + '" class="badge badge-danger state">' + d + '</span>'
    }else if(d == "Assigned") {
        return '<span data-cveid="' + cveid + '" class="badge badge-success state">' + d + '</span>'
    }else if(d == "NFU") {
        return '<span data-cveid="' + cveid + '" class="badge badge-info state">' + d + '</span>'
    }else if(d == "Later") {
        return '<span data-cveid="' + cveid + '" class="badge badge-warning state">' + d + '</span>'
    }else if(d == "Invalid") {
        return '<span data-cveid="' + cveid + '" class="badge badge-dark state">' + d + '</span>'
    }else{
        return '<span data-cveid="' + cveid + '" class="badge badge-primary state">' + d + '</span>'
    }
    return d
}

function format ( d ) {

    var bugs = ' <i>no assigned bugs</i>';
    if(d[3]!='' && JSON.parse(d[3]) != null){

        bugs = "";

        JSON.parse(d[3]).forEach(function(bug) {
            bugs = bugs + bug.id + ",";
        });

    }

    var packages = ' <i>no assigned packages</i>';
    if(d[2]!=''){
        packages = d[2];
    }

    var comments = '<div class="col-12 text-center mb-3"> <i>- no comments yet -</i> </div>';
    if(d[7]!='null') {
        console.log("CommentsObject");
        console.log(d[7]);
        console.log(JSON.parse(d[7]));

        var commentsObjects = JSON.parse(d[7]);
        comments = '';
        commentsObjects.forEach(function (comment, index) {
            var commentDate = '<small class="text-muted">' + comment.Date.split("T")[0] + ' ' + comment.Date.split("T")[1].split(".")[0] + ' UTC</small>';
            comments = comments + '<div class="col-3 text-right mb-3"><b>' + comment.User.Name + '</b><br/>' + commentDate + '</div><div class="col-9 mb-3"><div class="card" style="background: none;"><div class="card-body">' + comment.Message + '</div></div></div>';
        });
    }

    var bugs_cards = '<div class="col-12 text-center mb-3"> <i>- no assigned bugs yet -</i> </div>';
    if(d[3]!='' && JSON.parse(d[3]) != null) {

        bugs_cards = '';

        JSON.parse(d[3]).forEach(function(bug) {
            var newBug = '<div class="col-3 text-right mb-3"><b> Bug ' + bug.id + '</b></div><div class="col-9 mb-3"><div class="card" style="background: none;"><div class="card-body pt-2"><span class="bug-title" data-cveid="' + d[0] + '" data-bugid="' + bug.id + '">' + escape(bug.summary) + '</span><div class="row"><div class="col-6"><small>Alias: </small><small class="bug-alias" data-cveid="' + d[0] + '" data-bugid="' + bug.id + '">' + bug.alias.join(", ") + '</small><br/><small>Status: </small><small class="bug-status" data-cveid="' + d[0] + '" data-bugid="' + bug.id + '">' + escape(bug.status) + '</small></div><div class="col-6"><small>Whiteboard: </small><small class="bug-whiteboard" data-cveid="' + d[0] + '" data-bugid="' + bug.id + '">' + escape(bug.whiteboard) + '</small><br/><small>Created: </small><small class="bug-created" data-cveid="' + d[0] + '" data-bugid="' + bug.id + '">' + escape(bug.creation_time) + '</small></div></div></div></div></div>';
            bugs_cards = bugs_cards + newBug;
        });

    }

    var changes = '<i>no changes yet</i>';

    // `d` is the original data object for the row
    return '<div class="container px-0">' +
        '<div class="row py-2">' +
        '<div class="col-7"><h4><b>Details of ' + d[0] + '</b></h4></div><div class="col-5"></div>' +
        '<div class="col-7">' +
        '<span>' + d[1] + '</span>' +
        '<div data-cveid="' + d[0] + '" class="row bugs-section mt-4">' +
        bugs_cards +
        '</div>' +
        '<div data-cveid="' + d[0] + '" class="row new-bug-row" style="display: none;">' +
        '<div class="col-3 text-right"><b>New Bug</b></div>'+
        '<div class="col-9"><textarea data-cveid="' + d[0] + '" class="form-control new-bug" id="exampleFormControlTextarea1" rows="3" placeholder="Add a bug to ' + d[0] + '"></textarea></div>'+
        '<div class="col-12 mt-2 mb-3"><button data-cveid="' + d[0] + '" type="button" class="btn-save-new-bug float-right btn btn-sm btn-outline-success">Save</button><button data-cveid="' + d[0] + '" type="button" class="mr-2 float-right btn btn-sm btn-outline-danger btn-cancel-new-bug">Cancel</button></div>' +
        '</div>'+
        '<div data-cveid="' + d[0] + '" class="row assign-bug-row" style="display: none;">' +
        '<div class="col-3 text-right"><b>Assign Bug</b></div>'+
        '<div class="col-9"><input type="text" data-cveid="' + d[0] + '" class="form-control assign-bug" maxlength="6" placeholder="Bug ID"/></div>'+
        '<div class="col-12 mt-2 mb-3"><button data-cveid="' + d[0] + '" type="button" class="btn-save-assign-bug float-right btn btn-sm btn-outline-success">Save</button><button data-cveid="' + d[0] + '" type="button" class="mr-2 float-right btn btn-sm btn-outline-danger btn-cancel-assign-bug">Cancel</button></div>' +
        '</div>'+
        '<div class="row pb-4">' +
        (window.userCanAssignBug ? '<div class="col-12 mb-3"><button type="button" data-cveid="' + d[0] + '" class="trigger-assign-bug float-right btn btn-sm btn-outline-primary">Assign Bug</button><button type="button" data-cveid="' + d[0] + '" class="trigger-new-bug mr-2 float-right btn btn-sm btn-outline-primary" disabled>Create New Bug</button></div>' : '') +
        '</div>'+
        //        '<hr/>' +
        '<div data-cveid="' + d[0] + '" class="row comments-section pb-1 mt-4">' +
        //        '<div class="col-12 mb-2"><b>Comments</b></div>' +
        comments +
        '</div>' +
        '<div data-cveid="' + d[0] + '" class="row new-comment-row" style="display: none;">' +
        '<div class="col-3 text-right"><b>New Comment</b></div>'+
        '<div class="col-9"><textarea data-cveid="' + d[0] + '" class="form-control new-comment" id="exampleFormControlTextarea1" rows="3" placeholder="Add a comment to ' + d[0] + '"></textarea></div>'+
        '<div class="col-12 mt-2 mb-3"><button data-cveid="' + d[0] + '" type="button" class="save-new-comment float-right btn btn-sm btn-outline-success">Save</button><button data-cveid="' + d[0] + '" type="button" class="mr-2 float-right btn btn-sm btn-outline-danger btn-cancel-comment">Cancel</button></div>' +
        '</div>'+
        '<div class="row pb-4">' +
        (window.userCanComment ? '<div class="col-12 mb-3"><button type="button" data-cveid="' + d[0] + '" class="trigger-new-comment float-right btn btn-sm btn-outline-primary">Add New Comment</button></div>' : '') +
        '</div>'+
        '</div>'+
        '<div class="col-5">' +
        '<table class="w-100 float-right" cellpadding="5" cellspacing="0" border="0" style="padding-left:50px;">'+
        '<tr><td><b>State:</b></td><td>'+ renderState(d[10], d[0]) + ( (window.userCanChangeState && d[10] != 'Assigned') ? '<div style="display: inline-block;" class="float-right"><a class="btn btn-sm btn-link p-0" data-toggle="collapse" href="#collapseExample-' +  d[0] + '" role="button" aria-expanded="false" aria-controls="collapseExample"> change </a></div>' : '') + '</td></tr>'+
        '<tr><td data-cveid="' + d[0] + '" class="change-state-form collapse" id="collapseExample-' + d[0] +'" colspan="2" style="border-top: none;"><div class="row"><div class="col-7"><input data-cveid="' + d[0] + '" class="change-state-reason form-control form-control-sm" type="text" placeholder="reason (required)" /></div> <div class="col-5"> <button data-cveid="' + d[0] + '" type="button" class="change-state-invalid my-1 btn btn-sm btn-outline-dark float-right mr-2 py-0 px-1">Invalid</button> <button data-cveid="' + d[0] + '" type="button" class="change-state-later my-1 btn btn-sm btn-outline-warning float-right mr-2 py-0 px-1">Later</button> <button data-cveid="' + d[0] + '" type="button" class="change-state-nfu my-1 btn btn-sm btn-outline-info float-right mr-2 py-0 px-1">NFU</button></div></div> </td></tr>' +
        '<tr><td><b>Last Modified:</b></td><td>'+ d[8] + '</td></tr>'+
        '<tr><td><b>Published:</b></td><td>'+ d[9] + '</td></tr>'+
        '<tr><td><b>Base Score:</b></td><td>'+ d[4] + '</td></tr>'+
        '<tr><td><b>Impact:</b></td><td>'+ d[5] + '</td></tr>'+
        '<tr><td><b>Bug(s):</b></td><td>'+ bugs + '</td></tr>'+
        '<tr><td><b>Package(s):</b></td><td>'+ packages + '</td></tr>'+
        '<tr><td><b>Reference(s):</b></td><td>'+ d[6] + '</td></tr>'+
        //        '<tr><td><b>Comments:</b></td><td>'+ d[7] + '</td></tr>'+
        //        '<tr><td><b>Changelog:</b></td><td>'+ changes + '</td></tr>'+
        '</table>'+
        '</div>'+
        '</div>'+
        '</div>';
}


$( "#disable-twofactor-notice" ).click(function() {
    $("#twofactor-notice").hide();
    $.get( "/account/2fa/notice/disable", function( data ) {
        console.log("Disabled 2FA Notice.")
    });
});


function registerCommentListener(){

    $( ".trigger-new-comment" ).click(function() {
        $('.new-comment-row[data-cveid="' + $(this).data( "cveid" ) + '"]').show();
        $('.trigger-new-comment[data-cveid="' + $(this).data( "cveid" ) + '"]').hide();
    });

    $( ".btn-cancel-comment" ).click(function() {
        $('.new-comment-row[data-cveid="' + $(this).data( "cveid" ) + '"]').hide();
        $('.trigger-new-comment[data-cveid="' + $(this).data( "cveid" ) + '"]').show();
    });

    $( ".save-new-comment" ).click(function() {
        var cveid = $(this).data( "cveid" );
        var comment = $('textarea.new-comment[data-cveid="' + cveid + '"]').val();

        $.post(
            '/cve/comment/add',
            {
                cveid: cveid,
                comment: comment,
            },
            function(data) {

                if(data != "err") {
                    console.log("hi");
                    console.log(data);
                    var comment = JSON.parse(data);
                    var commentDate = '<small class="text-muted">' + comment.Date.split("T")[0] + ' ' + comment.Date.split("T")[1].split(".")[0] + ' UTC</small>';
                    var newComment = '<div class="col-3 text-right mb-3"><b>' + comment.User.Name + '</b><br/>' + commentDate + '</div><div class="col-9 mb-3"><div class="card" style="background: none;"><div class="card-body">' + comment.Message + '</div></div></div>';
                    $('.comments-section[data-cveid="' + cveid + '"]').append(newComment);
                }
                return
            });
    });
}

function registerAssignBugListener(){


    $( ".trigger-assign-bug" ).click(function() {
        var cveid = $(this).data( "cveid" );
        showAssignBugForm(cveid);
    });

    $( ".btn-cancel-assign-bug" ).click(function() {
        var cveid = $(this).data( "cveid" );
        hideAssignBugForm(cveid);
    });

    $( ".btn-save-assign-bug" ).click(function() {
        var cveid = $(this).data( "cveid" );
        var bugid = $('input.assign-bug[data-cveid="' + cveid + '"]').val();

        assignBug(cveid, bugid);
        hideAssignBugForm(cveid);
    });
}

function showAssignBugForm(cveid){
    $('.assign-bug-row[data-cveid="' + cveid + '"]').show();
    $('.trigger-assign-bug[data-cveid="' + cveid + '"]').hide();
    $('.trigger-new-bug[data-cveid="' + cveid + '"]').hide();
}

function hideAssignBugForm(cveid) {
    $('.assign-bug-row[data-cveid="' + cveid + '"]').hide();
    $('.trigger-assign-bug[data-cveid="' + cveid + '"]').show();
    $('.trigger-new-bug[data-cveid="' + cveid + '"]').show();
}


function assignBug(cveid, bugid){

    $.post(
        '/cve/bug/assign',
        {
            cveid: cveid,
            bugid: bugid,
        },
        function(data) {
            if(data != "err") {
                console.log("hi");
                console.log(data);

                if(data == "ok"){

                    setStateToAssigned(cveid);

                    var newBug = '<div class="col-3 text-right mb-3"><b> Bug ' + bugid + '</b></div><div class="col-9 mb-3"><div class="card" style="background: none;"><div class="card-body pt-2"><span class="bug-title" data-cveid="' + cveid + '" data-bugid="' + bugid + '" >Loading...</span><br/><small>Alias: </small><small class="bug-alias" data-cveid="' + cveid + '" data-bugid="' + bugid + '"></small><br/><small>Status: </small><small class="bug-status" data-cveid="' + cveid + '" data-bugid="' + bugid + '"></small><br/><small>Resolution: </small><small class="bug-resolution" data-cveid="' + cveid + '" data-bugid="' + bugid + '"></small><br/><small>Whiteboard: </small><small class="bug-whiteboard" data-cveid="' + cveid + '" data-bugid="' + bugid + '"></small><br/><small>Created: </small><small class="bug-created" data-cveid="' + cveid + '" data-bugid="' + bugid + '"></small><br/><small>Last Update: </small><small class="bug-last-update" data-cveid="' + cveid + '" data-bugid="' + bugid + '"></small></div></div></div>';
                    $('.bugs-section[data-cveid="' + cveid + '"]').append(newBug);

                    updateBugInformation(cveid, bugid);
                }

            }
        });
}


function registerChangeStateListener(){

    $( ".change-state-nfu" ).click(function() {
        var cveid = $(this).data( "cveid" );
        var reason = $('.change-state-reason[data-cveid="' + cveid + '"]').val();
        if(reason != "") {
            changeState(cveid, reason, "NFU");
            $("#collapseExample-" + cveid).removeClass('show');
        }else{
            $('.change-state-reason[data-cveid="' + cveid + '"]').addClass('is-invalid');
        }
    });

    $( ".change-state-invalid" ).click(function() {
        var cveid = $(this).data( "cveid" );
        var reason = $('.change-state-reason[data-cveid="' + cveid + '"]').val();
        if(reason != "") {
            changeState(cveid, reason, "Invalid");
            $("#collapseExample-" + cveid).removeClass('show');
        }else{
            $('.change-state-reason[data-cveid="' + cveid + '"]').addClass('is-invalid');
        }
    });

    $( ".change-state-later" ).click(function() {
        var cveid = $(this).data( "cveid" );
        var reason = $('.change-state-reason[data-cveid="' + cveid + '"]').val();
        if(reason != ""){
            changeState(cveid, reason, "Later");
            $("#collapseExample-" + cveid).removeClass('show');
        }else{
            $('.change-state-reason[data-cveid="' + cveid + '"]').addClass('is-invalid');
        }
    });
}

function changeState(cveid, reason, newState){

    $.post(
        '/cve/state/change',
        {
            cveid: cveid,
            newstate: newState,
            reason: reason,
        },
        function(data) {
            if(data != "err") {
                console.log("hi");
                console.log(data);

                // change state
                setStateTo(cveid, newState);

                // add comment
                var comment = JSON.parse(data);
                var commentDate = '<small class="text-muted">' + comment.Date.split("T")[0] + ' ' + comment.Date.split("T")[1].split(".")[0] + ' UTC</small>';
                var newComment = '<div class="col-3 text-right mb-3"><b>' + comment.User + '</b><br/>' + commentDate + '</div><div class="col-9 mb-3"><div class="card" style="background: none;"><div class="card-body">' + escape(comment.Message) + '</div></div></div>';
                $('.comments-section[data-cveid="' + cveid + '"]').append(newComment);

            }
        });
}


function setStateToAssigned(cveid) {
    setStateTo(cveid, "Assigned");
}

function setStateTo(cveid, newState) {
    $('.state[data-cveid="' + cveid + '"]').removeClass('badge-primary');
    $('.state[data-cveid="' + cveid + '"]').removeClass('badge-secondary');
    $('.state[data-cveid="' + cveid + '"]').removeClass('badge-success');
    $('.state[data-cveid="' + cveid + '"]').removeClass('badge-danger');
    $('.state[data-cveid="' + cveid + '"]').removeClass('badge-warning');
    $('.state[data-cveid="' + cveid + '"]').removeClass('badge-info');
    $('.state[data-cveid="' + cveid + '"]').removeClass('badge-light');
    $('.state[data-cveid="' + cveid + '"]').removeClass('badge-dark');

    if(newState == "New"){
        $('.state[data-cveid="' + cveid + '"]').addClass('badge-danger');
    } else if(newState == "Assigned"){
        $('.state[data-cveid="' + cveid + '"]').addClass('badge-success');
    } else if(newState == "NFU"){
        $('.state[data-cveid="' + cveid + '"]').addClass('badge-info');
    } else if(newState == "Later"){
        $('.state[data-cveid="' + cveid + '"]').addClass('badge-warning');
    } else if(newState == "Invalid"){
        $('.state[data-cveid="' + cveid + '"]').addClass('badge-dark');
    } else {
        $('.state[data-cveid="' + cveid + '"]').addClass('badge-primary');
    }

    $('.state[data-cveid="' + cveid + '"]').html(newState);
}


function updateBugInformation(cveid, bugid){
    $.getJSON( BUGZILLA_URL +  "/rest/bug?id=" + bugid, function( data ) {
        console.log(data.bugs[0]);

        console.log(escape(data.bugs[0].alias.join(", ")));
        console.log(escape(data.bugs[0].status));
        console.log(escape(data.bugs[0].resolution));
        console.log(escape(data.bugs[0].whiteboard));
        console.log(escape(data.bugs[0]['creation_time']));
        console.log(escape(data.bugs[0]['last_change_time']));

        $('.bug-title[data-cveid="' + cveid + '"][data-bugid="' + bugid + '"]').html(escape(data.bugs[0].summary));

        $('.bug-alias[data-cveid="' + cveid + '"][data-bugid="' + bugid + '"]').html('<i>' + escape(data.bugs[0].alias.join(", ")) + '</i>');
        $('.bug-status[data-cveid="' + cveid + '"][data-bugid="' + bugid + '"]').html('<i>' + escape(data.bugs[0].status) + '</i>');
        $('.bug-resolution[data-cveid="' + cveid + '"][data-bugid="' + bugid + '"]').html('<i>' + escape(data.bugs[0].resolution) + '</i>');
        $('.bug-whiteboard[data-cveid="' + cveid + '"][data-bugid="' + bugid + '"]').html('<i>' + escape(data.bugs[0].whiteboard) + '</i>');
        $('.bug-created[data-cveid="' + cveid + '"][data-bugid="' + bugid + '"]').html('<i>' + escape(data.bugs[0]['creation_time']) + '</i>');
        $('.bug-last-update[data-cveid="' + cveid + '"][data-bugid="' + bugid + '"]').html('<i>' + escape(data.bugs[0]['last_change_time']) + '</i>');

    });
}

export default {initDatatable, destroyDatatable}
