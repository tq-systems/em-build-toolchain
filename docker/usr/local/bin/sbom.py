#!/opt/venv/bin/python3
#
# Copyright (c) 2024-2026 TQ-Systems GmbH <license@tq-group.com>, D-82229 Seefeld, Germany. All rights reserved.
# Author: Hans-Christian Melzer and the Energy Manager development team
#
# This software is licensed under the TQ-Systems Product Software License Agreement Version 1.0.3 or any later version.
# You can obtain a copy of the License Agreement in the TQS (TQ-Systems Software Licenses) folder on the following website:
# https://www.tq-group.com/en/support/downloads/tq-software-license-conditions/
# In case of any license issues please contact license@tq-group.com.
#
"""Merges the SBOMs of the apps in a RAUC bundle and the SBOM of the core image into one
CycloneDX file per bundle, with the layers bundle, apps and operating system.

The script creates no SBOM itself. It reads the app SBOMs shipped inside the bundle and the
core image SBOM given on the command line.
"""
import argparse
import datetime
import json
import os
import shutil
import subprocess
import sys
import tarfile

SPEC_VERSION = "1.6"
BUNDLE_NAME = "EMOS Bundle"
ROOT_BOM_REF = "emos-bundle-root"
APP_PURL_PREFIX = "pkg:emos-app/"
OS_BOM_REF = "pkg:emos-os/core-image"
ROOTFS_TAR_PREFIX = "em-image-"
OPT_DIR = "opt/"
APPS_DIR = "opt/apps/"
APPS_IMAGE = "opt/apps.squashfs"
SBOM_SUFFIX = "bom.json"
MERGED_COMPONENT_FIELDS = (
    "type", "group", "cpe", "name", "version", "purl", "licenses", "properties")
CPE_PART_TYPES = {"a": "generic", "o": "os", "h": "hardware"}


class SbomError(Exception):
    """An error that aborts the run with a message instead of a traceback."""


def read_manifest(bundle_dir):
    """Returns the version and compatible entries of the RAUC manifest."""
    values = {}
    with open(os.path.join(bundle_dir, "manifest.raucm"), encoding="utf-8") as manifest:
        for line in manifest:
            key, _, value = line.strip().partition("=")
            values[key] = value.strip()
    return values.get("version"), values.get("compatible")


def find_rootfs_tar(bundle_dir):
    """Returns the root file system archive of an extracted RAUC bundle.

    A bundle can hold further archives, the root file system is the one emit names em-image-*.
    """
    for name in sorted(os.listdir(bundle_dir)):
        if name.startswith(ROOTFS_TAR_PREFIX) and name.endswith((".tar", ".tar.xz")):
            return os.path.join(bundle_dir, name)
    raise SbomError(f"no root file system archive in {bundle_dir}")


def read_rootfs_tar(tar_path, work_dir):
    """Collects the SBOMs below opt from the root file system archive of a bundle.

    Without compression the apps lie below opt/apps. With compression they lie in
    opt/apps.squashfs, which is extracted to work_dir and returned as second value. An app that
    emit installs uncompressed lies below opt/<app>, the apps image links to it.

    Returns:
        tuple: (dict app directory like opt/apps/<app> -> list of SBOM documents,
                path of the apps image or None)
    """
    app_sboms = {}
    apps_image = None
    with tarfile.open(tar_path) as tar:
        for member in tar:
            name = os.path.normpath(member.name)
            if name == APPS_IMAGE:
                tar.extract(member, work_dir, filter="data")
                apps_image = os.path.join(work_dir, APPS_IMAGE)
            elif name.startswith(OPT_DIR):
                depth = 3 if name.startswith(APPS_DIR) else 2
                docs = app_sboms.setdefault("/".join(name.split("/")[:depth]), [])
                if member.isfile() and name.endswith(SBOM_SUFFIX):
                    docs.append(json.load(tar.extractfile(member)))
    return app_sboms, apps_image


