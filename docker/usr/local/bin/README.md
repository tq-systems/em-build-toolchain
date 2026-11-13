# Scripts

Scripts copied to /usr/local/bin of every image. Unit tests lie next to their script as test_*.py
and stay out of the images like the Markdown files, see .dockerignore. A test runs on its own:

    ./docker/usr/local/bin/test_sbom.py

| Script | Purpose |
|---|---|
| git-helper.sh | Git helper functions for the build scripts |
| sbom.py | Merges the app SBOMs of a bundle and the core image SBOM into one CycloneDX file, used by the sbom target of the bundles |
