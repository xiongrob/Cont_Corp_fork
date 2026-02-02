import json

# Path to your .osu file
# osu_file_path = r'G:\My Drive\3. Personal\rhythm_test\osu beatmap\Yunosuke - Kimi wo Mitai (Guest) [Test diff].osu'
# Modified to relative pathing. That way the file path is platform independent.
osu_file_path = r'./osu beatmap/Yunosuke - Kimi wo Mitai [4k].osu'

# Initialize data structures
hit_objects = []
metadata = {}
general = {}
difficulty = {}

# Read and parse the file
with open(osu_file_path, 'r', encoding='utf-8') as f:
    current_section = None
    
    for line in f:
        line = line.strip()
        
        # Skip empty lines
        if not line:
            continue
        
        # Check for section headers
        if line.startswith('[') and line.endswith(']'):
            current_section = line[1:-1]
            continue
        
        # Parse based on current section
        if current_section == 'Metadata' and ':' in line:
            key, value = line.split(':', 1)
            metadata[key] = value.strip()
        
        elif current_section == 'General' and ':' in line:
            key, value = line.split(':', 1)
            general[key] = value.strip()
        
        elif current_section == 'Difficulty' and ':' in line:
            key, value = line.split(':', 1)
            difficulty[key] = value.strip()
        
        elif current_section == 'HitObjects':
            # Parse hit object line: x,y,time,type,hitSound,endTime:...
            parts = line.split(',')
            if len(parts) >= 5:
                x = int(parts[0])
                time = int(float(parts[2]))
                obj_type = int(parts[3])
                
                # Convert X position to lane (0-3)
                # This map uses: 0, 128, 256, 384
                # Calculate lane based on 128-unit spacing
                lane = x // 128
                lane = min(3, max(0, lane))  # Clamp to 0-3
                
                note = {
                    'x': lane,
                    'time': time
                }
                
                # Check if it's a hold note (type & 128)
                if obj_type & 128:
                    note['type'] = 'hold'
                    # End time is in the last part
                    if len(parts) >= 6:
                        end_time_str = parts[5].split(':')[0]
                        note['end_time'] = int(float(end_time_str))
                else:
                    note['type'] = 'note'
                
                hit_objects.append(note)

# Build the final JSON structure
result = {
    'title': metadata.get('Title', 'Unknown'),
    'artist': metadata.get('Artist', 'Unknown'),
    'audio_filename': general.get('AudioFilename', 'audio.mp3'),
    'mode': int(general.get('Mode', 3)),
    'circle_size': int(difficulty.get('CircleSize', 4)),
    'hit_objects': hit_objects
}

# Save to JSON
# output_path = r'G:\My Drive\3. Personal\Rhythm Game\output.json'
# Modified to relative pathing. That way the file path is platform independent.
output_path = r'./output.json'
with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(result, f, indent=2, ensure_ascii=False)

print(f"✓ Conversion complete!")
print(f"✓ Saved to: {output_path}")
print(f"\nMap Info:")
print(f"  Title: {result['title']}")
print(f"  Artist: {result['artist']}")
print(f"  Audio: {result['audio_filename']}")
print(f"  Total Notes: {len(hit_objects)}")

# Count notes per lane
lane_counts = [0, 0, 0, 0]
for note in hit_objects:
    lane_counts[note['x']] += 1

print(f"\nNotes per lane:")
print(f"  Lane 0 (Q): {lane_counts[0]} notes")
print(f"  Lane 1 (P): {lane_counts[1]} notes")
print(f"  Lane 2 (Z): {lane_counts[2]} notes")
print(f"  Lane 3 (M): {lane_counts[3]} notes")

print(f"\nFirst 10 notes:")
for i, note in enumerate(hit_objects[:10]):
    lane_names = ['Q', 'P', 'Z', 'M']
    hold_info = f" -> {note['end_time']}ms" if note['type'] == 'hold' else ""
    print(f"  {i+1}. Lane {note['x']} ({lane_names[note['x']]}): {note['time']}ms{hold_info}")
