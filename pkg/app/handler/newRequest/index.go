// Used to show the landing page of the application

package newRequest

import (
	"glsamaker/pkg/app/handler/authentication"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/app/handler/glsa"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/logger"
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/bugzilla"
	"glsamaker/pkg/models/cve"
	"crypto/sha256"
	"fmt"
	"github.com/go-pg/pg/v9"
	"net/http"
	"strconv"
	"strings"
	"time"
)

// Show renders a template to show the landing page of the application
func Show(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	if !user.Permissions.Glsa.Create {
		authentication.AccessDenied(w, r)
		return
	}

	bugs, title, synopsis, description, workaround, impact, background, resolution, importReferences, permissions, access, severity, keyword, comment, err := getParams(r)
	newID := getNextGLSAId()

	if err != nil || bugs == "" {
		// render without message
		renderNewTemplate(w, user, strconv.FormatInt(newID, 10))
		return
	}

	// create bugs
	newBugs := bugzilla.GetBugsByIds(strings.Split(bugs, ","))

	for _, newBug := range newBugs {
		_, err = connection.DB.Model(&newBug).OnConflict("(id) DO UPDATE").Insert()

		if err != nil {
			logger.Error.Println("Error creating bug")
			logger.Error.Println(err)
		}

		glsaToBug := &models.GlsaToBug{
			GlsaId: newID,
			BugId:  newBug.Id,
		}

		connection.DB.Model(glsaToBug).Insert()

	}

	var references []models.Reference

	// TODO if title is empty try to import from bug
	// TODO validate permissions
	if importReferences {
		// TODO import references

		// import from CVE
		for _, bug := range strings.Split(bugs, ",") {
			var cves []cve.DefCveItem
			connection.DB.Model(&cves).Where("bugs::jsonb @> ?", "\""+bug+"\"").Select()

			for _, cve := range cves {
				references = append(references, models.Reference{
					Title: cve.Id,
					URL:   "https://nvd.nist.gov/vuln/detail/" + cve.Id,
				})
			}

		}

		// import from BUG
		for _, bug := range newBugs {
			for _, alias := range bug.Alias {
				if strings.HasPrefix(alias, "CVE-") {
					alreadyPresent := false
					for _, reference := range references {
						if reference.Title == alias {
							alreadyPresent = true
						}
					}
					if !alreadyPresent {
						references = append(references, models.Reference{
							Title: alias,
							URL:   "https://nvd.nist.gov/vuln/detail/" + alias,
						})
					}
				}
			}
		}

	}

	id := title + bugs + time.Now().String()
	id = fmt.Sprintf("%x", sha256.Sum256([]byte(id)))

	glsaType := "request"
	if description != "" {
		glsaType = "draft"
	}

	newGlsa := &models.Glsa{
		//Id:          id,
		Type:        glsaType,
		Title:       title,
		Synopsis:    synopsis,
		Description: description,
		Workaround:  workaround,
		Impact:      impact,
		Background:  background,
		Resolution:  resolution,
		References:  references,
		Permission:  permissions,
		Access:      access,
		Severity:    severity,
		Keyword:     keyword,
		Revision:    "r0",
		CreatorId:   user.Id,
		Created:     time.Now(),
		Updated:     time.Now(),
	}

	_, err = connection.DB.Model(newGlsa).OnConflict("(id) DO Nothing").Insert()
	if err != nil {
		logger.Error.Println("Err during creating new GLSA")
		logger.Error.Println(err)
	}

	if comment != "" {
		glsa.AddNewCommment(strconv.FormatInt(newID, 10), user, comment, "comment")
	}

	if glsaType == "draft" {
		http.Redirect(w, r, "/drafts", 301)
	} else {
		http.Redirect(w, r, "/requests", 301)
	}
}

func getParams(r *http.Request) (string, string, string, string, string, string, string, string, bool, string, string, string, string, string, error) {
	err := r.ParseForm()
	if err != nil {
		return "", "", "", "", "", "", "", "", false, "", "", "", "", "", err
	}
	bugs := r.Form.Get("bugs")
	title := r.Form.Get("title")
	synopsis := r.Form.Get("synopsis")
	description := r.Form.Get("description")
	workaround := r.Form.Get("workaround")
	impact := r.Form.Get("impact")
	background := r.Form.Get("background")
	resolution := r.Form.Get("resolution")
	importReferences := r.Form.Get("importReferences")
	permissions := r.Form.Get("permissions")
	access := r.Form.Get("access")
	severity := r.Form.Get("severity")
	keyword := r.Form.Get("keyword")
	comment := r.Form.Get("comment")
	return bugs, title, synopsis, description, workaround, impact, background, resolution, importReferences == "on", permissions, access, severity, keyword, comment, err
}

func getNextGLSAId() int64 {
	var newID int64
	newID = 1
	var glsas []*models.Glsa
	err := connection.DB.Model(&glsas).Order("id DESC").Limit(1).Select()

	if err != nil && err != pg.ErrNoRows {
		newID = -1
	} else if glsas != nil && len(glsas) == 1 {
		newID = glsas[0].Id + 1
	}

	return newID
}
