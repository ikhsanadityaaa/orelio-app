# orelio v0.4 status

## Changes from v0.3

- Removed the long vertically stacked Adjust list from the editing flow.
- Separate Film, Tools and Lighting modes; Tools now shows a contextual individual slider with 19 horizontally scrolling tool buttons.
- Film looks are arranged in a horizontal photo-thumbnail rail, with category switching and film-strength control.
- Native gesture handle is clipped to the aspect-fit rendered photo, preventing overflow into the black preview margins.
- Browser prototype computes the actual displayed image rectangle and clips light overlay/drag handle to that rectangle.
- Offline workflows, batch paste, export and collage remain intact.

## Implemented in project source

- Removed in-app brand wordmark from working-screen UI (the v0.2 native screen already used generic navigation titles).
- 27 film looks including Original, arranged into four visible tabs: Negative, Slide, Instant and B&W. Former Vintage color looks appear under Negative; all monochrome looks appear under B&W. Existing recipe IDs remain unchanged.
- Film strength plus expanded adjustment state and local Core Image processing.
- Model migration/defaults supporting v0.1 and v0.2 recipe manifests.
- Selective paste now transfers all new groups of adjustments.
- Multipage collage editor: add/remove/reorder page, six layouts, choose photo per slot, gap editing.
- Auto-save collage pages on device; export JPG per page.
- Procedural dust and date stamp (initial implementation).

## Not implemented / incomplete

- Xcode/device-verified build; native renderer quality and GPU regressions still untested.
- Camera-calibrated emulation of actual film stocks; grading remains approximation.
- Full SCRL-like freeform canvas, text stickers, cross-page seamless content, image crop pan/zoom.
- Advanced object eraser (deliberately out of scope).

## Verification performed

- Portable Swift model test suite: PASS.
- Swift source syntax parsing: PASS.
- HTML preview interactions: PASS; no JS page errors in test scenarios.
- Project ZIP integrity: PASS after packaging.
- Test of light clipping and edge drag at different image sizes in HTML: PASS.


## v0.5 additions
- Added border in non-destructive EditRecipe; rendered at the end of Core Image pipeline, supports inner/outer, monochrome, adjustable width.
- Added preview-only composition grids and golden spiral rotation/mirror.
- Extended UI with Border/Grid modes and selective batch-paste checkbox.
- Portable code checks and browser prototype interaction checks passed; iOS binary build/real export test pending Xcode.
