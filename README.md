# Screenshot2PDF

A small macOS app that batch-crops PNG/JPEG images from a folder and stitches the cropped images into a single PDF, in creation-date order.

Originally built for cropping recurring regions out of screenshots (e.g. a fixed window on a screen-recording frame grab).

## Features

- Pick a folder of PNG/JPEG images
- Set a crop rectangle (`x`, `y`, `width`, `height` in pixels, top-left origin)
- Generates `CroppedOutput.pdf` in the same folder, one page per image
- Sandboxed, user-selected file access only
- macOS 14+ (SwiftUI, PDFKit)

## Build & run

Requires Xcode 15+.

```sh
open Screenshot2PDF.xcodeproj
```

Then `⌘R` to build and run. Or from the command line:

```sh
xcodebuild -project Screenshot2PDF.xcodeproj -scheme Screenshot2PDF -configuration Release
```

## Usage

1. Click **Choose…** and select a folder containing PNG/JPEG images.
2. Enter the crop rectangle in pixels. Origin is the top-left of each image.
3. Click **Generate PDF**. The output is written as `CroppedOutput.pdf` in the selected folder.
4. Click **Reveal PDF** to open it in Finder.

Images are ordered by file creation date (ties broken alphabetically). If the crop rectangle falls outside any image's bounds, processing stops with an error naming the offending file.

## Project layout

```
Screenshot2PDF/
├── Screenshot2PDFApp.swift   # App entry point
├── ContentView.swift          # SwiftUI UI
├── CropProcessor.swift        # Image crop + PDF assembly
├── Screenshot2PDF.entitlements
└── Assets.xcassets
```
