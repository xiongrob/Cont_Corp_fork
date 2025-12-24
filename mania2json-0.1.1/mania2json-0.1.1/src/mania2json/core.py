import os
import time
import json
from concurrent.futures import ThreadPoolExecutor, as_completed

class mania_file_parser:
    """
    A class to parse osu!mania beatmap files and extract relevant information.

    The parsed data is stored as class attributes for easy access.
    
    This class is designed to handle the osu! v14 file format : https://osu.ppy.sh/wiki/Client/File_formats/osu_(file_format)
    """

    LANE_X_VALUES = [64, 192, 320, 448]
    # used to determine the lane based on x coordinate

    def __init__(self):
        self.file_path = ""
        self.general = {}
        self.editor = {}
        self.metadata = {}
        self.difficulty = {}
        self.background = {}
        # skipping most of [Events] as i don't intend to use storyboards or videos
        self.timing_points = {}
        self.colours = {}
        # [Colours] can straight up not exist and we dont need it for mania so we can ignore it
        # it is still being referenced for consistency
        self.hit_objects = {}
        self.extra = {}

    
    def full_parse(self, file_path):
        """
        Parses the entire .osu file, and populates the class attributes with parsed data.

        The class can then be used to access the parsed data directly.
        """
        self.file_path = file_path
        with open(self.file_path, "r", encoding="utf-8") as file:
            self.content = file.read()
        self.general = self.parse_key_value_pairs("General", ": ")
        self.editor = self.parse_key_value_pairs("Editor", ": ")
        self.metadata = self.parse_key_value_pairs("Metadata", ":")
        self.difficulty = self.parse_key_value_pairs("Difficulty", ":")
        self.background = self.get_background(self.split_section("Events"))
        self.timing_points = self.parse_timing_points(self.split_section("TimingPoints"))
        self.hit_objects = self.parse_hit_objects(self.split_section("HitObjects"))
        self.extra = self.get_miscellaneous_data()
        self.content = None  # clear the content to save memory after parsing


    def light_parse(self, file_path):
        """
        Parses only the essential sections of the .osu file for display purposes.

        This is used to reduce memory usage and speed up parsing when possible.
        """
        self.file_path = file_path
        with open(self.file_path, "r", encoding="utf-8") as file:
            self.content = file.read()
        self.general = self.parse_key_value_pairs("General", ": ")
        self.metadata = self.parse_key_value_pairs("Metadata", ":")
        self.difficulty = self.parse_key_value_pairs("Difficulty", ":")
        self.extra = self.get_miscellaneous_data()
        self.content = None  # clear the content to save memory after parsing



    def is_4k_map(self):
        """
        Check if this is a 4K mania map using the CircleSize value of filename as a fallback.
        """
        circle_size = self.difficulty.get('CircleSize')
        filename = self.file_path.lower()
        return True if circle_size and float(circle_size) == 4.0 or "4k" in filename else False


    def split_section(self, name):
        """
        Finds a specified section by name in the .osu file and returns a split list of its lines.
        """
        return self.content.split(f"[{name}]\n")[1].split("\n\n")[0].splitlines()


    def parse_key_value_pairs(self, section, linesep):
        """
        Parse key-value pairs from a specified section.

        This only works if the section is formatted as a key-value pair with a specified separator.
        See: https://osu.ppy.sh/wiki/en/Client/File_formats/osu_(file_format)#structure
        """
        section_content = self.split_section(section)
        return {k: v for k, v in (line.split(linesep) for line in section_content if linesep in line)}


    def parse_hit_objects(self, objects):
        """
        Parse hit objects from the HitObjects section.

        Hit object syntax: x,y,time,type,hitSound,objectParams,hitSample

        osu!mania hit objects do not use y. x is used to determine the column with arbitrary values.

        Samples and sound are ignored for now, might implement later.
        """
        objects_dict = {}
        
        for line in objects:
            split_line = line.split(",")
                
            try:
                time = float(split_line[2])
                x_coord = int(split_line[0])
                hit_object = {
                    "lane": max(0, min(x_coord // 128, 3)),
                }
                
                # this is a safety net that is never used in practice, as long as the file validation works
                if x_coord not in self.LANE_X_VALUES:
                    return {}

                if int(split_line[3]) > 1 and len(split_line) > 5:
                    try:
                        hit_object["end"] = int(split_line[5].split(":")[0])
                    except (ValueError, IndexError):
                        hit_object["end"] = str(time)

                if time not in objects_dict:
                    objects_dict[time] = []
                objects_dict[time].append(hit_object)
                
            except (ValueError, IndexError):
                continue
                
        return objects_dict
    

    def parse_timing_points(self, objects):
        """
        Parse timing points from the TimingPoints section.

        Timing point syntax: time,beatLength,meter,sampleSet,sampleIndex,volume,uninherited,effects
        """
        timing_points = {}
        for line in objects:
            split_line = line.split(",")
            timing_points[float(split_line[0])] = {
                "beat_length": float(split_line[1]),
                "meter": int(split_line[2]),
                "sample_set": int(split_line[3]),
                "sample_index": int(split_line[4]),
                "volume": int(split_line[5]),
                "uninherited": bool(int(split_line[6])),
                "effects": int(split_line[7]) if len(split_line) > 7 else 0
            }
        # can maybe refactor? might be less readable
        return timing_points
    

    def get_background(self, events):
        """
        Extract the background image file name from the Events section.

        Background syntax: 0,0,filename,xOffset,yOffset
        """
        background = {}
        if not events:
            return background
        
        for line in events:
            if not line.startswith("0,0,"):
                continue
            split_line = line.split(",")
            background = {
                "path": split_line[2].strip('\"'),
                "x_offset": int(split_line[3]),
                "y_offset": int(split_line[4])
            }
        return background
    

    def get_miscellaneous_data(self):
        """
        Extract miscellaneous data from the beatmap.
        """
        long_notes = 0
        short_notes = 0
        lanes = self.hit_objects.values()
        # each lane is a list of hit objects at that timestamp
        for lane in lanes:
            for hit_object in lane:
                if 'end' in hit_object:
                    long_notes += 1
                else:
                    short_notes += 1
        return {
            "long_note_count": long_notes,
            "short_note_count": short_notes
        }


class mania_mapset_parser:
        """
        A class to collect mania beatmapset data from a given folder.

        Returns a dictionary of parsed mania beatmaps."""

        def get_mapset_data(self, songs_directory, map_subfolder):
            """
            Collects mania beatmap data from a specific subfolder in the osu! Songs directory.
            """
            start = time.time()
            target_directory = songs_directory + map_subfolder
            dir_list = os.listdir(target_directory) if os.path.exists(target_directory) else []
            valid_files = [
                os.path.join(target_directory, file) for file in dir_list if file.endswith(".osu")
            ]
            mapset_data = {}
            for file in valid_files:
                try:
                    beatmap = mania_file_parser()
                    beatmap.full_parse(file_path=file)
                    if (beatmap.general.get('Mode') == '3' and float(beatmap.difficulty['CircleSize']) == 4.0):
                        mapset_data[f'{beatmap.metadata['Version']}'] = beatmap
                except:
                    continue
            if mapset_data:
                print(f"Found {len(mapset_data)} mania beatmaps in {(time.time() - start)*1000:.4f}ms ({target_directory.replace(songs_directory,'')})")
            return mapset_data
        

        def get_mania_mapsets_from_folder(self, directory, max_workers=8):
            """
            Collects all mania beatmapsets from the specified osu! Songs directory.

            Returns a dictionary with mapset names as keys and their data as values.
            """
            start = time.time()
            folder_list = os.listdir(directory)
            print(f"Searching {len(folder_list)} items in {directory} for mania mapsets...")
            
            mapset_data = {}
            with ThreadPoolExecutor(max_workers=max_workers) as executor:
                future_to_folder = {
                    executor.submit(self.get_mapset_data, directory, folder): folder
                    for folder in folder_list
                    if os.path.isdir(os.path.join(directory, folder))
                }
                
                for future in as_completed(future_to_folder):
                    folder = future_to_folder[future]
                    try:
                        mapset = future.result()
                        if mapset:
                            mapset_data[folder] = mapset
                    except Exception as exc:
                        print(f'Error processing {folder}: {exc}')
            
            print(f"\nFinished searching in {(time.time() - start):.4f} seconds")
            return mapset_data


        def save_mapsets_to_json(self, mapset_list, file_path="data.json"):
            """ 
            Saves mapset data to a JSON file.

            Multiple mapset can be saved in a single file, with each mapset being a key-value pair.
            """
            with open(file_path, "w") as f:
                f.write(json.dumps([{mapset_name: {k: v.__dict__ for k, v in maps.items()}} for mapset_name, maps in mapset_list.items()], indent=4, default=str))