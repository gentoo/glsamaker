package webauthn

import (
	"glsamaker/pkg/app/handler/authentication/auth_session"
	"glsamaker/pkg/app/handler/authentication/utils"
	"encoding/json"
	"fmt"
	"github.com/duo-labs/webauthn.io/session"
	webauthn_lib "github.com/duo-labs/webauthn/webauthn"
	"glsamaker/pkg/config"
	"log"
	"net/http"
)

var (
	WebAuthn     *webauthn_lib.WebAuthn
	SessionStore *session.Store
)


func BeginLogin(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	CreateWebAuthn()
	CreateSessionStore()

	// user doesn't exist
	if user == nil {
		log.Println("Error fetching the user.")
		JsonResponse(w, "Error fetching the user.", http.StatusBadRequest)
		return
	}

	// generate PublicKeyCredentialRequestOptions, session data
	options, sessionData, err := WebAuthn.BeginLogin(user)
	if err != nil {
		log.Println(err)
		JsonResponse(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// store session data as marshaled JSON
	err = SessionStore.SaveWebauthnSession("authentication", sessionData, r, w)
	if err != nil {
		log.Println(err)
		JsonResponse(w, err.Error(), http.StatusInternalServerError)
		return
	}

	JsonResponse(w, options, http.StatusOK)
}

func FinishLogin(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	// user doesn't exist
	if user == nil {
		log.Println("Error fetching the user.")
		JsonResponse(w, "Error fetching the user.", http.StatusBadRequest)
		return
	}

	// load the session data
	sessionData, err := SessionStore.GetWebauthnSession("authentication", r)
	if err != nil {
		log.Println(err)
		JsonResponse(w, err.Error(), http.StatusBadRequest)
		return
	}

	// in an actual implementation, we should perform additional checks on
	// the returned 'credential', i.e. check 'credential.Authenticator.CloneWarning'
	// and then increment the credentials counter
	_, err = WebAuthn.FinishLogin(user, sessionData, r)
	if err != nil {
		log.Println(err)
		JsonResponse(w, err.Error(), http.StatusBadRequest)
		return
	}

	// handle successful login
	// TODO handle bindLoginToIP correctly
	auth_session.Create(w, r, user, true, false)
	JsonResponse(w, "Login Success", http.StatusOK)
}

// from: https://github.com/duo-labs/webauthn.io/blob/3f03b482d21476f6b9fb82b2bf1458ff61a61d41/server/response.go#L15
func JsonResponse(w http.ResponseWriter, d interface{}, c int) {
	dj, err := json.Marshal(d)
	if err != nil {
		http.Error(w, "Error creating JSON response", http.StatusInternalServerError)
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(c)
	fmt.Fprintf(w, "%s", dj)
}

func CreateWebAuthn() {

	if WebAuthn == nil {
		authn, _ := webauthn_lib.New(&webauthn_lib.Config{
			RPDisplayName: "Gentoo GLSAMaker",                               // Display Name for your site
			RPID:          config.Domain(),                                  // Generally the domain name for your site
			RPOrigin:      "https://" + config.Domain(),                     // The origin URL for WebAuthn requests
			RPIcon:        "https://assets.gentoo.org/tyrian/site-logo.png", // Optional icon URL for your site
		})

		WebAuthn = authn
	}

}

func CreateSessionStore() {
	if SessionStore == nil {
		SessionStore, _ = session.NewStore()
	}
}
