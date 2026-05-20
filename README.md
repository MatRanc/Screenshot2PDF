# Screenshot2PDF

A small macOS app that batch-crops PNG/JPEG images from a folder and stitches the cropped images into a single PDF, in creation-date order.

Originally built for cropping recurring regions out of screenshots (e.g. a fixed window on a screen-recording frame grab).

## Features

- Pick a folder of PNG/JPEG images
- Set a crop rectangle numerically (`x`, `y`, `width`, `height` in pixels, top-left origin)
- **Set from Sample…** — upload any image and drag a rectangle on it to set the crop
- **Preview & Adjust…** — page through every image in the folder and tweak the crop per-image; images without an override use the default
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
2. Set the crop rectangle. Three options, all interchangeable:
   - Type the numbers directly into the X / Y / W / H fields (top-left origin).
   - Click **Set from Sample…** to pick any image and drag a yellow rectangle on it visually. "Apply to All" copies the result back to the global crop.
   - Click **Preview & Adjust…** (enabled once a folder is loaded) to page through every image in the folder. Dragging the rectangle on a particular image creates a per-image override. Use **Apply as default for all** to promote the current rectangle to the default and clear overrides, or **Reset overrides** to remove all per-image overrides.
3. Click **Generate PDF**. Each image is cropped with its override if one exists, otherwise the default. The output is written as `CroppedOutput.pdf` in the selected folder.
4. Click **Reveal PDF** to open it in Finder.

Images are ordered by file creation date (ties broken alphabetically). If the crop rectangle falls outside any image's bounds, processing stops with an error naming the offending file.

## Project layout

```
Screenshot2PDF/
├── Screenshot2PDFApp.swift    # App entry point
├── ContentView.swift          # Main window UI
├── CropEditorView.swift       # Visual rectangle editor + sample / preview sheets
├── CropProcessor.swift        # Image crop + PDF assembly
├── Screenshot2PDF.entitlements
└── Assets.xcassets
```
