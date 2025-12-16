# GitHub Audio Libraries - Bulk Download Guide

**Date:** 2025-12-04
**Purpose:** Download entire audio libraries from GitHub repositories
**Advantage:** One git clone command gets hundreds/thousands of sounds

---

## Quick Summary

Instead of downloading individual files from Freesound/ZapSplat, you can clone entire GitHub repositories with bulk audio libraries. This is faster and gets you more sounds to choose from.

### Top 3 Recommendations

1. **Sonniss GameAudioGDC 2024** - 27.5+ GB, professional quality, royalty-free ⭐ BEST
2. **JimLynchCodes/Game-Sound-Effects** - Quick git clone, game-focused sounds
3. **FilmCow Sound Effects** - Alphabetically organized, includes footsteps/impacts

---

## Option 1: Sonniss GameAudioGDC 2024 (RECOMMENDED)

### Overview

**Size:** 27.5+ GB
**Quality:** Professional game audio libraries
**License:** Royalty-free, no attribution required, unlimited projects
**Restriction:** Cannot use for AI/ML training
**Format:** WAV files (need conversion to OGG)

### What's Included

- **Footsteps:** Multiple surface types (wood, stone, metal, etc.)
- **Impacts:** Comprehensive impact library (light, medium, heavy)
- **Sci-fi sounds:** Spacecraft, engines, UI beeps
- **Ambience:** Space, atmospheric sounds
- **UI sounds:** Success chimes, warnings, alerts
- **And much more:** 27.5 GB of professional SFX

### Why This is the BEST Option

✅ **Professional quality** - Used by AAA game studios
✅ **Royalty-free forever** - Use on unlimited projects
✅ **No attribution required** - No credits needed
✅ **Comprehensive** - Will have 90% of what you need
✅ **Legal for commercial use** - 100% cleared

### Download Instructions

**Method 1: Web Download (Split into 9 parts)**

