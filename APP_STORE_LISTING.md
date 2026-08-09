# App Store Connect, Listing Copy (v1.0, build 1)

Copy-paste fields for the Mac App Store submission.

- Bundle ID: `com.matranc.Screenshot2PDF`
- Version: `1.0`, Build: `1`
- Platform: macOS 14+
- Localization: English (U.S.) only

---

## App Name (30 max)

```
Screenshot2PDF
```

**14 chars.**

---

## Subtitle (30 max)

```
Batch-crop screenshots to PDF
```

**30 chars, exactly at the limit.**

---

## Promotional Text (170 max)

Editable any time without a new build submission.

```
Turn a folder of screenshots into one clean PDF. Set a crop once, apply it to every image, reorder pages, and export. Fully on-device, sandboxed.
```

**148 chars.**

---

## Description (4000 max)

```
Screenshot2PDF batch-crops a folder of PNG or JPEG screenshots and stitches the results into a single PDF, in the page order you choose.

Made for the same crop, over and over: a fixed browser chrome around a document viewer, a phone status bar, a dashboard's window frame, a presenter's webcam tile. Set the crop rectangle once and it applies to every image in the folder.

SET THE CROP YOUR WAY
Type exact pixel coordinates, or drag a rectangle on a sample image to set it visually. A magnifier loupe helps you line up a corner exactly.

PREVIEW, ADJUST, REORDER
Page through every image before you export. Drag thumbnails to put pages in the order you want, and override the crop on individual images when a few don't match the rest.

ONE PDF, DONE
Generate a single PDF from the whole folder and reveal it in Finder.

Fully sandboxed, no network access, and no data collection of any kind.

USE IT FOR
- Turning screenshots of an online document, paper, or slide deck into one scrollable PDF
- Receipts or message threads from your phone, cropped down to just the content
- Daily dashboard or chart snapshots, cropped to the chart only
- Slide decks captured from a lecture or talk recording
```

---

## What's New in This Version (4000 max)

```
First release. Batch-crop a folder of screenshots and export one PDF: type exact crop coordinates or drag a rectangle on a sample image, sort or drag-reorder pages, override the crop per image, and export.
```

---

## Keywords (100 max, comma-separated, NO spaces after commas)

```
screenshot,crop,batch,pdf,export,image,scan,folder,archive,receipt,slides,dashboard
```

**84 chars.**

---

## URLs

- **Support URL:** `https://github.com/MatRanc/Screenshot2PDF`
- **Marketing URL:** `https://github.com/MatRanc/Screenshot2PDF` (optional, same is fine)
- **Privacy Policy URL:** `https://github.com/MatRanc/Screenshot2PDF/blob/main/PrivacyPolicy.md`

---

## Category

- **Primary: Productivity** (matches `LSApplicationCategoryType = public.app-category.productivity` in the project)
- **Secondary:** optional, leave blank or use Utilities.

---

## Age Rating

Answer **None / No to every question** in the questionnaire. Result: **4+**.
No objectionable content, no web access, no ads, no gambling, no user-generated content.

---

## App Privacy

Answer **"No"** to *"Do you or your third-party partners collect any data from this app?"*, this produces **Data Not Collected** on the product page.

- No tracking, so App Tracking Transparency does not apply.
- No third-party SDKs, the app links only Apple frameworks (SwiftUI, PDFKit).

This matches `Screenshot2PDF/PrivacyInfo.xcprivacy`, which declares
`NSPrivacyTracking = false`, an empty `NSPrivacyCollectedDataTypes`, and one
accessed-API entry: file timestamps (used to sort images by creation date).

**Sandboxing:** the app's entitlements only request
`com.apple.security.files.user-selected.read-write` inside the app sandbox,
no network entitlement at all.

**Export compliance:** if App Store Connect asks about encryption, answer
that the app uses no encryption beyond what's exempt by default (standard
OS-provided encryption only).

---

## Copyright

```
2026 Mathieu Rancourt
```

(Confirm your legal name before submitting.)

---

## Review Notes (App Review Information, Notes)

```
No account or sign-in is required. Nothing is gated.

To test: launch the app, click Choose... and pick a folder of PNG or JPEG images (any folder of screenshots works), set a crop rectangle (or leave the default), and click Generate PDF. The output, CroppedOutput.pdf, is written to the same folder and can be opened via Reveal PDF.

The app is fully sandboxed and has no network entitlement. It contains no networking code and links no third-party SDKs.
```

---

## Screenshots needed

Up to 10, for Mac: one of 1280 x 800, 1440 x 900, 2560 x 1600, or 2880 x 1800 px.

What each shot should show:

1. **Main window** with a folder loaded and the crop fields filled in.
2. **Set from Sample** sheet, dragging a rectangle on a sample image.
3. **Preview & Adjust** sheet, paging through images with the loupe visible on a drag.
4. **Thumbnail reordering** in the preview sheet.
5. **Finder**, showing the generated `CroppedOutput.pdf` next to the source screenshots.

Screenshots must be real captures of the shipping build.

---

## Still to decide / supply

- Price tier (free or paid).
- Whether to set a secondary category.
- The screenshots themselves.
