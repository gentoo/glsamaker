// Used to show the landing page of the application

package requests

import (
	"glsamaker/pkg/app/handler/authentication"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/logger"
	"glsamaker/pkg/models"
	"net/http"
)

// Show renders a template to show the landing page of the application
func Show(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	if !user.Permissions.Glsa.View {
		authentication.AccessDenied(w, r)
		return
	}

	var requests []*models.Glsa
	err := user.CanAccess(connection.DB.Model(&requests).
		Where("type = ?", "request").
		Relation("Bugs").
		Relation("Creator").
		Relation("Comments").
		Relation("Comments.User")).
		Select()

	if err != nil {
		logger.Info.Println("Error during request selection")
		logger.Info.Println(err)
		http.NotFound(w, r)
		return
	}

	for _, request := range requests {
		request.ComputeStatus(user)
	}

	renderRequestsTemplate(w, user, requests)
}
