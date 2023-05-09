from glsamaker.extensions import base, db


class Package(base):
    __tablename__ = "package"

    pkg = db.Column(db.String(), primary_key=True)

    def __init__(self, pkg):
        self.pkg = pkg

    @staticmethod
    def maybe_add_pkg(pkg):
        db.session.merge(Package(pkg))


class Affected(base):
    __tablename__ = "affected"

    range_types = {
        "=": "eq",
        ">=": "ge",
        "<=": "le",
        ">": "gt",
        "<": "lt",
        # ??
        "rge": "",
        "rgt": "",
        "rle": "",
    }
    range_types_rev = {v: k for k, v in range_types.items()}

    affected_id = db.Column(db.Integer(), primary_key=True)
    pkg = db.Column(db.ForeignKey("package.pkg"))
    # Less than, greater than, greater than-equal to, etc.
    pkg_range = db.Column(
        db.Enum("eq", "ge", "gt", "le", "lt", "rge", "rgt", "rle", name="atom_ranges")
    )
    version = db.Column(db.String())
    arch = db.Column(db.String())
    slot = db.Column(db.String())
    # The two types of package version specifiers are unaffected and
    # vulnerable, so this var has a confusing name but it just
    # indicates whether this package specification indicates an
    # unaffected range or vulnerable range
    range_type = db.Column(db.Enum("unaffected", "vulnerable", name="range_types"))

    def __init__(self, pkg, version, pkg_range, arch, slot, range_type):
        Package.maybe_add_pkg(pkg)
        self.pkg = pkg
        self.version = version
        self.pkg_range = pkg_range
        self.arch = arch
        self.slot = slot
        self.range_type = range_type

    def versioned_atom(self):
        if self.pkg_range and self.version:
            atom = self.range_types_rev[self.pkg_range]
            atom += self.pkg
            atom += "-" + self.version

            if self.slot and self.slot != "*":
                atom += ":" + self.slot

            return atom
        return str(self.pkg)
