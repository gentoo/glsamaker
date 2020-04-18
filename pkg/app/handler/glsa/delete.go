// Used to show the landing page of the application

package glsa

import (
	"glsamaker/pkg/app/handler/authentication"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/cve"
	"net/http"
	"strconv"
)

// Show renders a template to show the landing page of the application
func Delete(w http.ResponseWriter, r *http.Request) {

	// TODO delete confidential bugs?

	user := utils.GetAuthenticatedUser(r)

	if !user.Permissions.Glsa.Delete {
		authentication.AccessDenied(w, r)
		return
	}

	glsaID := r.URL.Path[len("/glsa/delete/"):]

	if _, err := strconv.Atoi(glsaID); err != nil {
		http.Redirect(w, r, "/", 301)
		w.Write([]byte("err"))
	}

	var glsa *models.Glsa
	var glsaToBug *models.GlsaToBug
	var comment *cve.Comment
	connection.DB.Model(glsa).Where("id = ?", glsaID).Delete()
	connection.DB.Model(glsaToBug).Where("glsa_id = ?", glsaID).Delete()
	connection.DB.Model(comment).Where("glsa_id = ?", glsaID).Delete()

	w.Write([]byte("ok"))
}
