# Mark Twain

A read-only Markdown library for iPhone and iPad, built with SwiftUI, SwiftData,
and an embedded WebKit browser.

## Run in Xcode

1. Open `MarkTwain.xcodeproj` in Xcode 15 or newer.
2. Select the **MarkTwain** scheme and an iPhone or iPad simulator running iOS 17+.
3. Build and run (Command-R). For a physical device, choose your development
   team under **Signing & Capabilities** and a unique bundle identifier.

No package installation or network connection is required to build or render
documents. To build from a Mac terminal:

```sh
xcodebuild -project MarkTwain.xcodeproj -scheme MarkTwain \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

## Read Markdown

Tap **+** to import `.md`, `.markdown`, or plain-text files from Files, including
iCloud Drive and other file providers. You can also open a Markdown file in
Mark Twain from another app. Files must be UTF-8 and at most 5 MB.

Imported files are copied into the app's local SwiftData library, so they remain
available after relaunch and do not change if the original file changes. Select
a document to read it; swipe to delete it or use **Edit**. Deleting a library
copy never deletes the original file.

The preview supports GitHub Flavored Markdown tables, task lists, strikethrough,
autolinks, and fenced code blocks, plus light/dark appearance. Code blocks are
not syntax-highlighted. Use **PRINT** in the document toolbar to open the
system print panel and print or save a PDF. Editing and relative/local image
loading are not implemented. HTTPS images can load from the network; embedded
data images work offline. Tapped HTTP(S) and email links open outside the preview.

## Rendering and safety

The app bundles [Marked](https://github.com/markedjs/marked) 18.2.1 and
[DOMPurify](https://github.com/cure53/DOMPurify) 3.4.18, with their licenses in
`MarkTwain/Resources`. Markdown is passed as base64-encoded UTF-8 text, parsed
with GFM enabled, and sanitized before insertion into the page. A Content
Security Policy blocks document scripts, frames, forms, and other unexpected
resources; browser storage is ephemeral.

To update the bundled libraries, obtain the pinned npm packages, check their
security advisories, and replace `marked/lib/marked.umd.js` → `marked.js` and
`dompurify/dist/purify.min.js` → `purify.js`, together with their license files.
Keep all five resources in the app target's **Copy Bundle Resources** phase.

## Verification

There was no existing test infrastructure in this repository. Before shipping,
build in Xcode and check the following on both iPhone and iPad:

- Import a UTF-8 file containing a table, task list, strikethrough, code block,
  Unicode, and links; verify the rendered preview in light and dark mode.
- Relaunch the app and confirm the imported content remains available offline.
- Open a file from another app, import multiple files, cancel the picker, and
  verify invalid UTF-8 and oversized files produce an error.
- Delete a document and verify the original file is untouched.
- Import raw HTML containing scripts, event handlers, and `javascript:` links;
  verify none execute.

The Linux development environment can validate Swift syntax, Xcode project
structure, and browser rendering, but cannot build or run Apple's UI frameworks.
