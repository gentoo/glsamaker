package authentication

import (
	"glsamaker/pkg/app/handler/authentication/templates"
	"net/http"
)

func AccessDenied(w http.ResponseWriter, r *http.Request) {
	templates.RenderAccessDeniedTemplate(w, r)
}
