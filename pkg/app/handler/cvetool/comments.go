package cvetool

import (
	"glsamaker/pkg/app/handler/authentication"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/logger"
	"glsamaker/pkg/models/cve"
	"encoding/json"
	"glsamaker/pkg/models/users"
	"html"
	"net/http"
	"time"
)

// Show renders a template to show the landing page of the application
func AddComment(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	if !user.Permissions.CVETool.Comment {
		authentication.AccessDenied(w, r)
		return
	}

	id, comment, err := getParams(r)

	newComment, err := addNewCommment(id, user, comment)

	if err != nil || comment == "" {
		logger.Info.Println("Err")
		logger.Info.Println(err)
		w.Write([]byte("err"))
		return
	}

	newCommentString, _ := json.Marshal(newComment)

	w.Write(newCommentString)

}

func addNewCommment(id string, user *users.User, comment string) (cve.Comment, error) {

	cveItem := &cve.DefCveItem{Id: id}
	err := connection.DB.Select(cveItem)

	if err != nil {
		return cve.Comment{}, err
	}

	newComment := cve.Comment{
		CVEId:   id,
		UserId:  user.Id,
		User:    user,
		Message: html.EscapeString(comment),
		Date:    time.Now(),
	}

	//cveItem.Comments = append(cveItem.Comments, newComment)

	//_, err = connection.DB.Model(cveItem).Column("comments").WherePK().Update()
	_, err = connection.DB.Model(&newComment).Insert()

	return newComment, err

}

func getParams(r *http.Request) (string, string, error) {
	err := r.ParseForm()
	if err != nil {
		return "", "", err
	}
	id := r.Form.Get("cveid")
	comment := r.Form.Get("comment")
	return id, comment, err
}
