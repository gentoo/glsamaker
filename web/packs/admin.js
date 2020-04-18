
$( "#addUser" ).click(function() {

    if($("#newNick").val() == "" || $("#newName").val() == "" || $("#newEmail").val() == ""){
        if($("#newNick").val() == ""){
            $("#newNick").addClass("is-invalid");
        }
        if($("#newName").val() == ""){
            $("#newName").addClass("is-invalid");
        }
        if($("#newEmail").val() == ""){
            $("#newEmail").addClass("is-invalid");
        }
        return;
    }

    var newNick = $("#newNick").val();
    var newName = $("#newName").val();
    var newEmail = $("#newEmail").val();

    var newUser = '<tr>\n' +
        '                                <td>\n' +
        '                                    <span class="my-1 badge badge-secondary float-left mr-2" style="background: none;border: 1px solid grey;">\n' +
        '                                        <i class="fa fa-user mr-1" aria-hidden="true" style="font-size: 0.8rem;color: grey;"></i>\n' +
        '                                        <span class="text-uppercase" style="color:grey;">User</span>\n' +
        '                                    </span>\n' +
        '                                </td>\n' +
        '                                <td>\n' +
        '                                    <input name="userId" type="text" value="-1" hidden/>\n' +
        '                                    <input name="userNick" class="form-control form-control-sm" value="' + newNick + '" style="max-width: 150px;"/>\n' +
        '                                </td>\n' +
        '                                <td>\n' +
        '                                    <input name="userName" class="form-control form-control-sm" value="' + newName + '" style="max-width: 150px;"/>\n' +
        '                                </td>\n' +
        '                                <td>\n' +
        '                                    <input name="userEmail" class="form-control form-control-sm" value="' + newEmail + '" style="max-width: 150px;"/>\n' +
        '                                </td>\n' +
        '                                <td>\n' +
        '                                        <i class="my-2 fa fa-times" style="color: darkred;" aria-hidden="true"></i>\n' +
        '                                </td>\n' +
        '                                <td>\n' +
        '                                        <i class="my-2 fa fa-times" style="color: darkred;" aria-hidden="true"></i>\n' +
        '                                </td>\n' +
        '                                <td>\n' +
        '                                    <i class="my-2 ml-2 fa fa-check" style="color: green;" aria-hidden="true"></i>\n' +
        '                                </td>\n' +
        '                                <td>\n' +
        '                                    <input name="userForce2FA" class="m-2" type="checkbox" value="-1" />\n' +
        '                                </td>\n' +
        '                                <td>\n' +
        '                                    <input name="userActive" class="m-2" type="checkbox" value="-1" checked/>\n' +
        '                                </td>\n' +
        '                                <td>\n' +
        '                                    <button type="button" class="float-right my-1 py-0 btn btn-outline-secondary btn-sm">Actions</button>\n' +
        '                                </td>\n' +
        '                            </tr>'

    $("#userList").append(newUser);
    $("#addUserForm").hide();
});
