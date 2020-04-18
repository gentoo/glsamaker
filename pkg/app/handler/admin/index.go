// Used to show the landing page of the application

package admin

import (
	"glsamaker/pkg/app/handler/authentication"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/models/users"
	"net/http"
)

// Show renders a template to show the landing page of the application
func Show(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	if !user.Permissions.Admin.View {
		authentication.AccessDenied(w, r)
		return
	}

	var users []*users.User
	connection.DB.Model(&users).Order("email ASC").Select()

	renderAdminTemplate(w, user, users)
}
