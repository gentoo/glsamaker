
// Base64 to ArrayBuffer
function bufferDecode(value) {
    return Uint8Array.from(atob(value), c => c.charCodeAt(0));
}

// ArrayBuffer to URLBase64
function bufferEncode(value) {
    return btoa(String.fromCharCode.apply(null, new Uint8Array(value)))
        .replace(/\+/g, "-")
        .replace(/\//g, "_")
        .replace(/=/g, "");;
}

function registerUser() {

    authname = $("#webauthn-name").val();
    authname = authname.substring(0, 20);
    authname = escape(authname);

    $.get(
        '/account/2fa/webauthn/register/begin',
        null,
        function (data) {
            return data
        },
        'json')
        .then((credentialCreationOptions) => {
            console.log(credentialCreationOptions)
            credentialCreationOptions.publicKey.challenge = bufferDecode(credentialCreationOptions.publicKey.challenge);
            credentialCreationOptions.publicKey.user.id = bufferDecode(credentialCreationOptions.publicKey.user.id);
            if (credentialCreationOptions.publicKey.excludeCredentials) {
                for (var i = 0; i < credentialCreationOptions.publicKey.excludeCredentials.length; i++) {
                    credentialCreationOptions.publicKey.excludeCredentials[i].id = bufferDecode(credentialCreationOptions.publicKey.excludeCredentials[i].id);
                }
            }

            return navigator.credentials.create({
                publicKey: credentialCreationOptions.publicKey
            })
        })
        .then((credential) => {
            console.log(credential)
            let attestationObject = credential.response.attestationObject;
            let clientDataJSON = credential.response.clientDataJSON;
            let rawId = credential.rawId;

            $.post(
                '/account/2fa/webauthn/register/finish?name=' + authname,
                JSON.stringify({
                    id: credential.id,
                    rawId: bufferEncode(rawId),
                    type: credential.type,
                    response: {
                        attestationObject: bufferEncode(attestationObject),
                        clientDataJSON: bufferEncode(clientDataJSON),
                    },
                }),
                function (data) {
                    return data
                },
                'json')
        })
        .then((success) => {
            // successfully registered
            return
        })
        .catch((error) => {
            // failed to register
            console.log(error)
        })
}


$( "#register-webauthn" ).click(function() {
    if($("#webauthn-name").val().length == 0){
        alert("Please provide a non-empty Authenticator Name");
    }else{
        registerUser();
    }
});
