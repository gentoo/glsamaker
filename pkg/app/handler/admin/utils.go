// miscellaneous utility functions used for the landing page of the application

package admin

import (
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/users"
	"html/template"
	"net/http"
)

// renderIndexTemplate renders all templates used for the landing page
func renderAdminTemplate(w http.ResponseWriter, user *users.User, allUsers []*users.User) {
	templates := template.Must(
		template.Must(
			template.Must(
				template.New("Show").
					ParseGlob("web/templates/layout/*.tmpl")).
				ParseGlob("web/templates/admin/components/*.tmpl")).
			ParseGlob("web/templates/admin/*.tmpl"))

	templates.ExecuteTemplate(w, "view.tmpl", createPageData("admin", user, allUsers, "", ""))
}

// renderIndexTemplate renders all templates used for the landing page
func renderAdminNewUserTemplate(w http.ResponseWriter, user *users.User, allUsers []*users.User, newUserNick, newUserPass string) {
	templates := template.Must(
		template.Must(
			template.Must(
				template.New("Show").
					ParseGlob("web/templates/layout/*.tmpl")).
				ParseGlob("web/templates/admin/components/*.tmpl")).
			ParseGlob("web/templates/admin/*.tmpl"))

	templates.ExecuteTemplate(w, "view.tmpl", createPageData("admin", user, allUsers, newUserNick, newUserPass))
}

// renderIndexTemplate renders all templates used for the landing page
func renderEditUsersTemplate(w http.ResponseWriter, user *users.User, allUsers []*users.User) {
	templates := template.Must(
		template.Must(
			template.Must(
				template.New("Show").
					ParseGlob("web/templates/layout/*.tmpl")).
				ParseGlob("web/templates/admin/components/*.tmpl")).
			ParseGlob("web/templates/admin/edit/*.tmpl"))

	templates.ExecuteTemplate(w, "users.tmpl", createPageData("admin", user, allUsers, "", ""))
}

// renderIndexTemplate renders all templates used for the landing page
func renderPasswordResetTemplate(w http.ResponseWriter, user *users.User, userId int64, userNick string) {
	templates := template.Must(
		template.Must(
			template.New("Show").
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/admin/passwordreset.tmpl"))

	templates.ExecuteTemplate(w, "passwordreset.tmpl", createPasswordResetData("admin", user, userId, userNick))
}

// renderIndexTemplate renders all templates used for the landing page
func renderEditPermissionsTemplate(w http.ResponseWriter, user *users.User, allUsers []*users.User) {
	templates := template.Must(
		template.Must(
			template.Must(
				template.New("Show").
					ParseGlob("web/templates/layout/*.tmpl")).
				ParseGlob("web/templates/admin/components/*.tmpl")).
			ParseGlob("web/templates/admin/edit/*.tmpl"))

	templates.ExecuteTemplate(w, "permissions.tmpl", createPageData("admin", user, allUsers, "", ""))
}

// createPageData creates the data used in the template of the landing page
func createPageData(page string, user *users.User, allUsers []*users.User, newUserNick, newUserPassword string) interface{} {
	return struct {
		Page            string
		Application     *models.GlobalSettings
		User            *users.User
		Users           []*users.User
		NewUserNick     string
		NewUserPassword string
	}{
		Page:            page,
		Application:     models.GetDefaultGlobalSettings(),
		User:            user,
		Users:           allUsers,
		NewUserNick:     newUserNick,
		NewUserPassword: newUserPassword,
	}
}

// createPageData creates the data used in the template of the landing page
func createPasswordResetData(page string, user *users.User, userId int64, userNick string) interface{} {
	return struct {
		Page            string
		Application     *models.GlobalSettings
		User            *users.User
		Users           []*users.User
		NewUserNick     string
		NewUserPassword string
		UserId          int64
		UserNick        string
	}{
		Page:        page,
		Application: models.GetDefaultGlobalSettings(),
		User:        user,
		UserId:      userId,
		UserNick:    userNick,
	}
}
