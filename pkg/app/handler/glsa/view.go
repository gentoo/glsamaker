package glsa

import (
	"glsamaker/pkg/app/handler/authentication"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/models"
	"net/http"
	"strconv"
)

// Show renders a template to show the landing page of the application
func View(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	if !user.Permissions.Glsa.View {
		authentication.AccessDenied(w, r)
		return
	}

	glsaID := r.URL.Path[len("/glsa/"):]

	parsedGlsaId, _ := strconv.ParseInt(glsaID, 10, 64)
	glsa := &models.Glsa{Id: parsedGlsaId}
	err := user.CanAccess(connection.DB.Model(glsa).
		Relation("Bugs").
		Relation("Creator").
		Relation("Comments").
		Relation("Comments.User").WherePK()).
		Select()

	if err != nil {
		http.NotFound(w, r)
		return
	}

	if glsa.Permission == "confidential" && user.Confidential() != "confidential" {
		authentication.AccessDenied(w, r)
		return
	}

	glsa.ComputeStatus(user)
	glsa.ComputeCommentBadges()

	glsaCount, err := connection.DB.Model((*models.Glsa)(nil)).Count()

	renderViewTemplate(w, user, glsa, int64(glsaCount))
}
