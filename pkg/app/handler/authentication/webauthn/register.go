package webauthn

import (
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/logger"
	"fmt"
	"github.com/duo-labs/webauthn/protocol"
	"log"
	"net/http"
)

func BeginRegistration(w http.ResponseWriter, r *http.Request) {
	user := utils.GetAuthenticatedUser(r)

	CreateWebAuthn()
	CreateSessionStore()

	if user == nil {
		JsonResponse(w, fmt.Errorf("must supply a valid username i.e. foo@bar.com"), http.StatusBadRequest)
		return
	}

	registerOptions := func(credCreationOpts *protocol.PublicKeyCredentialCreationOptions) {
		credCreationOpts.CredentialExcludeList = user.CredentialExcludeList()
	}

	// generate PublicKeyCredentialCreationOptions, session data
	//var options *protocol.CredentialCreation
	//var err error
	options, sessionData, err := WebAuthn.BeginRegistration(
		user,
		registerOptions,
	)

	if err != nil {
		log.Println("Error begin register")
		log.Println(err)
		JsonResponse(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// store session data as marshaled JSON
	err = SessionStore.SaveWebauthnSession("registration", sessionData, r, w)
	if err != nil {
		log.Println("Error store session")
		log.Println(err)
		JsonResponse(w, err.Error(), http.StatusInternalServerError)
		return
	}

	JsonResponse(w, options, http.StatusOK)
}

func FinishRegistration(w http.ResponseWriter, r *http.Request) {

	authname := getParams(r)
	user := utils.GetAuthenticatedUser(r)

	if user == nil {
		JsonResponse(w, "Cannot find User", http.StatusBadRequest)
		return
	}

	// load the session data
	sessionData, err := SessionStore.GetWebauthnSession("registration", r)
	if err != nil {
		log.Println("Error loading session")
		log.Println(err)
		JsonResponse(w, err.Error(), http.StatusBadRequest)
		return
	}

	credential, err := WebAuthn.FinishRegistration(user, sessionData, r)
	if err != nil {
		log.Println("Error finish session")
		log.Println(err)
		JsonResponse(w, err.Error(), http.StatusBadRequest)
		return
	}

	user.AddCredential(*credential, authname)

	_, err = connection.DB.Model(user).Column("webauthn_credentials").WherePK().Update()
	_, err = connection.DB.Model(user).Column("webauthn_credential_names").WherePK().Update()
	if err != nil {
		logger.Error.Println("Error adding WebAuthn credentials.")
		logger.Error.Println(err)
	}

	JsonResponse(w, "Registration Success", http.StatusOK)
}

func getParams(r *http.Request) string {

	keys, ok := r.URL.Query()["name"]

	if !ok || len(keys[0]) < 1 {
		logger.Info.Println("Url Param 'name' is missing")
		return "Unnamed Authenticator"
	}

	// we only want the single item.
	key := keys[0]

	if len(key) > 20 {
		key = key[0:20]
	}

	return key
}
