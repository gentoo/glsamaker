package totp

import (
	"glsamaker/pkg/app/handler/authentication/auth_session"
	"glsamaker/pkg/app/handler/authentication/utils"
	"glsamaker/pkg/models/users"
	"bytes"
	"encoding/base64"
	"github.com/pquerna/otp/totp"
	"image/png"
	"net/http"
	"time"
)

func Login(w http.ResponseWriter, r *http.Request) {

	user := utils.GetAuthenticatedUser(r)
	token, err := getParam(r)

	if user == nil || err != nil || !IsValidTOTPToken(user, token) {
		http.Redirect(w, r, "/login/2fa", 301)
	} else {
		auth_session.Create(w, r, user, true, false)
		http.Redirect(w, r, "/", 301)
	}

}

func IsValidTOTPToken(user *users.User, token string) bool {
	return totp.Validate(token, user.TOTPSecret)
}

func GetToken(user *users.User) string {
	token, _ := totp.GenerateCode(user.TOTPSecret, time.Now())
	return token
}

func Generate(email string) (string, string) {

	key, _ := totp.Generate(totp.GenerateOpts{
		Issuer:      "glsamakertest.gentoo.org",
		AccountName: email,
	})

	var buf bytes.Buffer
	img, _ := key.Image(250, 250)

	png.Encode(&buf, img)

	return key.Secret(), base64.StdEncoding.EncodeToString(buf.Bytes())
}

func getParam(r *http.Request) (string, error) {
	err := r.ParseForm()
	if err != nil {
		return "", err
	}
	token := r.Form.Get("token")
	return token, err
}
