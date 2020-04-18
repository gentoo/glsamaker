// Used to show the landing page of the application

package home

import (
	"glsamaker/pkg/app/handler/authentication/utils"
	"net/http"
)

// Show renders a template to show the landing page of the application
func Show(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	renderHomeTemplate(w, user)
}
