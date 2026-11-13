#!/usr/bin/env python3
#
# Copyright (c) 2026 TQ-Systems GmbH <license@tq-group.com>, D-82229 Seefeld, Germany. All rights reserved.
# Author: Hans-Christian Melzer and the Energy Manager development team
#
# This software is licensed under the TQ-Systems Product Software License Agreement Version 1.0.3 or any later version.
# You can obtain a copy of the License Agreement in the TQS (TQ-Systems Software Licenses) folder on the following website:
# https://www.tq-group.com/en/support/downloads/tq-software-license-conditions/
# In case of any license issues please contact license@tq-group.com.
#
"""Tests of docker/usr/local/bin/sbom.py with SBOM fixtures, no real bundle needed."""
import io
import json
import pathlib
import sys
import tarfile

import pytest

import sbom  # pylint: disable=import-error

CORE_SBOM = {"components": [{
    "type": "library", "name": "busybox", "version": "1.36.1", "group": "core",
    "purl": "pkg:generic/busybox@1.36.1", "supplier": {"name": "BusyBox"},
    "properties": [{"name": "SRCREV", "value": "deadbeef"}]}]}


def app_sbom(*purls, version=None):
    """Returns an app SBOM with one library component per purl."""
    doc = {"components": [{"type": "library", "name": purl.split("/")[-1], "purl": purl}
                          for purl in purls]}
    if version:
        doc["metadata"] = {"component": {"version": version}}
    return doc


def dependencies(merged):
    """Returns the dependency section as dict ref -> dependsOn."""
    return {dep["ref"]: dep["dependsOn"] for dep in merged["dependencies"]}


def test_merge_builds_bundle_app_and_os_layers():
    apps = {
        "flow-control": [app_sbom("pkg:golang/x/net@0.29", version="3.1.0"),
                         app_sbom("pkg:npm/vue@3.4")],
        "backup": [app_sbom("pkg:golang/x/net@0.29")],
    }
    merged, missing = sbom.merge(apps, CORE_SBOM)

    assert missing == []
    deps = dependencies(merged)
    assert deps["emos-bundle-root"] == [
        "pkg:emos-app/backup", "pkg:emos-app/flow-control", "pkg:emos-os/core-image"]
    assert deps["pkg:emos-app/flow-control"] == ["pkg:golang/x/net@0.29", "pkg:npm/vue@3.4"]
    assert deps["pkg:emos-app/backup"] == ["pkg:golang/x/net@0.29"]
    assert deps["pkg:emos-os/core-image"] == ["pkg:generic/busybox@1.36.1"]

    purls = [component.get("purl") for component in merged["components"]]
    assert purls.count("pkg:golang/x/net@0.29") == 1
    by_name = {component["name"]: component for component in merged["components"]}
    assert by_name["flow-control"]["version"] == "3.1.0"
    assert by_name["busybox"]["group"] == "core"
    assert by_name["busybox"]["properties"] == CORE_SBOM["components"][0]["properties"]
    assert "supplier" not in by_name["busybox"]


def test_app_without_sbom_is_reported_by_name():
    merged, missing = sbom.merge({"presets": [], "backup": [app_sbom("pkg:npm/vue@3.4")]},
                                 CORE_SBOM)
    sbom.add_metadata(merged, "11.0.0", "em-aarch64/tq-embase", missing)

    assert missing == ["presets"]
    assert "pkg:emos-app/presets" not in dependencies(merged)["emos-bundle-root"]
    assert merged["metadata"]["component"]["version"] == "11.0.0"
    assert merged["serialNumber"].startswith("urn:uuid:")
    assert merged["properties"] == [
        {"name": "emos.compatible", "value": "em-aarch64/tq-embase"},
        {"name": "emos.apps_without_sbom", "value": "presets"}]


def test_excluded_purls_leave_components_and_dependencies():
    apps = {"backup": [app_sbom("pkg:golang/git.example.com/libs/x@1.0", "pkg:npm/vue@3.4")]}
    merged, _ = sbom.merge(apps, CORE_SBOM, ["git.example.com"])

    assert "git.example.com" not in json.dumps(merged)
    assert dependencies(merged)["pkg:emos-app/backup"] == ["pkg:npm/vue@3.4"]


