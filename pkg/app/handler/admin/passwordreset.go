package admin

import (
	"glsamaker/pkg/app/handler/authentication"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/models/users"
	"net/http"
	"strconv"
)

// Show renders a template to show the landing page of the application
func ResetPassword(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	if !user.Permissions.Admin.ManageUsers {
		authentication.AccessDenied(w, r)
		return
	}

	userPasswordResetId := r.URL.Path[len("/admin/edit/password/reset/"):]

	parsedUserPasswordResetId, err := strconv.ParseInt(userPasswordResetId, 10, 64)

	if err != nil {
		http.NotFound(w, r)
		return
	}

	selectedUser := &users.User{Id: parsedUserPasswordResetId}
	err = connection.DB.Model(selectedUser).WherePK().Select()

	if err != nil || selectedUser == nil {
		http.NotFound(w, r)
		return
	}

	if r.Method == "POST" {

		newPassword := generateNewPassword(14)
		passwordParameters := users.Argon2Parameters{
			Type:    "argon2id",
			Time:    1,
			Memory:  64 * 1024,
			Threads: 4,
			KeyLen:  32,
		}
		passwordParameters.GenerateSalt(32)
		passwordParameters.GeneratePassword(newPassword)

		updatedUser := &users.User{
			Id:                    parsedUserPasswordResetId,
			Password:              passwordParameters,
			ForcePasswordRotation: true,
		}

		_, err = connection.DB.Model(updatedUser).Column("password").WherePK().Update()
		_, err = connection.DB.Model(updatedUser).Column("force_password_rotation").WherePK().Update()
		if err != nil {
			http.NotFound(w, r)
			return
		}

		var updatedUsers []*users.User
		connection.DB.Model(&updatedUsers).Order("email ASC").Select()

		renderAdminNewUserTemplate(w, user, updatedUsers, selectedUser.Nick, newPassword)
		return
	}

	renderPasswordResetTemplate(w, user, selectedUser.Id, selectedUser.Nick)
}
