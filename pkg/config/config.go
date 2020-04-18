package config

import "os"

func PostgresUser() string {
	return getEnv("GLSAMAKER_POSTGRES_USER", "root")
}

func PostgresPass() string {
	return getEnv("GLSAMAKER_POSTGRES_PASS", "root")
}

func PostgresDb() string {
	return getEnv("GLSAMAKER_POSTGRES_DB", "glsamaker")
}

func PostgresHost() string {
	return getEnv("GLSAMAKER_POSTGRES_HOST", "db")
}

func PostgresPort() string {
	return getEnv("GLSAMAKER_POSTGRES_PORT", "5432")
}

func Debug() string {
	return getEnv("GLSAMAKER_DEBUG", "false")
}

func Quiet() string {
	return getEnv("GLSAMAKER_QUIET", "false")
}

func LogFile() string {
	return getEnv("GLSAMAKER_LOG_FILE", "/var/log/glsamaker/errors.log")
}

func Version() string {
	return getEnv("GLSAMAKER_VERSION", "v0.1.0")
}

func Port() string {
	return getEnv("GLSAMAKER_PORT", "5000")
}

func AdminEmail() string {
	return getEnv("GLSAMAKER_EMAIL", "admin@gentoo.org")
}

func AdminInitialPassword() string {
	return getEnv("GLSAMAKER_INITIAL_ADMIN_PASSWORD", "admin")
}

func CacheControl() string {
	return getEnv("GLSAMAKER_CACHE_CONTROL", "max-age=300")
}

func getEnv(key string, fallback string) string {
	if os.Getenv(key) != "" {
		return os.Getenv(key)
	} else {
		return fallback
	}
}
