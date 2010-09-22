class ConvertToInnodb < ActiveRecord::Migration
  TABLES = [:bugs, :comments, :cpes, :cpes_cves, :cve_assignments, :cve_changes, :cve_comments, :cve_references, :cves, :glsas, :packages, :references, :revisions, :sessions, :users]
  def self.up
    TABLES.each { |table|
        ActiveRecord::Migration::say "Converting table #{table} to InnoDB engine"
        execute("ALTER TABLE #{table.to_s} TYPE = InnoDB")
    }
  end

  def self.down
    TABLES.each { |table|
        ActiveRecord::Migration::say "Converting table #{table} to MyISAM engine"
        execute("ALTER TABLE #{table.to_s} TYPE = MyISAM")
    }
  end
end
