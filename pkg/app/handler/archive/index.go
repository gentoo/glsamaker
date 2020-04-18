// Used to show the landing page of the application

package archive

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

	var glsas []*models.Glsa
	err := user.CanAccess(connection.DB.Model(&glsas).
		Where("type = ?", "glsa").
		Relation("Bugs").
		Relation("Creator").
		Relation("Comments")).
		Select()

	if err != nil {
		logger.Info.Println("Error during glsa selection")
		logger.Info.Println(err)
		http.NotFound(w, r)
		return
	}

	for _, glsa := range glsas {
		glsa.ComputeStatus(user)
	}

	renderArchiveTemplate(w, user, glsas)
}
