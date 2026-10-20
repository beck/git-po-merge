# Three-way SPDX and PO metadata merge

- `base.po`: SPDX copyright 2015 Douglas Beck and original metadata.
- `ours.po`: changes SPDX copyright to 2021 Mikko Rantalainen, `PO-Revision-Date`, `Last-Translator`, `X-Generator`, and the `Hello` translation.
- `theirs.po`: retains the base SPDX copyright but changes `Project-Id-Version`, `Report-Msgid-Bugs-To`, `POT-Creation-Date`, `Language-Team`, and the `Goodbye` translation.
- `expected.po`: retains the updated SPDX header and merges independent field changes and translations from both sides.

Run the project's merge script against a temporary copy of `ours.po`, and compare to `expected.po`. `polib` may normalize serialization, so the checked-in expected output should be regenerated using the actual driver after verifying its semantic correctness.
