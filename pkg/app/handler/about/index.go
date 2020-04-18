// Used to show the about pages of the application

package about

import (
	"glsamaker/pkg/app/handler/authentication/utils"
	"net/http"
)

// Show renders a template to show the main about page of the application
func Show(w http.ResponseWriter, r *http.Request) {
	user := utils.GetAuthenticatedUser(r)
	renderAboutTemplate(w, user)
}

// ShowSearch renders a template to show the about
// page about the search functionality
func ShowSearch(w http.ResponseWriter, r *http.Request) {
	user := utils.GetAuthenticatedUser(r)
	renderAboutSearchTemplate(w, user)
}

// ShowCLI renders a template to show the about
// page about the command line tool
func ShowCLI(w http.ResponseWriter, r *http.Request) {
	user := utils.GetAuthenticatedUser(r)
	renderAboutCLITemplate(w, user)
}
