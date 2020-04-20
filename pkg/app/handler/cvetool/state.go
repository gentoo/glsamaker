package cvetool

import (
	"glsamaker/pkg/app/handler/authentication"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/logger"
	"glsamaker/pkg/models/cve"
	"encoding/json"
	"net/http"
)

// Show renders a template to show the landing page of the application
func ChangeState(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	if !user.Permissions.CVETool.ChangeState {
		authentication.AccessDenied(w, r)
		return
	}

	if !user.CanEditCVEs() {
		logger.Error.Println("Err, user can not edit.")
		w.Write([]byte("err"))
		return
	}

	id, newState, reason, err := getStateParams(r)

	cveItem := &cve.DefCveItem{Id: id}
	err = connection.DB.Select(cveItem)

	if err != nil || reason == "" || cveItem.State == "Assigned" || !(newState == "NFU" || newState == "Later" || newState == "Invalid") {
		logger.Error.Println("Err, invalid data")
		logger.Error.Println(err)
		w.Write([]byte("err"))
		return
	}

	cveItem.State = newState
	_, err = connection.DB.Model(cveItem).Column("state").WherePK().Update()

	if err != nil {
		logger.Error.Println("Err")
		logger.Error.Println(err)
		w.Write([]byte("err"))
		return
	}

	newComment, err := addNewCommment(id, user, "Changed status to "+newState+": "+reason)

	if err != nil {
		logger.Error.Println("Err")
		logger.Error.Println(err)
		w.Write([]byte("err"))
		return
	}

	newCommentString, _ := json.Marshal(newComment)

	w.Write(newCommentString)

}

func getStateParams(r *http.Request) (string, string, string, error) {
	err := r.ParseForm()
	if err != nil {
		return "", "", "", err
	}
	id := r.Form.Get("cveid")
	newstate := r.Form.Get("newstate")
	reason := r.Form.Get("reason")
	return id, newstate, reason, err
}
