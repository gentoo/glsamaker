// Used to show the landing page of the application

package drafts

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

	var drafts []*models.Glsa
	err := user.CanAccess(connection.DB.Model(&drafts).
		Where("type = ?", "draft").
		Relation("Bugs").
		Relation("Creator").
		Relation("Comments")).
		Select()

	if err != nil {
		logger.Info.Println("Error during draft selection")
		logger.Info.Println(err)
		http.NotFound(w, r)
		return
	}

	for _, draft := range drafts {
		draft.ComputeStatus(user)
	}

	renderDraftsTemplate(w, user, drafts)
}
