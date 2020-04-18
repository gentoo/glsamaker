// Used to show the change password page

package account

import (
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/logger"
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/users"
	"html/template"
	"net/http"
)

// ChangePassword changes the password of a user in case of a valid POST request.
// In case of a GET request the dialog for the password change is displayed
func ChangePassword(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	if r.Method == "POST" {

		r.ParseForm()

		oldPassword := getStringParam("oldPassword", r)
		newPassword := getStringParam("newPassword", r)
		confirmedNewPassword := getStringParam("confirmedNewPassword", r)

		if newPassword != confirmedNewPassword {
			renderPasswordChangeTemplate(w, r, user, false, "The passwords you have entered do not match")
			return
		}

		if !user.CheckPassword(oldPassword) {
			renderPasswordChangeTemplate(w, r, user, false, "The old password you have entered is not correct")
			return
		}

		err := user.UpdatePassword(newPassword)
		if err != nil {
			renderPasswordChangeTemplate(w, r, user, false, "Internal error during hash calculation.")
			return
		}

		wasForcedToChange := user.ForcePasswordRotation
		user.ForcePasswordRotation = false

		_, err = connection.DB.Model(user).Column("password").WherePK().Update()
		_, err = connection.DB.Model(user).Column("force_password_rotation").WherePK().Update()

		if err != nil {
			logger.Info.Println("error during password update")
			logger.Info.Println(err)
			renderPasswordChangeTemplate(w, r, user, false, "Internal error during password update.")
			return
		}

		if wasForcedToChange {
			http.Redirect(w, r, "/", 301)
			return
		}

		updatedUser := utils.GetAuthenticatedUser(r)

		renderPasswordChangeTemplate(w, r, updatedUser, true, "Your password has been changed successfully.")
		return
	}

	renderPasswordChangeTemplate(w, r, user, false, "")
}

// renderPasswordChangeTemplate renders all templates used for the login page
func renderPasswordChangeTemplate(w http.ResponseWriter, r *http.Request, user *users.User, success bool, message string) {

	templates := template.Must(
		template.Must(
			template.New("Show").
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/account/password/*.tmpl"))

	templates.ExecuteTemplate(w, "password.tmpl", createPasswordChangeData("account", user, success, message))
}

// createPasswordChangeData creates the data used in the template of the password change page
func createPasswordChangeData(page string, user *users.User, success bool, message string) interface{} {

	return struct {
		Page        string
		Application *models.GlobalSettings
		User        *users.User
		Success     bool
		Message     string
	}{
		Page:        page,
		Application: models.GetDefaultGlobalSettings(),
		User:        user,
		Success:     success,
		Message:     message,
	}
}

// returns the value of a parameter with the given key of a POST request
func getStringParam(key string, r *http.Request) string {
	if len(r.Form[key]) > 0 {
		return r.Form[key][0]
	}

	return ""
}
