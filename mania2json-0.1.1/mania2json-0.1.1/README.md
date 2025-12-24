# mania2json

A Python library for parsing osu!mania 4k beatmap files and extracting relevant information.

## Features

- Parse osu!mania beatmap (.osu) files
- Extract metadata, difficulty settings, hit objects, and timing points
- JSON exports

## Installation

```bash
pip install mania2json
```

## Quick Start

```python
from mania2json import mania_file_parser, mania_mapset_parser


# example use with a single file
maniap = mania_file_parser()
maniap.light_parse(file_path="xi - .357 Magnum (Akali) [4K Hyper].osu")
print(maniap.__dict__)


# example use with a songs directory
dir = "C:\\Users\\phile\\AppData\\Local\\osu!\\Songs\\" 
parser = mania_mapset_parser()  
mapset_data = parser.get_mania_mapsets_from_folder(directory=dir, max_workers=1)
print(f"Found {len(mapset_data)} mania mapsets in {dir} ({sum(len(maps) for maps in mapset_data.values())} maps)")


# save all mapsets to a single JSON file
parser.save_mapsets_to_json(mapset_data, "all_mapsets.json")


# ...or save individual mapsets in multiple files
for mapset_id, mapset_content in mapset_data.items():
    parser.save_mapsets_to_json({mapset_id: mapset_content}, f"songs\\{mapset_id}.json")
```

## API Reference

### mania_file_parser

- `full_parse(file_path)`: Parse all sections of a beatmap file
- `light_parse(file_path)`: Parse metadata-related sections only
- `is_4k_map()`: Check if the beatmap is a 4K mania map

### mania_mapset_parser

- `get_mania_mapsets_from_folder(directory, max_workers=8)`: Scan directory for mania mapsets
- `save_mapsets_to_json(data, file_path)`: Export parsed data to JSON

## Requirements

- Python 3.8+

## License

MIT License
