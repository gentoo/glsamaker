package templates

import (
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/users"
	"html/template"
	"net/http"
)

// renderIndexTemplate renders all templates used for the login page
func RenderAccessDeniedTemplate(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	templates := template.Must(
		template.Must(
			template.New("Show").
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/authentication/accessDenied.tmpl"))

	templates.ExecuteTemplate(w, "accessDenied.tmpl", createAccessDeniedData(user))
}

// createPageData creates the data used in the template of the landing page
func createAccessDeniedData(user *users.User) interface{} {
	return struct {
		Page        string
		Application *models.GlobalSettings
		User        *users.User
	}{
		Page:        "",
		Application: models.GetDefaultGlobalSettings(),
		User:        user,
	}
}
