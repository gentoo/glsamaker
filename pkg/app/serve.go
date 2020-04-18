// Entrypoint for the web application

package app

import (
	"glsamaker/pkg/app/handler/about"
	"glsamaker/pkg/app/handler/account"
	"glsamaker/pkg/app/handler/admin"
	"glsamaker/pkg/app/handler/all"
	"glsamaker/pkg/app/handler/archive"
	"glsamaker/pkg/app/handler/authentication"
	"glsamaker/pkg/app/handler/authentication/totp"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/app/handler/authentication/webauthn"
	"glsamaker/pkg/app/handler/cvetool"
	"glsamaker/pkg/app/handler/dashboard"
	"glsamaker/pkg/app/handler/drafts"
	"glsamaker/pkg/app/handler/glsa"
	"glsamaker/pkg/app/handler/home"
	"glsamaker/pkg/app/handler/newRequest"
	"glsamaker/pkg/app/handler/requests"
	"glsamaker/pkg/app/handler/search"
	"glsamaker/pkg/app/handler/statistics"
	"glsamaker/pkg/config"
	"glsamaker/pkg/database"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/logger"
	"glsamaker/pkg/models"
	"log"
	"net/http"
	"strings"
)

// Serve is used to serve the web application
func Serve() {

	database.Connect()
	defer connection.DB.Close()

	CreateDefaultAdmin()
	models.SeedInitialApplicationData()

	// public login page
	loginPage("/login", authentication.Login)

	// second factor login page
	// (either totp or webauthn, depending on the user settings)
	twoFactorLogin("/login/2fa", authentication.SecondFactorLogin)

	// webauthn login endpoints
	twoFactorLogin("/login/2fa/totp", totp.Login)

	// webauthn login endpoints
	twoFactorLogin("/login/2fa/webauthn/begin", webauthn.BeginLogin)
	twoFactorLogin("/login/2fa/webauthn/finish", webauthn.FinishLogin)

	requireLogin("/", home.Show)

	requireLogin("/dashboard", dashboard.Show)

	requireLogin("/statistics", statistics.Show)

	requireLogin("/search", search.Search)

	requireLogin("/about", about.Show)
	requireLogin("/about/search", about.ShowSearch)
	requireLogin("/about/cli", about.ShowCLI)

	requireLogin("/archive", archive.Show)

	requireLogin("/drafts", drafts.Show)

	requireLogin("/requests", requests.Show)

	requireLogin("/all", all.Show)

	requireLogin("/new", newRequest.Show)

	requireLogin("/cve/update", cvetool.Update)
	requireLogin("/cve/tool", cvetool.Show)
	requireLogin("/cve/tool/fullscreen", cvetool.ShowFullscreen)
	requireLogin("/cve/data", cvetool.CveData)
	requireLogin("/cve/add", cvetool.Add)
	requireLogin("/cve/comment/add", cvetool.AddComment)
	requireLogin("/cve/bug/assign", cvetool.AssignBug)
	requireLogin("/cve/state/change", cvetool.ChangeState)

	requireLogin("/logout", authentication.Logout)

	requireLogin("/account/password", account.ChangePassword)
	requireLogin("/account/2fa", account.TwoFactorAuth)
	requireLogin("/account/2fa/notice/disable", account.Disable2FANotice)
	requireLogin("/account/2fa/totp/activate", account.ActivateTOTP)
	requireLogin("/account/2fa/totp/disable", account.DisableTOTP)
	requireLogin("/account/2fa/totp/verify", account.VerifyTOTP)
	requireLogin("/account/2fa/webauthn/activate", account.ActivateWebAuthn)
	requireLogin("/account/2fa/webauthn/disable", account.DisableWebAuthn)
	requireLogin("/account/2fa/webauthn/register/begin", webauthn.BeginRegistration)
	requireLogin("/account/2fa/webauthn/register/finish", webauthn.FinishRegistration)

	requireLogin("/glsa/", glsa.View)
	requireLogin("/glsa/edit/", glsa.Edit)
	requireLogin("/glsa/comment/add", glsa.AddComment)
	requireLogin("/glsa/delete/", glsa.Delete)
	requireLogin("/glsa/release/", glsa.Release)
	requireLogin("/glsa/bugs/update", glsa.UpdateBugs)

	requireAdmin("/admin", admin.Show)
	requireAdmin("/admin/", admin.Show)
	requireAdmin("/admin/edit/users", admin.EditUsers)
	requireAdmin("/admin/edit/permissions", admin.EditPermissions)
	requireAdmin("/admin/edit/password/reset/", admin.ResetPassword)

	fs := http.StripPrefix("/assets/", http.FileServer(http.Dir("/go/src/glsamaker/assets")))
	requireLogin("/assets/", fs.ServeHTTP)

	logger.Info.Println("Serving on port " + config.Port())
	log.Fatal(http.ListenAndServe(":"+config.Port(), nil))
}

