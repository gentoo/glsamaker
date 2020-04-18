package cve

// CVE
type CVE struct {
	Affects     *Affects     `json:"affects,omitempty"`
	CVEDataMeta *CVEDataMeta `json:"CVE_data_meta"`
	DataFormat  string       `json:"data_format"`
	DataType    string       `json:"data_type"`
	DataVersion string       `json:"data_version"`
	Description *Description `json:"description"`
	Problemtype *Problemtype `json:"problemtype"`
	References  *References  `json:"references"`
}

// Affects
type Affects struct {
	Vendor *Vendor `json:"vendor"`
}

// CVEDataMeta
type CVEDataMeta struct {
	ASSIGNER string `json:"ASSIGNER"`
	ID       string `json:"ID"`
	STATE    string `json:"STATE,omitempty"`
}

// Description
type Description struct {
	DescriptionData []*LangString `json:"description_data"`
}

// LangString
type LangString struct {
	Lang  string `json:"lang"`
	Value string `json:"value"`
}

// Problemtype
type Problemtype struct {
	ProblemtypeData []*ProblemtypeDataItems `json:"problemtype_data"`
}

// ProblemtypeDataItems
type ProblemtypeDataItems struct {
	Description []*LangString `json:"description"`
}

// Product
type Product struct {
	ProductData []*Product `json:"product_data"`
}

// Reference
type Reference struct {
	Name      string   `json:"name,omitempty"`
	Refsource string   `json:"refsource,omitempty"`
	Tags      []string `json:"tags,omitempty"`
	Url       string   `json:"url"`
}

// References
type References struct {
	ReferenceData []*Reference `json:"reference_data"`
}

// Vendor
type Vendor struct {
	VendorData []*VendorDataItems `json:"vendor_data"`
}

// VendorDataItems
type VendorDataItems struct {
	Product    *Product `json:"product"`
	VendorName string   `json:"vendor_name"`
}

// Version
type Version struct {
	VersionData []*VersionDataItems `json:"version_data"`
}

// VersionDataItems
type VersionDataItems struct {
	VersionAffected string `json:"version_affected,omitempty"`
	VersionValue    string `json:"version_value"`
}