def read_apps_dir(apps_dir, rootfs_sboms):
    """Collects the app SBOMs below an extracted apps image, one top-level entry per app.

    An app that emit installs uncompressed is a symlink to opt/<app> of the root file system,
    its SBOMs come from rootfs_sboms.
    """
    app_sboms = {}
    for app in sorted(os.listdir(apps_dir)):
        app_path = os.path.join(apps_dir, app)
        if os.path.islink(app_path):
            target = os.path.normpath(os.path.join(APPS_DIR, os.readlink(app_path)))
            app_sboms[app] = rootfs_sboms.get(target, [])
            continue
        docs = app_sboms[app] = []
        for root, dirs, files in os.walk(app_path):
            dirs.sort()
            for name in sorted(files):
                if name.endswith(SBOM_SUFFIX):
                    with open(os.path.join(root, name), encoding="utf-8") as sbom_file:
                        docs.append(json.load(sbom_file))
    return app_sboms


def extract_bundle(raucb_path, work_dir):
    """Extracts a RAUC bundle and returns its version, compatible and the app SBOMs."""
    bundle_dir = os.path.join(work_dir, "bundle")
    subprocess.run(["unsquashfs", "-q", "-no-progress", "-d", bundle_dir, raucb_path], check=True)
    version, compatible = read_manifest(bundle_dir)
    rootfs_sboms, apps_image = read_rootfs_tar(find_rootfs_tar(bundle_dir), work_dir)
    if not apps_image:
        return version, compatible, {path[len(APPS_DIR):]: docs for path, docs
                                     in rootfs_sboms.items() if path.startswith(APPS_DIR)}
    apps_dir = os.path.join(work_dir, "apps")
    subprocess.run(["unsquashfs", "-q", "-no-progress", "-d", apps_dir, apps_image], check=True)
    return version, compatible, read_apps_dir(apps_dir, rootfs_sboms)


def cpe_to_purl(cpe, version):
    """Converts a CPE 2.3 string to a package URL."""
    # Imported here, the unit tests run in an image without packageurl-python
    from packageurl import PackageURL  # pylint: disable=import-outside-toplevel,import-error
    parts = cpe.split(":")
    if len(parts) < 5 or parts[0] != "cpe" or parts[1] != "2.3":
        raise ValueError(f"invalid CPE {cpe}")
    vendor, product = parts[3], parts[4]
    purl_type = CPE_PART_TYPES.get(parts[2], "generic")
    namespace = vendor if vendor != product else None
    return str(PackageURL(type=purl_type, namespace=namespace, name=product, version=version))


def missing_purl(component):
    """Derives a package URL for a component without one, from its CPE or its type and name."""
    from packageurl import PackageURL  # pylint: disable=import-outside-toplevel,import-error
    if component.get("cpe"):
        try:
            return cpe_to_purl(component["cpe"], component.get("version"))
        except ValueError as exc:
            print(f"warning: {exc}", file=sys.stderr)
            return None
    return str(PackageURL(type=component.get("type"), name=component.get("name"),
                          version=component.get("version")))


class BundleSbom:
    """Builds the merged SBOM. The purl of a component doubles as its bom-ref."""

    def __init__(self, exclude_purls):
        self.exclude_purls = exclude_purls
        self.components = []
        self.dependencies = []
        self.root_refs = []
        self.seen_purls = set()

    def add_layer(self, layer, sbom_docs):
        """Adds a layer component (app or operating system) and the components of its SBOMs."""
        self.components.append(layer)
        self.root_refs.append(layer["bom-ref"])
        refs = []
        for doc in sbom_docs:
            for source in doc.get("components", []):
                component = {key: source[key] for key in MERGED_COMPONENT_FIELDS if key in source}
                if "purl" not in component:
                    purl = missing_purl(component)
                    if purl:
                        component["purl"] = purl
                purl = component.get("purl")
                if purl and any(text in purl for text in self.exclude_purls):
                    continue
                if purl:
                    component["bom-ref"] = purl
                    if purl not in refs:
                        refs.append(purl)
                    if purl in self.seen_purls:
                        continue
                    self.seen_purls.add(purl)
                self.components.append(component)
        if refs:
            self.dependencies.append({"ref": layer["bom-ref"], "dependsOn": refs})

    def document(self):
        """Returns the merged CycloneDX document."""
        return {
            "bomFormat": "CycloneDX",
            "specVersion": SPEC_VERSION,
            "version": 1,
            "metadata": {
                "component": {"type": "firmware", "name": BUNDLE_NAME, "bom-ref": ROOT_BOM_REF}
            },
            "components": self.components,
            "dependencies": [{"ref": ROOT_BOM_REF, "dependsOn": self.root_refs}]
            + self.dependencies,
        }


