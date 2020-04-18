package templates

import (
	"html/template"
	"net/http"
)

func RenderWebAuthnTemplate(w http.ResponseWriter, r *http.Request) {

	data := struct {
		CameFrom string
	}{
		CameFrom: getPath(r),
	}

	templates := template.Must(
		template.Must(
			template.New("Show").
				ParseGlob("web/templates/layout/*.tmpl")).
			ParseGlob("web/templates/authentication/webauthn.tmpl"))

	templates.ExecuteTemplate(w, "webauthn.tmpl", data)
}
