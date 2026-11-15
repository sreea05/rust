// Runs after cargo-generate creates a project. Files that would clash with
// the template repository's own files are stored under other names and
// moved into place here.
file::rename("LICENSE.project", "LICENSE");
file::rename(".github-project", ".github");
