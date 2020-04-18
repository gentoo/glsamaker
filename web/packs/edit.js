function registerDeleteReferenceButtons(){
    $('.btn-delete-reference').on('click', function(event){
        $(this).parent().parent().parent().remove();
    });
}

function registerDeleteBugButtons(){
    $('.btn-delete-bug').on('click', function(event){
        $(this).parent().parent().parent().remove();
    });
}

function registerDeletePackageButtons(){
    $('.btn-delete-package').on('click', function(event){
        $(this).parent().parent().parent().parent().remove();
    });
}

registerDeleteBugButtons();
registerDeleteReferenceButtons();
registerDeletePackageButtons();

$('.btn-add-bug').on('click', function(event){

    var newBugId = $("#new_bug_id").val();

    if(newBugId == "") {
        return;
    }

    var newBug = '<div class="col-sm-12 mt-2">' +
        '<div class="row" style="margin-bottom:2px;">' +
        '<div class="col-md-auto align-h-right" style="padding-right:0px;color:#505050;">' +
        '<small style="font-size: 12px;">' +
        '<small style="font-size: 12px;">' +
        '<input name="bugs" class="form-control" type="text" value="' + newBugId + '" style="max-width: 75px;height: 30px;padding: .25rem .5rem;display: inline-block" />' +
        '</small>' +
        '</small>' +
        '</div>' +
        '<div class="col py-1" style="color:#292929;padding-left:10px;">' +
        '<small style="font-size: 12px;">TODO...</small>' +
        '</div>' +
        '<small style="font-size: 12px;margin-top: 2px;">' +
        '<button type="button" class="btn btn-outline-danger mr-3 py-0 btn-delete-bug" type="text" style="height: 25px;display: inline-block">Delete</button>' +
        '</small>' +
        '</div>' +
        '</div>';

    $("#bugs-list").append(newBug);

    registerDeleteBugButtons();
});


$('.btn-add-reference').on('click', function(event){

    var newReferenceTitle = $("#new_reference_title").val();
    var newReferenceURL = $("#new_reference_url").val();

    if(newReferenceTitle == "" || newReferenceURL == "") {
        return;
    }

    var newReference = '<div class="col-sm-12 mt-2">' +
    '<div class="row" style="margin-bottom:2px;">' +
    '<div class="col-md-auto align-h-right" style="padding-right:0px;color:#505050;">' +
    '<small style="font-size: 12px;">' +
    '<small style="font-size: 12px;">' +
    '<input name="reference_title" class="form-control" type="text" value="' + newReferenceTitle + '" style="max-width: 125px;height: 30px;padding: .25rem .5rem;display: inline-block" />' +
    '</small>' +
    '</small>' +
    '</div>' +
    '<div class="col" style="color:#292929;padding-left:10px;">' +
    '<small style="font-size: 12px;">' +
    '<input name="reference_url" class="form-control" type="text" value="' + newReferenceURL + '" style="height: 30px;padding: .25rem .5rem;display: inline-block" />' +
    '</small>' +
    '</div>' +
    '<small style="font-size: 12px;margin-top: 2px;">' +
    '<button type="button" class="btn btn-outline-danger btn-delete-reference mr-3 py-0" type="text" style="height: 25px;display: inline-block">Delete</button>' +
    '</small>' +
    '</div>' +
    '</div>';

    $("#reference_list").append(newReference);

    registerDeleteReferenceButtons();
});


