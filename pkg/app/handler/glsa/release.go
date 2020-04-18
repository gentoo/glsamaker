package glsa

import (
	"glsamaker/pkg/app/handler/authentication"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/logger"
	"glsamaker/pkg/models"
	"net/http"
	"strconv"
	"strings"
	"time"
)

// Show renders a template to show the landing page of the application
func Release(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)

	if !user.Permissions.Glsa.Release {
		authentication.AccessDenied(w, r)
		return
	}

	glsaID := r.URL.Path[len("/glsa/release/"):]

	currentGlsa := new(models.Glsa)
	err := user.CanAccess(connection.DB.Model(currentGlsa).
		Where("id = ?", glsaID)).
		Select()

	if err != nil {
		http.NotFound(w, r)
		return
	}

	currentGlsa.Type = "glsa"
	currentGlsa.Alias = computeNextGLSAId()

	_, err = connection.DB.Model(currentGlsa).Column("type").WherePK().Update()
	_, err = connection.DB.Model(currentGlsa).Column("alias").WherePK().Update()

	http.Redirect(w, r, "/archive", 301)
}

func computeNextGLSAId() string {

	logger.Info.Println("compute Next GLSA")

	newGLSAID := ""
	var glsas []*models.Glsa
	err := connection.DB.Model(&glsas).Where("type = ?", "glsa").Order("alias DESC").Limit(1).Select()

	if err != nil || len(glsas) == 0 {
		newGLSAID = time.Now().Format("200601") + "-" + "01"
	} else if !strings.HasPrefix(glsas[0].Alias, time.Now().Format("200601")+"-") {
		newGLSAID = time.Now().Format("200601") + "-" + "01"
	} else {
		oldId := strings.Replace(glsas[0].Alias, time.Now().Format("200601")+"-", "", 1)
		parsedOldId, _ := strconv.Atoi(oldId)
		parsedOldId = parsedOldId + 1
		newID := strconv.Itoa(parsedOldId)
		if len(newID) < 2 {
			newID = "0" + newID
		}
		newGLSAID = time.Now().Format("200601") + "-" + newID
	}

	return newGLSAID
}
