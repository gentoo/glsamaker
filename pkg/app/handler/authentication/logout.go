package authentication

import (
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/logger"
	"glsamaker/pkg/models"
	"net/http"
)

func Logout(w http.ResponseWriter, r *http.Request) {

	sessionID, err := r.Cookie("session")

	if err != nil || sessionID == nil {
		// TODO Error
	}

	session := &models.Session{Id: sessionID.Value}
	_, err = connection.DB.Model(session).WherePK().Delete()

	if err != nil {
		logger.Info.Println("Error deleting session")
		logger.Error.Println("Error deleting session")
		logger.Error.Println(err)
	}

	http.Redirect(w, r, "/", 301)

}
