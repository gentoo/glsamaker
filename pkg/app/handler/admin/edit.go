package admin

import (
	"glsamaker/pkg/app/handler/authentication"
	"glsamaker/pkg/app/handler/authentication/totp"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/logger"
	"glsamaker/pkg/models/users"
	"math/rand"
	"net/http"
	"strconv"
	"strings"
	"time"
)

// Show renders a template to show the landing page of the application
func EditUsers(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	if !user.Permissions.Admin.ManageUsers {
		authentication.AccessDenied(w, r)
		return
	}

	var allUsers []*users.User
	connection.DB.Model(&allUsers).Order("email ASC").Select()

	if r.Method == "POST" {

		r.ParseForm()

		if !(getStringParam("edit", r) == "1") {
			http.Redirect(w, r, "/admin", 301)
		}

		userIds := getArrayParam("userId", r)
		userNicks := getArrayParam("userNick", r)
		userNames := getArrayParam("userName", r)
		userEmails := getArrayParam("userEmail", r)
		userPasswordRotations := getArrayParam("userPasswordRotation", r)
		userForce2FA := getArrayParam("userForce2FA", r)
		userActive := getArrayParam("userActive", r)

		newUserIndex := -1

		for index, userId := range userIds {

			parsedUserId, err := strconv.ParseInt(userId, 10, 64)

			if err != nil {
				continue
			}

			count, _ := connection.DB.Model((*users.User)(nil)).Where("id = ?", parsedUserId).Count()

			// user is present
			if count == 1 {

				updatedUser := users.User{
					Id:    parsedUserId,
					Email: userEmails[index],
					Nick:  userNicks[index],
					Name:  userNames[index],
					//Badge:                   users.Badge{},
					ForcePasswordRotation: containsStr(userPasswordRotations, userId),
					Force2FA:              containsStr(userForce2FA, userId),
					Disabled:              !containsStr(userActive, userId),
				}

				connection.DB.Model(&updatedUser).
					Column("email").
					Column("nick").
					Column("name").
					Column("force_password_rotation").
					Column("force2fa").
					Column("disabled").
					WherePK().Update()

			} else {

				newUserIndex = index

			}

		}

		if newUserIndex != -1 {

			newPassword := generateNewPassword(14)

			createNewUser(
				userNicks[newUserIndex],
				userNames[newUserIndex],
				userEmails[newUserIndex],
				newPassword,
				containsStr(userForce2FA, "-1"),
				!containsStr(userActive, "-1"))

			var updatedUsers []*users.User
			connection.DB.Model(&updatedUsers).Order("email ASC").Select()

			renderAdminNewUserTemplate(w, user, updatedUsers, userNicks[newUserIndex], newPassword)
			return

		} else {

			http.Redirect(w, r, "/admin", 301)
			return

		}

	}

	renderEditUsersTemplate(w, user, allUsers)
}

