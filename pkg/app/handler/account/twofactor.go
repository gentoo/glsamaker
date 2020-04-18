package account

import (
	"glsamaker/pkg/app/handler/authentication/totp"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/logger"
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/users"
	"bytes"
	"github.com/duo-labs/webauthn/webauthn"
	"html/template"
	"net/http"
)

// landing page

func TwoFactorAuth(w http.ResponseWriter, r *http.Request) {
	user := utils.GetAuthenticatedUser(r)
	render2FATemplate(w, r, user)
}

// webauthn

func ActivateWebAuthn(w http.ResponseWriter, r *http.Request) {
	user := utils.GetAuthenticatedUser(r)

	if user.WebauthnCredentials != nil && len(user.WebauthnCredentials) >= 0 {
		updatedUser := &users.User{
			Id:              user.Id,
			IsUsingTOTP:     false,
			IsUsingWebAuthn: true,
			Show2FANotice:   false,
		}

		_, err := connection.DB.Model(updatedUser).Column("is_using_totp").WherePK().Update()
		_, err = connection.DB.Model(updatedUser).Column("is_using_web_authn").WherePK().Update()
		_, err = connection.DB.Model(updatedUser).Column("show2fa_notice").WherePK().Update()

		if err != nil {
			logger.Error.Println("Error activating webauthn")
			logger.Error.Println(err)
		}

	}

	http.Redirect(w, r, "/account/2fa", 301)
}

func DisableWebAuthn(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	updatedUser := &users.User{
		Id:              user.Id,
		IsUsingWebAuthn: false,
	}

	_, err := connection.DB.Model(updatedUser).Column("is_using_web_authn").WherePK().Update()

	if err != nil {
		logger.Error.Println("Error disabling webauthn")
		logger.Error.Println(err)
	}

	http.Redirect(w, r, "/account/2fa", 301)
}

// totp

func ActivateTOTP(w http.ResponseWriter, r *http.Request) {
	user := utils.GetAuthenticatedUser(r)

	updatedUser := &users.User{
		Id:              user.Id,
		IsUsingTOTP:     true,
		IsUsingWebAuthn: false,
		Show2FANotice:   false,
	}

	_, err := connection.DB.Model(updatedUser).Column("is_using_totp").WherePK().Update()
	_, err = connection.DB.Model(updatedUser).Column("is_using_web_authn").WherePK().Update()
	_, err = connection.DB.Model(updatedUser).Column("show2fa_notice").WherePK().Update()

	if err != nil {
		logger.Error.Println("Error activating totp")
		logger.Error.Println(err)
	}

	http.Redirect(w, r, "/account/2fa", 301)
}

func DisableTOTP(w http.ResponseWriter, r *http.Request) {
	user := utils.GetAuthenticatedUser(r)

	updatedUser := &users.User{
		Id:          user.Id,
		IsUsingTOTP: false,
	}

	_, err := connection.DB.Model(updatedUser).Column("is_using_totp").WherePK().Update()

	if err != nil {
		logger.Error.Println("Error updating 2fa")
		logger.Error.Println(err)
	}

	http.Redirect(w, r, "/account/2fa", 301)
}

func VerifyTOTP(w http.ResponseWriter, r *http.Request) {
	user := utils.GetAuthenticatedUser(r)
	token := getToken(r)

	validToken := "false"

	if totp.IsValidTOTPToken(user, token) {
		validToken = "true"
	}

	w.Write([]byte(validToken))
}

func Disable2FANotice(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	updatedUser := &users.User{
		Id:            user.Id,
		Show2FANotice: false,
	}

	_, err := connection.DB.Model(updatedUser).Column("show2fa_notice").WherePK().Update()

	if err != nil {
		logger.Error.Println("Error disabling 2fa notice")
		logger.Error.Println(err)
	}

	w.Write([]byte("ok"))
}

// utility functions

func getToken(r *http.Request) string {
	err := r.ParseForm()
	if err != nil {
		return ""
	}
	return r.Form.Get("token")
}

// renderIndexTemplate renders all templates used for the login page
func render2FATemplate(w http.ResponseWriter, r *http.Request, user *users.User) {

	funcMap := template.FuncMap{
		"WebAuthnID":     WebAuthnCredentialID,
		"CredentialName": GetCredentialName,
	}

	templates := template.Must(
		template.Must(
			template.New("Show").
				Funcs(funcMap).
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/account/*.tmpl"))

	templates.ExecuteTemplate(w, "2fa.tmpl", createPageData("account", user))
}

// createPageData creates the data used in the template of the landing page
func createPageData(page string, user *users.User) interface{} {
	return struct {
		Page        string
		Application *models.GlobalSettings
		QRcode      string
		User        *users.User
	}{
		Page:        page,
		Application: models.GetDefaultGlobalSettings(),
		QRcode:      user.TOTPQRCode,
		User:        user,
	}
}

// WebAuthnCredentials returns credentials owned by the user
func WebAuthnCredentialID(cred webauthn.Credential) []byte {
	return cred.ID[:5]
}

func GetCredentialName(user *users.User, cred webauthn.Credential) string {

	for _, WebauthnCredentialName := range user.WebauthnCredentialNames {
		if bytes.Compare(WebauthnCredentialName.Id, cred.ID) == 0 {
			return WebauthnCredentialName.Name
		}
	}

	return "Unnamed Authenticator"
}