$('.btn-add-vulnerable-package').on('click', function(event){

    var addVulnerablePackageId = $("#add-vulnerable-package-atom").val();
    var addVulnerablePackageIdentifier = $("#add-vulnerable-package-identifier").val();
    var addVulnerablePackageVersion = $("#add-vulnerable-package-version").val();
    var addVulnerablePackageSlot = $("#add-vulnerable-package-slot").val();
    var addVulnerablePackageArch = $("#add-vulnerable-package-arch").val();
    var addVulnerablePackageAuto = $("#add-vulnerable-package-auto").val();

    if(addVulnerablePackageId == "" || addVulnerablePackageIdentifier == "" || addVulnerablePackageVersion == "" || addVulnerablePackageSlot == "" || addVulnerablePackageArch == "" || addVulnerablePackageAuto == "") {
        return;
    }

    var newPackage = '<div class="col-12 mt-2">' +
        '<div class="row">' +
        '<div class="col-md-auto" style="color:#292929;">' +
        '<small style="font-size: 12px;">' +
        '<input name="package_vulnerable" value="true" hidden />' +
        '<input name="package_atom" class="form-control" type="text" value="' + addVulnerablePackageId + '" style="width:150px; height: 30px;padding: .25rem .5rem;display: inline-block" />' +
        '</small>' +
        '</div>' +
        '<div class="col-md-auto pl-0" style="color:#292929;">' +
        '<small style="font-size: 12px;">' +
        '<select name="package_identifier" class="custom-select" style="display: inline-block;max-width: 100px;height: 30px;padding: .25rem .5rem;">' +
        '<option value=">=" ' + (addVulnerablePackageIdentifier == ">=" ? 'selected' : '') + '>&gt;=</option>' +
        '<option value=">" ' + (addVulnerablePackageIdentifier == ">" ? 'selected' : '') + '>&gt; </option>' +
        '<option value="*>=" ' + (addVulnerablePackageIdentifier == "*>=" ? 'selected' : '') + '>*&gt;=&nbsp;&nbsp;&nbsp; </option>' +
        '<option value="*>" ' + (addVulnerablePackageIdentifier == "*>" ? 'selected' : '') + '>*&gt; </option>' +
        '<option value="<=" ' + (addVulnerablePackageIdentifier == "<=" ? 'selected' : '') + '>&lt;= </option>' +
        '<option value="<" ' + (addVulnerablePackageIdentifier == "<" ? 'selected' : '') + '>&lt; </option>' +
        '<option value="*<=" ' + (addVulnerablePackageIdentifier == "*<=" ? 'selected' : '') + '>*&lt;= </option>' +
        '<option value="*<" ' + (addVulnerablePackageIdentifier == "*<" ? 'selected' : '') + '>*&lt; </option>' +
        '<option value="=" ' + (addVulnerablePackageIdentifier == "=" ? 'selected' : '') + '>= </option>' +
        '</select>' +
        '</small>' +
        '</div>' +
        '<div class="col-md-auto pl-0" style="color:#292929;">' +
        '<small style="font-size: 12px;">' +
        '<input name="package_version" class="form-control" type="text" value="' + addVulnerablePackageVersion + '" style="width: 80px; height: 30px;padding: .25rem .5rem;display: inline-block" />' +
        '</small>' +
        '</div>' +
        '<div class="col-md-auto pl-0" style="color:#292929;">' +
        '<small style="font-size: 12px;">' +
        '<input name="package_slot" class="form-control" type="text" value="' + addVulnerablePackageSlot + '" style="width: 30px; height: 30px;padding: .25rem .5rem;display: inline-block" />' +
        '</small>' +
        '</div>' +
        '<div class="col-md-auto pl-0" style="color:#292929;">' +
        '<small style="font-size: 12px;">' +
        '<input name="package_arch" class="form-control" type="text" value="' + addVulnerablePackageArch + '" style="width: 30px; height: 30px;padding: .25rem .5rem;display: inline-block" />' +
        '</small>' +
        '</div>' +
        '<div class="col-md-auto pl-0" style="color:#292929;">' +
        '<small style="font-size: 12px;">' +
        '<select name="package_auto" class="custom-select" id="inputGroupSelect01" style="display: inline-block;max-width: 100px;height: 30px;padding: .25rem .5rem;">' +
        '<option value="yes" ' + (addVulnerablePackageAuto == "true" ? 'selected' : '') + '>yes&nbsp;&nbsp;&nbsp; </option>' +
        '<option value="no" ' + (addVulnerablePackageAuto == "false" ? 'selected' : '') + '>no</option>' +
        '</select>' +
        '</small>' +
        '</div>' +
        '<div class="col-md-auto pl-0" style="color:#292929;">' +
        '<small style="font-size: 12px;">' +
        '<button type="button" class="btn btn-outline-danger btn-delete-package" type="text" placeholder="*" style="width: 30px; height: 30px;padding: .25rem .5rem;display: inline-block">-</button>' +
        '</small>' +
        '</div>' +
        '</div>' +
        '</div>';

    $("#vulnerable_package_list").append(newPackage);

    registerDeletePackageButtons();
});