// Show renders a template to show the landing page of the application
func EditPermissions(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	if !user.Permissions.Admin.ManageUsers {
		authentication.AccessDenied(w, r)
		return
	}

	var allUsers []*users.User
	connection.DB.Model(&allUsers).Order("email ASC").Select()

	if r.Method == "POST" {

		r.ParseForm()

		if !(getStringParam("edit", r) == "1") {
			http.Redirect(w, r, "/admin", 301)
		}

		glsaView := getArrayParam("glsa-view", r)
		glsaUpdateBugs := getArrayParam("glsa-updateBugs", r)
		glsaComment := getArrayParam("glsa-comment", r)
		glsaCreate := getArrayParam("glsa-create", r)
		glsaEdit := getArrayParam("glsa-edit", r)
		glsaDelete := getArrayParam("glsa-delete", r)
		glsaApprove := getArrayParam("glsa-approve", r)
		glsaApproveOwnGlsa := getArrayParam("glsa-approveOwnGlsa", r)
		glsaDecline := getArrayParam("glsa-decline", r)
		glsaRelease := getArrayParam("glsa-release", r)
		glsaConfidential := getArrayParam("glsa-confidential", r)

		cveView := getArrayParam("cve-view", r)
		cveUpdateCVEs := getArrayParam("cve-updateCVEs", r)
		cveComment := getArrayParam("cve-comment", r)
		cveAddCVE := getArrayParam("cve-addCVE", r)
		cveAddPackage := getArrayParam("cve-addPackage", r)
		cveChangeState := getArrayParam("cve-changeState", r)
		cveAssignBug := getArrayParam("cve-assignBug", r)

		adminView := getArrayParam("admin-view", r)
		adminCreateTemplates := getArrayParam("admin-createTemplates", r)
		adminGlobalSettings := getArrayParam("admin-globalSettings", r)
		adminManageUsers := getArrayParam("admin-manageUsers", r)

		for _, changedUser := range allUsers {

			updatedUserPermissions := users.Permissions{
				Glsa: users.GlsaPermissions{
					View:           containsInt(glsaView, changedUser.Id),
					UpdateBugs:     containsInt(glsaUpdateBugs, changedUser.Id),
					Comment:        containsInt(glsaComment, changedUser.Id),
					Create:         containsInt(glsaCreate, changedUser.Id),
					Edit:           containsInt(glsaEdit, changedUser.Id),
					Approve:        containsInt(glsaApprove, changedUser.Id),
					ApproveOwnGlsa: containsInt(glsaApproveOwnGlsa, changedUser.Id),
					Decline:        containsInt(glsaDecline, changedUser.Id),
					Delete:         containsInt(glsaDelete, changedUser.Id),
					Release:        containsInt(glsaRelease, changedUser.Id),
					Confidential:   containsInt(glsaConfidential, changedUser.Id),
				},
				CVETool: users.CVEToolPermissions{
					View:        containsInt(cveView, changedUser.Id),
					UpdateCVEs:  containsInt(cveUpdateCVEs, changedUser.Id),
					Comment:     containsInt(cveComment, changedUser.Id),
					AddCVE:      containsInt(cveAddCVE, changedUser.Id),
					AddPackage:  containsInt(cveAddPackage, changedUser.Id),
					ChangeState: containsInt(cveChangeState, changedUser.Id),
					AssignBug:   containsInt(cveAssignBug, changedUser.Id),
				},
				Admin: users.AdminPermissions{
					View:            containsInt(adminView, changedUser.Id),
					CreateTemplates: containsInt(adminCreateTemplates, changedUser.Id),
					ManageUsers:     containsInt(adminManageUsers, changedUser.Id),
					GlobalSettings:  containsInt(adminGlobalSettings, changedUser.Id),
				},
			}

			updatedUser := users.User{
				Id:          changedUser.Id,
				Permissions: updatedUserPermissions,
			}

			connection.DB.Model(&updatedUser).Column("permissions").WherePK().Update()
		}

		http.Redirect(w, r, "/admin", 301)
		return
	}

	renderEditPermissionsTemplate(w, user, allUsers)
}

func containsInt(arr []string, element int64) bool {
	return containsStr(arr, strconv.FormatInt(element, 10))
}

func containsStr(arr []string, element string) bool {
	for _, a := range arr {
		if a == element {
			return true
		}
	}
	return false
}

func getStringParam(key string, r *http.Request) string {
	if len(r.Form[key]) > 0 {
		return r.Form[key][0]
	}

	return ""
}

func getArrayParam(key string, r *http.Request) []string {
	return r.Form[key]
}

func createNewUser(nick, name, email, password string, force2FA, disabled bool) {

	token, qrcode := totp.Generate("user@gentoo.org")

	badge := users.Badge{
		Name:        "user",
		Description: "Normal user",
		Color:       "#54487A",
	}

	passwordParameters := users.Argon2Parameters{
		Type:    "argon2id",
		Time:    1,
		Memory:  64 * 1024,
		Threads: 4,
		KeyLen:  32,
	}
	passwordParameters.GenerateSalt(32)
	passwordParameters.GeneratePassword(password)

	defaultUser := &users.User{
		Email:                 email,
		Nick:                  nick,
		Name:                  name,
		Password:              passwordParameters,
		Role:                  "user",
		ForcePasswordChange:   false,
		TOTPSecret:            token,
		TOTPQRCode:            qrcode,
		IsUsingTOTP:           false,
		WebauthnCredentials:   nil,
		IsUsingWebAuthn:       false,
		Show2FANotice:         true,
		Badge:                 badge,
		Disabled:              disabled,
		ForcePasswordRotation: true,
		Force2FA:              force2FA,
	}

	_, err := connection.DB.Model(defaultUser).OnConflict("(id) DO Nothing").Insert()
	if err != nil {
		logger.Error.Println("Err during creating default admin user")
		logger.Error.Println(err)
	}
}

func generateNewPassword(length int) string {
	rand.Seed(time.Now().UnixNano())
	chars := []rune("ABCDEFGHIJKLMNOPQRSTUVWXYZÅÄÖ" +
		"abcdefghijklmnopqrstuvwxyz" +
		"0123456789" +
		"!&!$%&/()=?")
	var b strings.Builder
	for i := 0; i < length; i++ {
		b.WriteRune(chars[rand.Intn(len(chars))])
	}
	return b.String()
}