def merge(app_sboms, core_sbom, exclude_purls=()):
    """Merges the app SBOMs and the core image SBOM.

    Args:
        app_sboms (dict): app name -> list of SBOM documents, an empty list marks a gap
        core_sbom (dict): SBOM document of the core image
        exclude_purls (iterable): components whose purl contains one of these texts are dropped

    Returns:
        tuple: (merged document, sorted names of the apps without SBOM)
    """
    bundle = BundleSbom(tuple(exclude_purls))
    for app in sorted(name for name, docs in app_sboms.items() if docs):
        docs = app_sboms[app]
        layer = {"type": "application", "name": app,
                 "bom-ref": APP_PURL_PREFIX + app, "purl": APP_PURL_PREFIX + app}
        # The frontend SBOM of an app carries no version, the backend SBOM does
        version = next((doc["metadata"]["component"]["version"] for doc in docs
                        if doc.get("metadata", {}).get("component", {}).get("version")), None)
        if version:
            layer["version"] = version
        bundle.add_layer(layer, docs)
    bundle.add_layer({"type": "operating-system", "name": "core-image",
                      "bom-ref": OS_BOM_REF, "purl": OS_BOM_REF}, [core_sbom])
    return bundle.document(), sorted(name for name, docs in app_sboms.items() if not docs)


def license_names(component):
    """Yields the license ids and expressions of a component."""
    for entry in component.get("licenses", []):
        if "expression" in entry:
            yield entry["expression"]
        elif "id" in entry.get("license", {}):
            yield entry["license"]["id"]


def add_properties(sbom, version, compatible, missing_apps):
    """Adds generation data and statistics as CycloneDX properties."""
    components = sbom["components"]
    type_stats, purl_stats, license_stats = {}, {}, {}
    for component in components:
        component_type = component.get("type", "unknown")
        type_stats[component_type] = type_stats.get(component_type, 0) + 1
        purl = component.get("purl", "")
        if purl.startswith("pkg:"):
            purl_type = purl.split(":")[1].split("/")[0]
            purl_stats[purl_type] = purl_stats.get(purl_type, 0) + 1
        for name in license_names(component):
            license_stats[name] = license_stats.get(name, 0) + 1
    app_counts = {dep["ref"][len(APP_PURL_PREFIX):]: len(dep["dependsOn"])
                  for dep in sbom["dependencies"] if dep["ref"].startswith(APP_PURL_PREFIX)}

    properties = [
        ("sbom.generated", datetime.datetime.now(datetime.timezone.utc)
         .strftime("%Y-%m-%dT%H:%M:%S.%fZ")),
        ("sbom.generator", "sbom.py v2.0"),
        ("sbom.tools", "cyclonedx-gomod,yarn,npm,unsquashfs"),
        ("emos.version", version),
        ("emos.compatible", compatible),
        ("emos.apps_without_sbom", ",".join(missing_apps)),
        ("statistics.total_components", len(components)),
        ("statistics.total_dependencies", len(sbom["dependencies"])),
        ("statistics.total_applications", type_stats.get("application", 0)),
        ("statistics.total_libraries", type_stats.get("library", 0)),
        ("statistics.unique_licenses", len(license_stats)),
    ]
    properties += [(f"statistics.components_by_type.{name}", count)
                   for name, count in sorted(type_stats.items())]
    properties += [(f"statistics.components_by_package.{name}", count)
                   for name, count in sorted(purl_stats.items())]
    properties += [(f"statistics.app_components.{name}", count) for name, count in
                   sorted(app_counts.items(), key=lambda item: item[1], reverse=True)[:5]]
    properties += [(f"statistics.licenses.{name}", count) for name, count in
                   sorted(license_stats.items(), key=lambda item: item[1], reverse=True)[:10]]
    sbom["properties"] = [{"name": name, "value": str(value)}
                          for name, value in properties if value not in (None, "")]