def add_file(tar, name, content=b""):
    """Adds a file to a tar archive under construction."""
    info = tarfile.TarInfo(name)
    info.size = len(content)
    tar.addfile(info, io.BytesIO(content))


def test_rootfs_tar_without_compression_holds_the_apps(tmp_path):
    rootfs = tmp_path / "rootfs.tar"
    with tarfile.open(rootfs, "w") as tar:
        add_file(tar, "./opt/apps/backup/manifest.json", b"{}")
        add_file(tar, "./opt/apps/backup/sbom/backup.go-sbom.json",
                 json.dumps(app_sbom("pkg:npm/vue@3.4")).encode())
        add_file(tar, "./opt/apps/presets/manifest.json", b"{}")

    app_sboms, apps_image = sbom.read_rootfs_tar(str(rootfs), str(tmp_path / "work"))

    assert apps_image is None
    assert app_sboms == {"opt/apps/backup": [app_sbom("pkg:npm/vue@3.4")], "opt/apps/presets": []}


def test_rootfs_tar_with_compression_holds_the_apps_image(tmp_path):
    rootfs = tmp_path / "rootfs.tar"
    with tarfile.open(rootfs, "w") as tar:
        add_file(tar, "./opt/apps.squashfs", b"squashfs")
        add_file(tar, "./opt/uncompressed-app/sbom/app.go-sbom.json",
                 json.dumps(app_sbom("pkg:golang/example@1.0")).encode())

    app_sboms, apps_image = sbom.read_rootfs_tar(str(rootfs), str(tmp_path / "work"))

    assert app_sboms == {"opt/uncompressed-app": [app_sbom("pkg:golang/example@1.0")]}
    assert pathlib.Path(apps_image).read_bytes() == b"squashfs"


def test_rootfs_tar_is_the_em_image_archive(tmp_path):
    for name in ("customer-data.tar", "em-image-embase-em-aarch64.tar.xz"):
        (tmp_path / name).touch()

    rootfs = sbom.find_rootfs_tar(str(tmp_path))

    assert rootfs == str(tmp_path / "em-image-embase-em-aarch64.tar.xz")


def test_apps_dir_reports_apps_without_sbom(tmp_path):
    sbom_dir = tmp_path / "backup" / "sbom"
    sbom_dir.mkdir(parents=True)
    (sbom_dir / "backup.go-sbom.json").write_text(json.dumps(app_sbom("pkg:npm/vue@3.4")))
    (tmp_path / "presets").mkdir()
    # emit links an uncompressed app out of the apps image to opt/<app> of the root file system
    (tmp_path / "uncompressed-app").symlink_to("../uncompressed-app")
    rootfs_sboms = {"opt/uncompressed-app": [app_sbom("pkg:golang/example@1.0")]}

    assert sbom.read_apps_dir(str(tmp_path), rootfs_sboms) == {
        "backup": [app_sbom("pkg:npm/vue@3.4")], "presets": [],
        "uncompressed-app": [app_sbom("pkg:golang/example@1.0")]}


def run_main(tmp_path, core_sbom):
    """Runs the script against the bundle directory tmp_path/bin."""
    sbom.main(["--bundle-dir", str(tmp_path / "bin"), "--core-image-sbom", str(core_sbom),
               "--output-dir", str(tmp_path / "doc"), "--work-dir", str(tmp_path / "work")])


def test_missing_bundle_aborts(tmp_path):
    (tmp_path / "bin").mkdir()
    with pytest.raises(SystemExit, match="no .raucb file"):
        run_main(tmp_path, tmp_path / "core.json")


def test_missing_core_image_sbom_aborts(tmp_path):
    (tmp_path / "bin").mkdir()
    (tmp_path / "bin" / "demo-devel-hw02xx-latest.raucb").write_bytes(b"")
    with pytest.raises(SystemExit, match="core image SBOM not found"):
        run_main(tmp_path, tmp_path / "core.json")


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-q", "-p", "no:cacheprovider"]))
