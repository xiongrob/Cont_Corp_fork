"""
mania2json: A Python library for parsing osu!mania 4k beatmap files

This package provides tools for parsing osu!mania 4k beatmap (.osu) files and
extracting all information such as metadata, difficulty settings,
hit objects, and timing points.

Classes:
    mania_file_parser: Parse individual .osu files
    mania_mapset_parser: Parse entire directories of mapsets
"""

from .core import mania_file_parser, mania_mapset_parser

__version__ = "0.1.0"
__author__ = "glassive"
__email__ = "workingofpatch@gmail.com"

__all__ = ["mania_file_parser", "mania_mapset_parser"]
