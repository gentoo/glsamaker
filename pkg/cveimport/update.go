package cveimport

import (
	"glsamaker/pkg/database"
	"glsamaker/pkg/database/connection"
	"glsamaker/pkg/logger"
	"glsamaker/pkg/models"
	"glsamaker/pkg/models/cve"
	"compress/gzip"
	"encoding/json"
	"io"
	"io/ioutil"
	"net/http"
	"strconv"
)

func Update() {
	database.Connect()
	defer connection.DB.Close()

	logger.Info.Println("Start update...")
	IncrementalCVEImport()
	logger.Info.Println("Finished update...")
}

func FullUpdate() {
	database.Connect()
	defer connection.DB.Close()

	logger.Info.Println("Start full update...")
	FullCVEImport()
	logger.Info.Println("Finished full update...")
}

func IncrementalCVEImport() {
	logger.Info.Println("Start importing recent CVEs")
	importCVEs("recent")
	logger.Info.Println("Finished importing recent CVEs")
}

func FullCVEImport() {
	for i := 2002; i <= 2020; i++ {
		year := strconv.Itoa(i)
		logger.Info.Println("Import CVEs from " + year)
		importCVEs(year)
		logger.Info.Println("Finished importing recent CVEs")
	}
}

func importCVEs(year string) {
	resp, err := http.Get("https://nvd.nist.gov/feeds/json/cve/1.1/nvdcve-1.1-" + year + ".json.gz")
	if err != nil {
		logger.Error.Println("err")
		logger.Error.Println(err)
		return
	}
	defer resp.Body.Close()

	var reader io.ReadCloser
	reader, err = gzip.NewReader(resp.Body)
	defer reader.Close()

	s, _ := ioutil.ReadAll(reader)

	var data cve.NVDFeed

	err = json.Unmarshal([]byte(s), &data)

	if err != nil {
		logger.Info.Println("ERROR during unmarshal:")
		logger.Info.Println(err)
	}

	for _, cveitem := range data.CVEItems {
		cveitem.Id = cveitem.Cve.CVEDataMeta.ID
		cveitem.State = "New"

		description := ""
		for _, langstring := range cveitem.Cve.Description.DescriptionData {
			if langstring.Lang == "en" {
				description = langstring.Value
			}
		}
		cveitem.Description = description

		_, err := connection.DB.Model(cveitem).OnConflict("(id) DO UPDATE").Insert()
		if err != nil {
			logger.Error.Println("Err during CVE insert")
			logger.Error.Println(err)
		}
	}

	// update the time of the last bug update
	models.SetApplicationValue("LastCVEUpdate", "")

}
