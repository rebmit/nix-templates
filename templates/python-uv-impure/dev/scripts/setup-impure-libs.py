#!/usr/bin/env python3
#
# Portions of this file are sourced from
# https://github.com/albertz/system-tools/blob/bb8dc1bae9fa9c32f47a18e3787064a526c1f788/bin/find-lib-in-path.py
# https://github.com/numtide/nix-gl-host/blob/5269b233f83880a0b433eafe026f0bc0d8f1a4a9/src/nixglhost.py (Apache License 2.0)

import argparse
import os
import re
import shutil
import sys
import uuid
from glob import glob
from typing import Dict, List, Optional, Set


class ResolvedLib:
    def __init__(
        self,
        name: str,
        dirpath: str,
        fullpath: str,
        last_modification: Optional[float] = None,
        size: Optional[int] = None,
    ):
        self.name: str = name
        self.dirpath: str = dirpath
        self.fullpath: str = fullpath
        if size is None or last_modification is None:
            stat = os.stat(fullpath)
            self.last_modification: float = stat.st_mtime
            self.size: int = stat.st_size
        else:
            self.last_modification = last_modification
            self.size = size

    def __repr__(self):
        return f"ResolvedLib<{self.name}, {self.dirpath}, {self.fullpath}, {self.last_modification}, {self.size}>"

    def to_dict(self) -> Dict:
        return {
            "name": self.name,
            "dirpath": self.dirpath,
            "fullpath": self.fullpath,
            "last_modification": self.last_modification,
            "size": self.size,
        }

    def __hash__(self):
        return hash(
            (self.name, self.dirpath, self.fullpath, self.last_modification, self.size)
        )

    def __eq__(self, o):
        return (
            self.name == o.name
            and self.fullpath == o.fullpath
            and self.dirpath == o.dirpath
            and self.last_modification == o.last_modification
            and self.size == o.size
        )

    @classmethod
    def from_dict(cls, d: Dict):
        return ResolvedLib(
            d["name"], d["dirpath"], d["fullpath"], d["last_modification"], d["size"]
        )


def parse_ld_conf_file(fn: str) -> List[str]:
    paths = []
    for line in open(fn).read().splitlines():
        line = line.strip()
        if not line:
            continue
        if line.startswith("#"):
            continue
        if line.startswith("include "):
            dirglob = line[len("include ") :]
            if dirglob[0] != "/":
                dirglob = os.path.dirname(os.path.normpath(fn)) + "/" + dirglob
            for sub_fn in glob(dirglob):
                paths.extend(parse_ld_conf_file(sub_fn))
            continue
        paths.append(line)
    return paths


def get_ld_paths() -> List[str]:
    LDPATH = os.getenv("LD_LIBRARY_PATH")
    paths = []
    if LDPATH:
        paths.extend(LDPATH.split(":"))
    if os.path.exists("/etc/ld.so.conf"):
        paths.extend(parse_ld_conf_file("/etc/ld.so.conf"))
    paths.extend(["/lib", "/usr/lib", "/lib64", "/usr/lib64", "/run/opengl-driver/lib"])
    return [path for path in paths if os.path.isdir(path)]


def resolve_libraries(path: str, files_patterns: List[str]) -> List[ResolvedLib]:
    libraries: List[ResolvedLib] = []

    def is_dso_matching_pattern(filename):
        for pattern in files_patterns:
            if re.search(pattern, filename):
                return True
        return False

    try:
        for fname in os.listdir(path):
            abs_file_path = os.path.abspath(os.path.join(path, fname))
            if os.path.isfile(abs_file_path) and is_dso_matching_pattern(abs_file_path):
                libraries.append(
                    ResolvedLib(name=fname, dirpath=path, fullpath=abs_file_path)
                )
    except PermissionError as err:
        print(f"WARNING: {err}", file=sys.stderr)
    return libraries


def link_libraries(libraries: List[ResolvedLib], target_dir: str):
    parent = os.path.dirname(os.path.abspath(target_dir))
    next_dir = os.path.join(parent, f"lib-{str(uuid.uuid4())}")
    os.makedirs(next_dir, exist_ok=True)

    seen: Set[str] = set()
    for lib in libraries:
        if lib.name in seen:
            continue
        seen.add(lib.name)
        dst = os.path.join(next_dir, lib.name)
        os.symlink(lib.fullpath, dst)

    tmp_link = os.path.join(parent, f"link-{str(uuid.uuid4())}")
    os.symlink(next_dir, tmp_link)

    old_dir: Optional[str] = None
    if os.path.lexists(target_dir):
        try:
            old_dir = os.path.abspath(os.readlink(target_dir))
        except OSError:
            old_dir = None
        os.replace(tmp_link, target_dir)
    else:
        os.rename(tmp_link, target_dir)

    if old_dir and os.path.exists(old_dir) and old_dir != next_dir:
        try:
            shutil.rmtree(old_dir)
        except Exception as e:
            print(
                f"WARNING: failed to remove old lib dir {old_dir}: {e}", file=sys.stderr
            )


def main(args):
    dsos_paths: List[str] = get_ld_paths()
    found_libs: List[ResolvedLib] = []
    for path in dsos_paths:
        found_libs.extend(resolve_libraries(path, args.pattern))
    link_libraries(found_libs, args.target_dir)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-p",
        "--pattern",
        action="append",
        required=True,
        help="regex pattern to match library names",
    )
    parser.add_argument(
        "-t",
        "--target-dir",
        required=True,
        help="directory where symlinks will be created",
    )
    args = parser.parse_args()
    main(args)
