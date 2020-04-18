
$( "#save-new-glsa-comment" ).click(function() {
    var glsaid = $("#glsa-id").html();
    var comment = $('#comment').val();
    $('#comment').val(" ");
    $('#comment').focusout();

    commentGLSA(glsaid, comment, "comment");

});

$( "#save-new-glsa-approve" ).click(function() {
    var glsaid = $("#glsa-id").html();
    var comment = $('#comment').val();
    $('#comment').val(" ");
    $('#comment').focusout();

    commentGLSA(glsaid, comment, "approve");

});

$( "#save-new-glsa-decline" ).click(function() {
    var glsaid = $("#glsa-id").html();
    var comment = $('#comment').val();
    $('#comment').val(" ");
    $('#comment').focusout();

    commentGLSA(glsaid, comment, "decline");

});

function commentGLSA(glsaid, comment, commentType){

    $.post(
        '/glsa/comment/add',
        {
            glsaid: glsaid,
            comment: comment,
            commentType: commentType,
        },
        function(data) {

            if(data != "err") {



                console.log("hi");
                console.log(data);
                var comment = JSON.parse(data);
                var commentDate = comment.Date.split("T")[0] + ' ' + comment.Date.split("T")[1].split(".")[0] + ' UTC';
                var background = "";
                var hint = "";
                if(comment.Type == "approve"){
                    background = "background:#DFF0D8;";
                    hint = '<b class="mr-2">Approved: </b>';
                } else if(comment.Type == "decline"){
                    background = "background:#F2DEDE;";
                    hint = '<b class="mr-2">Declined: </b>';
                }

                var newComment = '<div class="col-12 mt-3">' +
                    '<div id="c0" class="card" style="padding:0px;' + background +'">' +
                    '<div class="card-header" style="' + background + '">' +
                    '<div class="row">' +
                    '<div class="col-sm-8">' +
                    '<div class="row">' +
                    '<div class="col-sm-12">' +
                    '<span style="color:#000!important;">' +
                    '<span class="vcard"><a class="email" href="mailto:' + comment.User + '"> <b class="text-dark">' + comment.User + '</b></a></span>' +
                    '</span>' +
                    '<span class="ml-2">' +
                    '<span class="badge badge-secondary" title="' + comment.UserBadge.Description + '" style="background: none;border: 1px solid ' + comment.UserBadge.Color + ';">' +
                    '<span class="text-capitalize" style="color: ' + comment.UserBadge.Color + ';">' + comment.UserBadge.Name + '</span>' +
                    '</span>' +
                    '</span>' +
                    '</div>' +
                    '<div class="col-sm-12">' +
                    '<span style="color:#505050; font-weight: normal;margin-left:2px;">' +
                    commentDate +
                    '</span>' +
                    '</div>' +
                    '</div>' +
                    '</div>' +
                    '<div class="col-sm-4">' +
                    '<div>' +
                    '<a href="#" class="btn btn-default btn-xs float-right" style="background:transparent;color:#505050;border:none;"><i class="fa fa-compress" aria-hidden="true"></i></a>' +
                    '<a class="btn btn-default btn-xs float-right" href="#add_comment" style="background:transparent;color:#505050;border:none;"><i class="fa fa-reply" aria-hidden="true"></i></a>' +
                    '<a href="#" class="btn btn-default btn-xs float-right" style="background:transparent;color:#505050;border:none;"><i class="fa fa-tag" aria-hidden="true"></i></a>' +
                    '</div>' +
                    '</div>' +
                    '</div>' +
                    '</div>' +
                    '<div class="card-body">' +
                    hint +
                    comment.Message +
                    '</div>' +
                    '</div>' +
                    '</div>';

                $('#comments-section').append(newComment);

            }
            return
        });
}


$('#btn-delete-glsa').on('click', function(event){
    var glsaid = $("#glsa-id").html();
    $.get( "/glsa/delete/" + glsaid, function( data ) {
       document.location.href = "/";
    });
});

