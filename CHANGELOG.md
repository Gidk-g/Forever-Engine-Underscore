# Changelog
All notable changes will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] - [AUG-8-2022 - AUG-23-2022]
### Added
- Notetypes were rewritten as an integer, they should properly save on songs now;
- New Accessibility Options (Notesplash Opacity, Arrow Opacity);
- You can optionally enable a commit hash, mostly something made for bug reporting on the base repository and such;
- Song Metadata will now be injected via a separated file named `meta.json` on your Song's Folder;
- with the Metadata change, you can now add colors to your songs as an RGB format;
- Shaders can now be called via Scripts;
- you can now have Animated Icons via Sparrow Atlas (XML);
- Campaign UI Characters are now separated into Folders and fully Softcoded via JSON Files;
- Dialogues can now use Text Files, meaning that you are no longer limited to just using the Hardcoded `Alphabet.hx` for them;
- Scripted Tweens can now have a `onComplete` function by calling `completeTween(tweenID)` on a script;
- Strumlines can now be moved freely, allowing for **Modcharts** to be made (still planning to make it easier though!);

### Fixed
- Newgrounds Logo now shows up on Title Screen
- Winter Horrorland now has a proper Background;
- Week 6 is completely Fixed;

### Adjusted
- Scripts now use the "hx" file extension, allowing for Haxe Extensions to be used;
- All Menus (excluding Story and Options) now have persistent variables for the item you are currently highlighting;
- Song Information is now available on the `ChartParser.hx` file, rather than being separated by both `Song.hx` and `Section.hx`;
- `Conductor.hx` now handles Song Playback;
- Improved Notetype Handling, Notetypes can now be fully set up on `Note.hx`;
- The Codebase has been entirely formatted (thanks @otallynotdoggogit);
- The `README.md` file has been entirely rewritten (thanks @otallynotdoggogit);

### Work in Progress
- (Addition) Softcoded Weeks via JSON Files;

### Status
still in development, I wanna add some more stuffs before hoping right to 0.2.2 / 0.3
help is appreaciated!
