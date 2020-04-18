package templates

import (
	"html/template"
	"net/http"
)

func RenderTOTPTemplate(w http.ResponseWriter, r *http.Request) {

	data := struct {
		CameFrom string
	}{
		CameFrom: getPath(r),
	}

	templates := template.Must(
		template.Must(
			template.New("Show").
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/authentication/totp.tmpl"))

	templates.ExecuteTemplate(w, "totp.tmpl", data)
}
