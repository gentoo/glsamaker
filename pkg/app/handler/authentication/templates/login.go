package templates

import (
	"html/template"
	"net/http"
)

// renderIndexTemplate renders all templates used for the login page
func RenderLoginTemplate(w http.ResponseWriter, r *http.Request) {

	data := struct {
		CameFrom string
	}{
		CameFrom: getPath(r),
	}

	templates := template.Must(
		template.Must(
			template.New("Show").
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/authentication/login.tmpl"))

	templates.ExecuteTemplate(w, "login.tmpl", data)
}

func getPath(r *http.Request) string {
	if r.URL.RawQuery == "" {
		return r.URL.Path
	} else {
		return r.URL.Path + "?" + r.URL.RawQuery
	}
}
