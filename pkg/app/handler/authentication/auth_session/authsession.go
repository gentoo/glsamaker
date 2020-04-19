package auth_session

import (
	"glsamaker/pkg/config"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/logger"
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/users"
	"github.com/google/uuid"
	"net/http"
	"strings"
	"time"
)

func Create(w http.ResponseWriter, r *http.Request, user *users.User, bindSessionToIP bool, secondFactorMissing bool) {
	sessionID := createSessionID()
	sessionIP := "*"
	expires := time.Now().AddDate(0, 1, 0)

	if bindSessionToIP {
		sessionIP = getIP(r)
	}

	if secondFactorMissing {
		expires = time.Now().Add(10 * time.Minute)
	}

	session := &models.Session{
		Id:                  sessionID,
		UserId:              user.Id,
		IP:                  sessionIP,
		SecondFactorMissing: secondFactorMissing,
		Expires:             expires,
	}

	_, err := connection.DB.Model(session).OnConflict("(id) DO UPDATE").Insert()
	if err != nil {
		logger.Error.Println("Err during creating session")
		logger.Error.Println(err)
	}

	createSessionCookie(w, sessionID)
}

func createSessionID() string {
	id, _ := uuid.NewUUID()
	return id.String()
}

func createSessionCookie(w http.ResponseWriter, sessionID string) {

	expires := time.Now().AddDate(0, 1, 0)

	ck := http.Cookie{
		Name:    "session",
		Domain:  config.Domain(),
		Path:    "/",
		Expires: expires,
	}

	ck.Value = sessionID

	http.SetCookie(w, &ck)

}

func GetUserId(sessionId, userIP string) int64 {
	session := &models.Session{Id: sessionId}
	err := connection.DB.Model(session).Relation("User").WherePK().Select()

	if err != nil || session.User.Disabled {
		return -1
	}

	if session != nil &&
		session.Expires.After(time.Now()) &&
		isValidIP(session.IP, userIP) {
		return session.UserId
	} else {
		return -1
	}
}

func Only2FAMissing(sessionId, userIP string) bool {
	session := &models.Session{Id: sessionId}
	err := connection.DB.Model(session).Relation("User").WherePK().Select()

	if err != nil {
		return false
	}

	invalidateExpiredSession(session)

	return session != nil &&
		session.Expires.After(time.Now()) &&
		!session.User.Disabled &&
		session.SecondFactorMissing &&
		isValidIP(session.IP, userIP)
}

func IsLoggedIn(sessionId, userIP string) bool {

	session := &models.Session{Id: sessionId}
	err := connection.DB.Model(session).Relation("User").WherePK().Select()

	if err != nil {
		return false
	}

	invalidateExpiredSession(session)

	return session != nil &&
		!session.SecondFactorMissing &&
		!session.User.Disabled &&
		session.Expires.After(time.Now()) &&
		isValidIP(session.IP, userIP)
}

func IsLoggedInAndNeedsNewPassword(sessionId, userIP string) bool {

	session := &models.Session{Id: sessionId}
	err := connection.DB.Model(session).Relation("User").WherePK().Select()

	if err != nil {
		return false
	}

	invalidateExpiredSession(session)

	return session != nil &&
		!session.SecondFactorMissing &&
		!session.User.Disabled &&
		session.User.ForcePasswordRotation &&
		session.Expires.After(time.Now()) &&
		isValidIP(session.IP, userIP)
}

func IsLoggedInAndNeeds2FA(sessionId, userIP string) bool {

	session := &models.Session{Id: sessionId}
	err := connection.DB.Model(session).Relation("User").WherePK().Select()

	if err != nil {
		return false
	}

	invalidateExpiredSession(session)

	return session != nil &&
		!session.SecondFactorMissing &&
		!session.User.Disabled &&
		session.User.Force2FA &&
		!session.User.IsUsing2FA() &&
		session.Expires.After(time.Now()) &&
		isValidIP(session.IP, userIP)
}

func invalidateExpiredSession(session *models.Session) {
	if session.Expires.Before(time.Now()) {
		_, err := connection.DB.Model(session).WherePK().Delete()
		if err != nil {
			logger.Error.Println("Error deleting expired session.")
			logger.Error.Println(err)
		}
	}
}

func isValidIP(sessionIP, userIP string) bool {
	return sessionIP == "*" || userIP == sessionIP
}

func getIP(r *http.Request) string {
	forwarded := r.Header.Get("X-FORWARDED-FOR")
	if forwarded != "" {
		return strings.Split(forwarded, ":")[0]
	}
	return strings.Split(r.RemoteAddr, ":")[0]
}
