package glsa

import (
	"glsamaker/pkg/app/handler/authentication"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/logger"
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/cve"
	"glsamaker/pkg/models/users"
	"encoding/json"
	"errors"
	"html"
	"net/http"
	"strconv"
	"time"
)

// Show renders a template to show the landing page of the application
func AddComment(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	if !user.Permissions.Glsa.Comment {
		authentication.AccessDenied(w, r)
		return
	}

	id, comment, commentType, err := getParams(r)

	newComment, err := AddNewCommment(id, user, comment, commentType)

	if err != nil || comment == "" {
		logger.Info.Println("Err")
		logger.Info.Println(err)
		w.Write([]byte("err"))
		return
	}

	newComment.Message = html.EscapeString(newComment.Message)
	newComment.User = &users.User{
		Id:                      newComment.User.Id,
		Email:                   newComment.User.Email,
		Nick:                    newComment.User.Nick,
		Name:                    newComment.User.Name,
		Badge:                   newComment.User.Badge,
	}

	newCommentString, _ := json.Marshal(newComment)

	w.Write(newCommentString)

}

func AddNewCommment(id string, user *users.User, comment string, commentType string) (cve.Comment, error) {

	glsaID, err := strconv.ParseInt(id, 10, 64)

	if err != nil {
		return cve.Comment{}, err
	}

	glsa := &models.Glsa{Id: glsaID}
	err = user.CanAccess(connection.DB.Model(glsa).WherePK()).Select()

	if err != nil {
		return cve.Comment{}, err
	}

	// TODO: VALIDATE !!

	if commentType == "approve" && !user.Permissions.Glsa.Approve {
		return cve.Comment{}, errors.New("ACCESS DENIED")
	} else if commentType == "approve" && glsa.CreatorId == user.Id && !user.Permissions.Glsa.ApproveOwnGlsa {
		return cve.Comment{}, errors.New("ACCESS DENIED")
	} else if commentType == "decline" && !user.Permissions.Glsa.Decline {
		return cve.Comment{}, errors.New("ACCESS DENIED")
	}

	if commentType == "approve" {
		glsa.ApprovedBy = append(glsa.ApprovedBy, user.Id)
		_, err = connection.DB.Model(glsa).Column("approved_by").WherePK().Update()
	} else if commentType == "decline" {
		glsa.DeclinedBy = append(glsa.DeclinedBy, user.Id)
		_, err = connection.DB.Model(glsa).Column("declined_by").WherePK().Update()
	}

	newComment := cve.Comment{
		GlsaId:    glsaID,
		UserId:    user.Id,
		User:      user,
		UserBadge: user.Badge,
		Type:      commentType,
		Message:   comment,
		Date:      time.Now(),
	}

	glsa.Comments = append(glsa.Comments, newComment)

	//_, err = connection.DB.Model(glsa).Column("comments").WherePK().Update()
	_, err = connection.DB.Model(&newComment).Insert()

	return newComment, err

}

func getParams(r *http.Request) (string, string, string, error) {
	err := r.ParseForm()
	if err != nil {
		return "", "", "", err
	}
	id := r.Form.Get("glsaid")
	comment := r.Form.Get("comment")
	commentType := r.Form.Get("commentType")
	return id, comment, commentType, err
}
