package glsa

import (
	"glsamaker/pkg/logger"
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/bugzilla"
	"glsamaker/pkg/models/users"
	"html/template"
	"net/http"
)

// renderIndexTemplate renders all templates used for the landing page
func renderViewTemplate(w http.ResponseWriter, user *users.User, glsa *models.Glsa, glsaCount int64) {

	templates := template.Must(
		template.Must(
			template.New("Show").
				Funcs(getFuncMap()).
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/glsa/show.tmpl"))

	templates.ExecuteTemplate(w, "show.tmpl", createPageData("show", user, glsa, glsaCount))
}

// renderIndexTemplate renders all templates used for the landing page
func renderEditTemplate(w http.ResponseWriter, user *users.User, glsa *models.Glsa, glsaCount int64) {
	templates := template.Must(
		template.Must(
			template.New("Show").
				Funcs(getFuncMap()).
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/glsa/edit.tmpl"))

	templates.ExecuteTemplate(w, "edit.tmpl", createPageData("edit", user, glsa, glsaCount))
}

// createPageData creates the data used in the template of the landing page
func createPageData(page string, user *users.User, glsa *models.Glsa, glsaCount int64) interface{} {
	return struct {
		Page        string
		Application *models.GlobalSettings
		User        *users.User
		Glsa        *models.Glsa
		GlsaCount   int64
	}{
		Page:        page,
		Application: models.GetDefaultGlobalSettings(),
		User:        user,
		Glsa:        glsa,
		GlsaCount:   glsaCount,
	}
}

func getFuncMap() template.FuncMap {
	return template.FuncMap{
		"bugIsReady": BugIsReady,
		"prevGLSA":   PrevGLSA,
		"nextGLSA":   NextGLSA,
	}
}

func BugIsReady(bug bugzilla.Bug) bool {
	return bug.IsReady()
}

func PrevGLSA(id int64, min int64) int64 {
	logger.Info.Println("prev glsa")
	if id == min {
		return id
	}
	return id - 1
}

func NextGLSA(id int64, max int64) int64 {
	if id == max {
		return id
	}
	return id + 1
}