def validate(sbom):
    """Raises SbomError if the document is not valid CycloneDX 1.6."""
    # pylint: disable=import-outside-toplevel,import-error
    from cyclonedx.schema import SchemaVersion
    from cyclonedx.validation.json import JsonStrictValidator
    errors = JsonStrictValidator(SchemaVersion.V1_6).validate_str(json.dumps(sbom))
    if errors:
        raise SbomError(f"merged SBOM is not valid CycloneDX {SPEC_VERSION}: {errors!r}")


def report(sbom, missing_apps, output_file):
    """Prints a summary and the findings that need a look."""
    components = sbom["components"]
    print(f"{output_file}: {len(components)} components")
    if missing_apps:
        print(f"warning: apps without SBOM: {', '.join(missing_apps)}", file=sys.stderr)
    for label, matches in (
            ("components without purl", [c for c in components if "purl" not in c]),
            ("components with version UNKNOWN",
             [c for c in components if c.get("version") == "UNKNOWN"])):
        if matches:
            names = ", ".join(c.get("name", "?") for c in matches)
            print(f"warning: {label}: {names}", file=sys.stderr)


def main(argv=None):
    """Writes one merged SBOM per bundle in the bundle directory."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bundle-dir", required=True, help="directory with the .raucb files")
    parser.add_argument("--core-image-sbom", required=True, help="CycloneDX SBOM of the core image")
    parser.add_argument("--output-dir", required=True, help="directory for <bundle>-sbom.json")
    parser.add_argument("--work-dir", required=True, help="scratch directory, emptied per bundle")
    parser.add_argument("--exclude-purl", action="append", default=[], metavar="TEXT",
                        help="drop components whose purl contains TEXT (repeatable)")
    args = parser.parse_args(argv)

    try:
        for name in ("bundle_dir", "core_image_sbom", "output_dir", "work_dir"):
            if not getattr(args, name):
                raise SbomError(f"--{name.replace('_', '-')} is empty")
        if not os.path.isdir(args.bundle_dir):
            raise SbomError(f"bundle directory not found: {args.bundle_dir}")
        bundles = sorted(n for n in os.listdir(args.bundle_dir) if n.endswith(".raucb"))
        if not bundles:
            raise SbomError(f"no .raucb file in {args.bundle_dir}")
        if not os.path.isfile(args.core_image_sbom):
            raise SbomError(f"core image SBOM not found: {args.core_image_sbom}")
        with open(args.core_image_sbom, encoding="utf-8") as core_file:
            core_sbom = json.load(core_file)

        os.makedirs(args.output_dir, exist_ok=True)
        for raucb in bundles:
            bundle_name = os.path.splitext(raucb)[0]
            work_dir = os.path.join(args.work_dir, bundle_name)
            shutil.rmtree(work_dir, ignore_errors=True)
            os.makedirs(work_dir)
            version, compatible, app_sboms = extract_bundle(
                os.path.join(args.bundle_dir, raucb), work_dir)
            sbom, missing_apps = merge(app_sboms, core_sbom, args.exclude_purl)
            add_properties(sbom, version, compatible, missing_apps)
            validate(sbom)
            output_file = os.path.join(args.output_dir, bundle_name + "-sbom.json")
            with open(output_file, "w", encoding="utf-8") as output:
                json.dump(sbom, output, indent=4)
            report(sbom, missing_apps, output_file)
    except (SbomError, OSError, ValueError, tarfile.TarError,
            subprocess.CalledProcessError) as exc:
        sys.exit(f"error: {exc}")


if __name__ == "__main__":
    main()