func loginPage(path string, handler http.HandlerFunc) {
	http.HandleFunc(path, func(w http.ResponseWriter, r *http.Request) {
		setDefaultHeaders(w)

		if utils.IsAuthenticated(w, r) {
			http.Redirect(w, r, "/", 301)
		} else if utils.Only2FAMissing(w, r) {
			http.Redirect(w, r, "/login/2fa", 301)
		} else {
			handler(w, r)
		}
	})
}

func twoFactorLogin(path string, handler http.HandlerFunc) {
	http.HandleFunc(path, func(w http.ResponseWriter, r *http.Request) {
		setDefaultHeaders(w)

		if utils.IsAuthenticated(w, r) {
			http.Redirect(w, r, "/", 301)
		} else if utils.Only2FAMissing(w, r) {
			handler(w, r)
		} else {
			http.Redirect(w, r, "/login", 301)
		}
	})
}

// define a route using the default middleware and the given handler
func requireLogin(path string, handler http.HandlerFunc) {
	http.HandleFunc(path, func(w http.ResponseWriter, r *http.Request) {
		setDefaultHeaders(w)

		if utils.IsAuthenticatedAndNeedsNewPassword(w, r) {
			if strings.HasPrefix(path, "/logout") ||
				strings.HasPrefix(path, "/assets/") ||
				strings.HasPrefix(path, "/account/password") {
				handler(w, r)
			} else {
				http.Redirect(w, r, "/account/password", 301)
			}
		} else if utils.IsAuthenticatedAndNeeds2FA(w, r) {
			if strings.HasPrefix(path, "/logout") ||
				strings.HasPrefix(path, "/assets/") ||
				strings.HasPrefix(path, "/account/2fa") {
				handler(w, r)
			} else {
				http.Redirect(w, r, "/account/2fa", 301)
			}
		} else if utils.IsAuthenticated(w, r) {
			handler(w, r)
		} else if utils.Only2FAMissing(w, r) {
			http.Redirect(w, r, "/login/2fa", 301)
		} else {
			http.Redirect(w, r, "/login", 301)
		}
	})
}

// define a route using the default middleware and the given handler
func requireAdmin(path string, handler http.HandlerFunc) {
	http.HandleFunc(path, func(w http.ResponseWriter, r *http.Request) {
		setDefaultHeaders(w)

		if utils.IsAuthenticatedAndNeedsNewPassword(w, r) {
			if strings.HasPrefix(path, "/logout") ||
				strings.HasPrefix(path, "/assets/") ||
				strings.HasPrefix(path, "/account/password") {
				handler(w, r)
			} else {
				http.Redirect(w, r, "/account/password", 301)
			}
		} else if utils.IsAuthenticatedAndNeeds2FA(w, r) {
			if strings.HasPrefix(path, "/logout") ||
				strings.HasPrefix(path, "/assets/") ||
				strings.HasPrefix(path, "/account/2fa") {
				handler(w, r)
			} else {
				http.Redirect(w, r, "/account/2fa", 301)
			}
		} else if utils.IsAuthenticatedAsAdmin(w, r) {
			handler(w, r)
		} else if utils.IsAuthenticated(w, r) {
			authentication.AccessDenied(w, r)
		} else {
			http.Redirect(w, r, "/login", 301)
		}
	})
}

// setDefaultHeaders sets the default headers that apply for all pages
func setDefaultHeaders(w http.ResponseWriter) {
	w.Header().Set("Cache-Control", "no-store")
}