1. Visit: [https://sonniss.com/gameaudiogdc](https://sonniss.com/gameaudiogdc/)
2. Download all 9 parts (easier than one massive file)
3. Extract each part
4. Browse folders for sounds you need

**Method 2: Torrent (if available)**

Some years provide torrent downloads - faster for large files.

**What to Download for Moon Landing:**

From the extracted library, search for:
- `/Footsteps/` - Look for dry, crunchy sounds
- `/Impacts/` - Spacecraft landing thuds
- `/Sci-Fi/` or `/Spaceships/` - Engine sounds
- `/UI/` - Success chimes, warnings
- `/Whoosh/` or `/Thrust/` - Jetpack sounds

**Conversion Required:**

Files are WAV format. Convert to OGG:
```bash
ffmpeg -i input.wav -c:a libvorbis -q:a 5 output.ogg
```

### Sources

- [Sonniss GameAudioGDC](https://sonniss.com/gameaudiogdc/)
- [GDC 2024 Announcement](https://www.audiopluginguy.com/news-sonniss-unveils-gdc-2024-game-audio-bundle-a-free-27-5-gb-sound-library/)
- [Download Page](https://gdc.sonniss.com/)

---

## Option 2: JimLynchCodes/Game-Sound-Effects (GitHub)

### Overview

**Size:** Small (exact size unknown, but git-friendly)
**Quality:** Game-appropriate, royalty-free
**License:** "Royalty free and open source" (check repo for specifics)
**Format:** Unknown (likely WAV or MP3)

### Download Instructions

**Clone the repository:**

```bash
cd C:/godot/audio
git clone https://github.com/JimLynchCodes/Game-Sound-Effects.git
cd Game-Sound-Effects/Sounds
ls
```

**Or download ZIP:**

1. Visit: [https://github.com/JimLynchCodes/Game-Sound-Effects](https://github.com/JimLynchCodes/Game-Sound-Effects)
2. Click green "Code" button
3. Select "Download ZIP"
4. Extract to `C:/godot/audio/Game-Sound-Effects`

### What's Inside

- Sounds folder with various game SFX
- Royalty-free collection
- Unknown specific categories (explore after download)

### Pros/Cons

✅ **Quick download** - Small enough to git clone in seconds
✅ **Game-focused** - Curated for game development
✅ **Open source** - Freely available

❌ **Unknown contents** - Need to explore after download
❌ **License unclear** - Says "royalty free" but no specific license file
❌ **Small collection** - Only 10 stars, 8 forks (not massive)

### Source

- [GitHub Repository](https://github.com/JimLynchCodes/Game-Sound-Effects)

---

## Option 3: FilmCow Sound Effects (GitHub)

### Overview

**Size:** Medium (entire recorded sounds collection)
**Quality:** Community-contributed, varied
**License:** Check [https://filmcow.itch.io/filmcow-sfx](https://filmcow.itch.io/filmcow-sfx) for specifics
**Format:** Unknown (likely WAV)
**Organization:** Alphabetically sorted (A-Z folders)

### Download Instructions

**Clone the repository:**

```bash
cd C:/godot/audio
gh repo clone mcdoolz/filmcow-recorded-sounds
cd filmcow-recorded-sounds
ls
```

**Or download ZIP:**

1. Visit: [https://github.com/mcdoolz/filmcow-recorded-sounds](https://github.com/mcdoolz/filmcow-recorded-sounds)
2. Click "Code" → "Download ZIP"
3. Extract to `C:/godot/audio/filmcow-sounds`

### What's Inside

According to earlier search results, FilmCow includes:
- **Footsteps** - Metal hits, various surfaces
- **Impacts** - Office sounds, materials
- **Varied SFX** - Organized alphabetically in 23 folders (A-Z, no Q)

### Pros/Cons

✅ **Well-organized** - Alphabetical folders
✅ **Includes footsteps/impacts** - Confirmed in descriptions
✅ **Community-tested** - Available on itch.io

❌ **License unclear** - Check itch.io page first
❌ **Unknown formats** - May need conversion
❌ **Quality varies** - Community-contributed

### Source

- [GitHub Repository](https://github.com/mcdoolz/filmcow-recorded-sounds)
- [Original Itch.io Page](https://filmcow.itch.io/filmcow-sfx)

---

## Option 4: Awesome CC0 Audio (GitHub Curated List)

### Overview

Not a library itself, but a curated list of CC0/public domain audio resources.

**Repository:** [https://github.com/madjin/awesome-cc0](https://github.com/madjin/awesome-cc0)

### What's Linked

According to the repo, it links to:
- **Freesound** - Filter for CC0 sounds
- **Free Music Archive** - 5400+ public domain songs
- **Musopen** - Royalty-free music and sound

### How to Use

1. Visit the GitHub repo
2. Browse the "Sound" section
3. Click links to external resources
4. Download CC0-licensed audio

### Pros/Cons

✅ **Curated quality** - Only CC0/public domain
✅ **Legal certainty** - All public domain
✅ **Multiple sources** - Links to best platforms

❌ **Not downloadable** - Just links, not files
❌ **Manual curation needed** - Still need to visit each site

### Source

- [Awesome CC0 Repository](https://github.com/madjin/awesome-cc0)

---

## Comparison Table

| Library | Size | Quality | License | Download Speed | Moon Landing Coverage |
|---------|------|---------|---------|----------------|----------------------|
| **Sonniss GDC 2024** | 27.5 GB | Professional | Royalty-free | Slow (9 parts) | 90%+ ⭐ |
| **Game-Sound-Effects** | Small | Good | Open source | Fast (git clone) | Unknown |
| **FilmCow** | Medium | Varied | Check itch.io | Medium | 60-70% |
| **Awesome CC0** | N/A | Varies | Public domain | N/A (links only) | N/A |

---

## Recommended Workflow

### For Moon Landing (Fast - 30 mins)

1. **Clone Game-Sound-Effects** (5 minutes)
   ```bash
   git clone https://github.com/JimLynchCodes/Game-Sound-Effects.git
   ```
2. **Browse for useful sounds** (10 minutes)
3. **Convert to OGG if needed** (10 minutes)
4. **Place in Godot directories** (5 minutes)

### For Moon Landing (Best Quality - 2-3 hours)

1. **Download Sonniss GDC 2024** (1-2 hours)
   - All 9 parts from [https://sonniss.com/gameaudiogdc](https://sonniss.com/gameaudiogdc/)
2. **Extract and search** (30 minutes)
   - Search for "footstep", "impact", "engine", "thrust", "ui"
3. **Convert batch to OGG** (30 minutes)
   ```bash
   for f in *.wav; do ffmpeg -i "$f" -c:a libvorbis -q:a 5 "${f%.wav}.ogg"; done
   ```
4. **Place in Godot directories** (10 minutes)

### For Complete Library (Future-proof - 3-4 hours)

1. **Download Sonniss GDC 2024** (full archive)
2. **Clone Game-Sound-Effects** (backup source)
3. **Clone FilmCow** (variety)
4. **Organize into master library** (1 hour)
5. **Convert all to OGG** (1 hour)
6. **Tag and categorize** (1 hour)

---

## Batch Conversion Script

Once you have WAV files from any source, convert all to OGG:

```bash
#!/bin/bash
# Convert all WAV files in a directory to OGG Vorbis

INPUT_DIR="$1"
OUTPUT_DIR="${INPUT_DIR}_ogg"

mkdir -p "$OUTPUT_DIR"

for f in "$INPUT_DIR"/*.wav; do
    filename=$(basename "$f" .wav)
    echo "Converting $filename..."
    ffmpeg -i "$f" -c:a libvorbis -q:a 5 "$OUTPUT_DIR/${filename}.ogg"
done

echo "Conversion complete! OGG files in: $OUTPUT_DIR"
```

**Usage:**
```bash
bash convert_to_ogg.sh /path/to/wav/files
```

---

## License Compliance

### Sonniss GameAudioGDC

**Terms:**
- ✅ Free for commercial use
- ✅ No attribution required
- ✅ Unlimited projects
- ✅ Lifetime usage
- ❌ Cannot use for AI/ML training

**Credits (optional but appreciated):**
```
Sound effects from Sonniss GameAudioGDC 2024
https://sonniss.com/gameaudiogdc/
```

### Game-Sound-Effects (JimLynchCodes)

**Terms:** States "royalty free and open source"
- Check repository for LICENSE file
- If no license, contact author for clarification
- Assume royalty-free for game use

**Credits (recommended):**
```
Sound effects from Game-Sound-Effects by JimLynchCodes
https://github.com/JimLynchCodes/Game-Sound-Effects
```

### FilmCow

**Terms:** Check [https://filmcow.itch.io/filmcow-sfx](https://filmcow.itch.io/filmcow-sfx)
- Likely royalty-free based on itch.io distribution
- Verify license before commercial use

**Credits (recommended):**
```
Sound effects from FilmCow SFX Library
https://filmcow.itch.io/filmcow-sfx
```

---

## Integration with Moon Landing

After downloading and converting sounds:

1. **Place files in directories:**
   ```
   C:/godot/audio/sfx/spacecraft/
   C:/godot/audio/sfx/landing/
   C:/godot/audio/sfx/walking/
   C:/godot/audio/sfx/ui/
   ```

2. **Follow naming convention from AUDIO_FILES_NEEDED.txt:**
   - engine_thrust_loop.ogg
   - footstep_moon_01.ogg
   - landing_impact_medium.ogg
   - etc.

3. **Open Godot and verify import:**
   - FileSystem panel should show new audio files
   - Click to preview
   - Check Import tab for loop settings

4. **Add MoonAudioManager to scene:**
   - Follow MOON_LANDING_AUDIO_SYSTEM.md
   - Press F6 to test

---

## Troubleshooting

**"Git clone failed"**
- Ensure git is installed: `git --version`
- Try ZIP download instead

**"WAV files too large"**
- Convert to OGG: reduces file size 5-10x
- Quality level 5 is good for games

**"Can't find specific sounds in Sonniss"**
- Use file explorer search: search for "footstep"
- Check subdirectories: `/SFX/`, `/Foley/`, `/Impacts/`

**"License unclear"**
- Default to Freesound/ZapSplat individual files (clear licenses)
- Contact library maintainer on GitHub Issues

---

## Summary

**Best Overall:** Sonniss GameAudioGDC 2024
- 27.5 GB professional library
- Will have 90%+ of sounds you need
- Royalty-free, no attribution

**Fastest:** JimLynchCodes/Game-Sound-Effects
- Git clone in seconds
- Game-focused sounds
- Unknown contents (explore after)

**Most Organized:** FilmCow
- Alphabetical folders
- Includes footsteps/impacts
- Check license first

**Next Steps:**
1. Pick one library to start
2. Download/clone
3. Search for needed sounds
4. Convert to OGG
5. Place in Godot directories
6. Test with moon_landing.tscn

---

**Generated:** 2025-12-04
**Documentation:** See AUDIO_DOWNLOAD_GUIDE.md for individual file approach
**System:** Audio manager ready at scripts/audio/moon_audio_manager.gd

### Sources

- [Sonniss GameAudioGDC](https://sonniss.com/gameaudiogdc/)
- [JimLynchCodes Game-Sound-Effects](https://github.com/JimLynchCodes/Game-Sound-Effects)
- [FilmCow Sound Effects](https://github.com/mcdoolz/filmcow-recorded-sounds)
- [Awesome CC0](https://github.com/madjin/awesome-cc0)
- [GDC 2024 Audio Bundle News](https://www.audiopluginguy.com/news-sonniss-unveils-gdc-2024-game-audio-bundle-a-free-27-5-gb-sound-library/)
