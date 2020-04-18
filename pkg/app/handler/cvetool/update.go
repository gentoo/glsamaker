package cvetool

import (
	"glsamaker/pkg/app/handler/authentication"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/cveimport"
	"net/http"
)

// Show renders a template to show the landing page of the application
func Update(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	if !user.Permissions.CVETool.UpdateCVEs {
		authentication.AccessDenied(w, r)
		return
	}

	go cveimport.IncrementalCVEImport()

	http.Redirect(w, r, "/", 301)
}
