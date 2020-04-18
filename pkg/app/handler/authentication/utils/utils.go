package utils

import (
	"glsamaker/pkg/app/handler/authentication/auth_session"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/models/users"
	"net/http"
	"strings"
)

// utility methods to check whether a user is authenticated

func Only2FAMissing(w http.ResponseWriter, r *http.Request) bool {
	sessionID, err := r.Cookie("session")
	userIP := getIP(r)

	return err == nil && sessionID != nil && auth_session.Only2FAMissing(sessionID.Value, userIP)
}

func IsAuthenticated(w http.ResponseWriter, r *http.Request) bool {
	sessionID, err := r.Cookie("session")
	userIP := getIP(r)

	return err == nil && sessionID != nil && auth_session.IsLoggedIn(sessionID.Value, userIP)
}

func IsAuthenticatedAndNeedsNewPassword(w http.ResponseWriter, r *http.Request) bool {
	sessionID, err := r.Cookie("session")
	userIP := getIP(r)

	return err == nil && sessionID != nil && auth_session.IsLoggedInAndNeedsNewPassword(sessionID.Value, userIP)
}

func IsAuthenticatedAndNeeds2FA(w http.ResponseWriter, r *http.Request) bool {
	sessionID, err := r.Cookie("session")
	userIP := getIP(r)

	return err == nil && sessionID != nil && auth_session.IsLoggedInAndNeeds2FA(sessionID.Value, userIP)
}

func IsAuthenticatedAsAdmin(w http.ResponseWriter, r *http.Request) bool {
	sessionID, err := r.Cookie("session")
	userIP := getIP(r)

	if err != nil || sessionID == nil || !auth_session.IsLoggedIn(sessionID.Value, userIP) {
		return false
	}

	user := GetAuthenticatedUser(r)

	return user != nil && user.Permissions.Admin.View

}

func GetAuthenticatedUser(r *http.Request) *users.User {
	sessionID, err := r.Cookie("session")
	userIP := getIP(r)

	if err != nil || sessionID == nil || !(auth_session.IsLoggedIn(sessionID.Value, userIP) || auth_session.Only2FAMissing(sessionID.Value, userIP)) {
		return nil
	}

	userId := auth_session.GetUserId(sessionID.Value, userIP)

	user := &users.User{Id: userId}
	err = connection.DB.Select(user)

	if err != nil {
		return nil
	}

	return user
}

func getIP(r *http.Request) string {
	forwarded := r.Header.Get("X-FORWARDED-FOR")
	if forwarded != "" {
		return strings.Split(forwarded, ":")[0]
	}
	return strings.Split(r.RemoteAddr, ":")[0]
}
