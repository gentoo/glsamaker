package authentication

import (
	"glsamaker/pkg/app/handler/authentication/auth_session"
	"glsamaker/pkg/app/handler/authentication/templates"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/models/users"
	"golang.org/x/crypto/argon2"
	"net/http"
)

func Login(w http.ResponseWriter, r *http.Request) {

	// in case '/login' is request but the user is
	// already authenticated we will redirect to '/'
	if utils.IsAuthenticated(w, r) {
		http.Redirect(w, r, "/", 301)
	}

	username, pass, cameFrom, bindLoginToIP, _ := getParams(r)

	if IsValidPassword(username, pass) {
		user, _ := getLoginUser(username)
		auth_session.Create(w, r, user, bindLoginToIP, user.IsUsing2FA())
		if user.IsUsing2FA() {
			http.Redirect(w, r, "/login/2fa", 301)
		} else {
			http.Redirect(w, r, cameFrom, 301)
		}
	} else {
		templates.RenderLoginTemplate(w, r)
	}

}

func SecondFactorLogin(w http.ResponseWriter, r *http.Request) {
	user := utils.GetAuthenticatedUser(r)

	if user == nil || !user.IsUsing2FA() {
		// this should not occur
		http.NotFound(w, r)
		return
	}

	if user.IsUsingTOTP {
		templates.RenderTOTPTemplate(w, r)
	} else if user.IsUsingWebAuthn {
		templates.RenderWebAuthnTemplate(w, r)
	} else {
		// this should not occur
		http.NotFound(w, r)
	}
}

// utility functions

func getLoginUser(username string) (*users.User, bool) {
	var potenialUsers []*users.User
	err := connection.DB.Model(&potenialUsers).Where("nick = ?", username).Select()
	isValidUser := err == nil

	if len(potenialUsers) < 1 {
		return &users.User{}, false
	}

	return potenialUsers[0], isValidUser
}

func getParams(r *http.Request) (string, string, string, bool, error) {
	err := r.ParseForm()
	if err != nil {
		return "", "", "", false, err
	}
	username := r.Form.Get("username")
	password := r.Form.Get("password")
	cameFrom := r.Form.Get("cameFrom")
	restrictLogin := r.Form.Get("restrictlogin")
	return username, password, cameFrom, restrictLogin == "on", err
}

func IsValidPassword(username string, password string) bool {
	user, isValidUser := getLoginUser(username)
	if !isValidUser {
		return false
	}

	hashedPassword := argon2.IDKey(
		[]byte(password),
		user.Password.Salt,
		user.Password.Time,
		user.Password.Memory,
		user.Password.Threads,
		user.Password.KeyLen)

	if user != nil && !user.Disabled && string(user.Password.Hash) == string(hashedPassword) {
		return true
	}
	return false
}
