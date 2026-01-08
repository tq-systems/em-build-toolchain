# Introduction
Here are the Makefiles for common applications.

## Files
The following common applications exist:

| File           | Description                              |
|----------------|------------------------------------------|
| artifacts.mk   | Handling of artifacts directories        |
| deploy.mk      | Deployment of artifacts                  |
| environment.mk | Environment variables (e.g. directories) |
| version.mk     | Versioning of project artifacts          |

# Common applications
## Versioning
### Version file
The version file is created once as an artifact if it does not exist. If the
version file exists, the version is read exclusively from the file.

### Create the version
If the version file does not exist, there are 4 ways to create the VERSION
information. These are tried with the following priority:
1. Use VERSION from the project's Makefile or an argument passed to make
2. Use CI_COMMIT_TAG from the Gitlab CI
3. Use the git tag from HEAD
4. Create VERSION from git information and timestamp

### Removing the prefix from the git tag
As prefixing a semantic version with a `v` or a `V` is a common way to indicate
it is a version, these characters are removed, if the version is derived from a
git tag. So the tags `v1.0.0` and `V1.0.0` become version `1.0.0`.