$('.btn-add-unaffected-package').on('click', function(event){

    var addVulnerablePackageId = $("#add-unaffected-package-atom").val();
    var addVulnerablePackageIdentifier = $("#add-unaffected-package-identifier").val();
    var addVulnerablePackageVersion = $("#add-unaffected-package-version").val();
    var addVulnerablePackageSlot = $("#add-unaffected-package-slot").val();
    var addVulnerablePackageArch = $("#add-unaffected-package-arch").val();
    var addVulnerablePackageAuto = $("#add-unaffected-package-auto").val();

    if(addVulnerablePackageId == "" || addVulnerablePackageIdentifier == "" || addVulnerablePackageVersion == "" || addVulnerablePackageSlot == "" || addVulnerablePackageArch == "" || addVulnerablePackageAuto == "") {
        return;
    }

    var newPackage = '<div class="col-12 mt-2">' +
        '<div class="row">' +
        '<div class="col-md-auto" style="color:#292929;">' +
        '<small style="font-size: 12px;">' +
        '<input name="package_vulnerable" value="false" hidden />' +
        '<input name="package_atom" class="form-control" type="text" value="' + addVulnerablePackageId + '" style="width:150px; height: 30px;padding: .25rem .5rem;display: inline-block" />' +
        '</small>' +
        '</div>' +
        '<div class="col-md-auto pl-0" style="color:#292929;">' +
        '<small style="font-size: 12px;">' +
        '<select name="package_identifier" class="custom-select" style="display: inline-block;max-width: 100px;height: 30px;padding: .25rem .5rem;">' +
        '<option value=">=" ' + (addVulnerablePackageIdentifier == ">=" ? 'selected' : '') + '>&gt;=</option>' +
        '<option value=">" ' + (addVulnerablePackageIdentifier == ">" ? 'selected' : '') + '>&gt; </option>' +
        '<option value="*>=" ' + (addVulnerablePackageIdentifier == "*>=" ? 'selected' : '') + '>*&gt;=&nbsp;&nbsp;&nbsp; </option>' +
        '<option value="*>" ' + (addVulnerablePackageIdentifier == "*>" ? 'selected' : '') + '>*&gt; </option>' +
        '<option value="<=" ' + (addVulnerablePackageIdentifier == "<=" ? 'selected' : '') + '>&lt;= </option>' +
        '<option value="<" ' + (addVulnerablePackageIdentifier == "<" ? 'selected' : '') + '>&lt; </option>' +
        '<option value="*<=" ' + (addVulnerablePackageIdentifier == "*<=" ? 'selected' : '') + '>*&lt;= </option>' +
        '<option value="*<" ' + (addVulnerablePackageIdentifier == "*<" ? 'selected' : '') + '>*&lt; </option>' +
        '<option value="=" ' + (addVulnerablePackageIdentifier == "=" ? 'selected' : '') + '>= </option>' +
        '</select>' +
        '</small>' +
        '</div>' +
        '<div class="col-md-auto pl-0" style="color:#292929;">' +
        '<small style="font-size: 12px;">' +
        '<input name="package_version" class="form-control" type="text" value="' + addVulnerablePackageVersion + '" style="width: 80px; height: 30px;padding: .25rem .5rem;display: inline-block" />' +
        '</small>' +
        '</div>' +
        '<div class="col-md-auto pl-0" style="color:#292929;">' +
        '<small style="font-size: 12px;">' +
        '<input name="package_slot" class="form-control" type="text" value="' + addVulnerablePackageSlot + '" style="width: 30px; height: 30px;padding: .25rem .5rem;display: inline-block" />' +
        '</small>' +
        '</div>' +
        '<div class="col-md-auto pl-0" style="color:#292929;">' +
        '<small style="font-size: 12px;">' +
        '<input name="package_arch" class="form-control" type="text" value="' + addVulnerablePackageArch + '" style="width: 30px; height: 30px;padding: .25rem .5rem;display: inline-block" />' +
        '</small>' +
        '</div>' +
        '<div class="col-md-auto pl-0" style="color:#292929;">' +
        '<small style="font-size: 12px;">' +
        '<select name="package_auto" class="custom-select" id="inputGroupSelect01" style="display: inline-block;max-width: 100px;height: 30px;padding: .25rem .5rem;">' +
        '<option value="yes" ' + (addVulnerablePackageAuto == "true" ? 'selected' : '') + '>yes&nbsp;&nbsp;&nbsp; </option>' +
        '<option value="no" ' + (addVulnerablePackageAuto == "false" ? 'selected' : '') + '>no</option>' +
        '</select>' +
        '</small>' +
        '</div>' +
        '<div class="col-md-auto pl-0" style="color:#292929;">' +
        '<small style="font-size: 12px;">' +
        '<button type="button" class="btn btn-outline-danger btn-delete-package" type="text" placeholder="*" style="width: 30px; height: 30px;padding: .25rem .5rem;display: inline-block">-</button>' +
        '</small>' +
        '</div>' +
        '</div>' +
        '</div>';

    $("#unaffected_package_list").append(newPackage);

    registerDeletePackageButtons();
});

