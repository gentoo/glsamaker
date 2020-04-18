// Used to show the landing page of the application

package all

import (
	"glsamaker/pkg/app/handler/authentication"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/database/connection"
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

	var all []*models.Glsa
	err := user.CanAccess(connection.DB.Model(&all).
		Relation("Bugs").
		Relation("Creator").
		Relation("Comments")).
		Select()

	if err != nil {
		http.NotFound(w, r)
		return
	}

	for _, glsa := range all {
		glsa.ComputeStatus(user)
	}

	renderAllTemplate(w, user, all)
}
