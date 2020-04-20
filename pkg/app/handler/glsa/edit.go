package glsa

import (
	"glsamaker/pkg/app/handler/authentication"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/logger"
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/bugzilla"
	"glsamaker/pkg/models/gpackage"
	"net/http"
	"sort"
	"strconv"
	"time"
)

func getStringParam(key string, r *http.Request) string {
	if len(r.Form[key]) > 0 {
		return r.Form[key][0]
	}

	return ""
}

func getArrayParam(key string, r *http.Request) []string {
	return r.Form[key]
}

// Show renders a template to show the landing page of the application
func Edit(w http.ResponseWriter, r *http.Request) {

	// TODO edit confidential bugs?

	user := utils.GetAuthenticatedUser(r)

	if !user.Permissions.Glsa.Edit {
		authentication.AccessDenied(w, r)
		return
	}

	glsaID := r.URL.Path[len("/glsa/edit/"):]

	parsedGlsaId, _ := strconv.ParseInt(glsaID, 10, 64)
	currentGlsa := &models.Glsa{Id: parsedGlsaId}
	err := user.CanAccess(connection.DB.Model(currentGlsa).
		Relation("Bugs").
		Relation("Creator").
		Relation("Comments").
		Relation("Comments.User").
		WherePK()).
		Select()

	if r.Method == "POST" {

		r.ParseForm()

		id, err := strconv.ParseInt(glsaID, 10, 64)

		if err != nil {
			http.NotFound(w, r)
			return
		}

		// if
		var packages []gpackage.Package
		for k, _ := range getArrayParam("package_atom", r) {
			newPackage := gpackage.Package{
				Affected:   r.Form["package_vulnerable"][k] == "true",
				Atom:       r.Form["package_atom"][k],
				Identifier: r.Form["package_identifier"][k],
				Version:    r.Form["package_version"][k],
				Slot:       r.Form["package_slot"][k],
				Arch:       r.Form["package_arch"][k],
				Auto:       r.Form["package_auto"][k] == "true",
			}
			packages = append(packages, newPackage)
		}

		var references []models.Reference
		for k, _ := range getArrayParam("reference_title", r) {
			newReference := models.Reference{
				Title: r.Form["reference_title"][k],
				URL:   r.Form["reference_url"][k],
			}
			references = append(references, newReference)
		}

		// Update Bugs: delete old mapping first
		_, err = connection.DB.Model(&[]models.GlsaToBug{}).Where("glsa_id = ?", glsaID).Delete()
		if err != nil {
			logger.Error.Println("ERR during delete")
			logger.Error.Println(err)
		}

		newBugs := bugzilla.GetBugsByIds(getArrayParam("bugs", r))

		for _, newBug := range newBugs {
			_, err = connection.DB.Model(&newBug).OnConflict("(id) DO UPDATE").Insert()

			if err != nil {
				logger.Error.Println("Error creating bug")
				logger.Error.Println(err)
			}

			parsedGlsaID, _ := strconv.ParseInt(glsaID, 10, 64)

			glsaToBug := &models.GlsaToBug{
				GlsaId: parsedGlsaID,
				BugId:  newBug.Id,
			}

			connection.DB.Model(glsaToBug).Insert()

		}

		glsa := &models.Glsa{
			Id: id,
			//			Alias:       getStringParam("alias", r),
			//			Type:        getStringParam("status", r),
			Title:       getStringParam("title", r),
			Synopsis:    getStringParam("synopsis", r),
			Packages:    packages,
			Description: getStringParam("description", r),
			Impact:      getStringParam("impact", r),
			Workaround:  getStringParam("workaround", r),
			Resolution:  getStringParam("resolution", r),
			References:  references,
			Permission:  getStringParam("permission", r),
			Access:      getStringParam("access", r),
			Severity:    getStringParam("severity", r),
			Keyword:     getStringParam("keyword", r),
			Background:  getStringParam("background", r),
			//TODO
			//Bugs:        ,
			//Comments:    nil,
			Revision: "r9999",
			//			Created:     time.Time{},
			Updated: time.Time{},
		}

		if currentGlsa.Type == "request" && glsa.Description != "" {
			glsa.Type = "draft"
		} else {
			glsa.Type = currentGlsa.Type
		}

		_, err = connection.DB.Model(glsa).Column(
			"type",
			"title",
			"synopsis",
			"packages",
			"description",
			"impact",
			"workaround",
			"resolution",
			"references",
			"permission",
			"access",
			"severity",
			"keyword",
			"background",
			"updated",
			"revision").WherePK().Update()

		if err != nil {
			http.NotFound(w, r)
			logger.Error.Println("ERR NOT FOUND")
			logger.Error.Println(err)
			return
		}

		http.Redirect(w, r, "/glsa/"+glsaID, 301)
		return
	}

	if err != nil {
		http.NotFound(w, r)
		return
	}

	currentGlsa.ComputeStatus(user)
	currentGlsa.ComputeCommentBadges()

	// sort the comments by creation date
	sort.Slice(currentGlsa.Comments, func(p, q int) bool {
		return currentGlsa.Comments[p].Date.Before(currentGlsa.Comments[q].Date) })

	glsaCount, err := connection.DB.Model((*models.Glsa)(nil)).Count()

	renderEditTemplate(w, user, currentGlsa, int64(glsaCount))
}
