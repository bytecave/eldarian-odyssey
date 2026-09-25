# PureBasic 6.41 review and regression guide — 2026-09-25

**Major spoilers.** Baseline: `f98ce913bfbee70bcf52c121dea998d4a7b29baa`, branch `master`.

The supplied Codex prompt authorized this work. The supplied preliminary review was checked against source; the 2018 notes transcription was treated as uncertain historical evidence, not instructions or sufficient grounds for changing gameplay. Runtime modules, room/noun databases, TODO/development notes, text resources, and project metadata were reviewed. The custom DSL, four-letter parser, state-bit reuse, pseudo-rooms, humor, and graphical presentation remain.

## Migration and validation

Verified compiler: **PureBasic 6.41 (Windows - x64)**, normal ASM `pbcompiler.exe`. All five uses of removed `#PB_String_InPlace` were migrated to assigned `ReplaceString()` results, retaining case sensitivity, start positions, and replacement counts. No additional compile-blocking incompatibilities remained after that migration. Current semantics were checked against the official [ReplaceString reference](https://www.purebasic.com/documentation/string/replacestring.html), [migration guide](https://www.purebasic.com/documentation/reference/migration.html), and [compiler CLI reference](https://www.purebasic.com/documentation/reference/cli_compiler.html).

The project creator and both x64 compiler selections now name 6.41 x64. DebugX86 now actually enables debugging. All four targets retain their paths, icon, company/product fields, and IFID; their project version fields are now 1.03. The x86 compiler selections retain their historical metadata pending validation with an installed x86 compiler.

Run from this directory:

```powershell
powershell -NoProfile -File .\Validate.ps1
```

This runs `/CHECK`, the requested x64 release build with `/ICON /XP /USER`, a debugger-enabled build, and the console regression executable. It stops on failure and does not launch the graphical game. The CLI builds embed separate release/debug Windows version resources, both reporting version 1.03; the PBP targets use the same version number for IDE builds.

Results at completion:

| Validation | Result and scope |
|---|---|
| Application `/CHECK` | Passed with PureBasic 6.41 x64 ASM |
| Release executable | Built successfully at `Binaries/EldarianOdyssey-x64.exe` |
| Debugger-enabled executable | Built successfully; not a claim of an interactive debugger playthrough |
| Published x64 archives | `Binaries/EldarianOdyssey-x64.zip` and `Binaries/EldarianOdyssey-x64-Debug.zip` each contain exactly their matching version 1.03 executable |
| Regression executable | **212 checks, 0 failures** |
| Complete game progression | Executed from fresh state through actual parser/handlers, rescue, return, and once-only reward; inventory membership checked after each command |
| Save/load | Real temporary EOS files exercised for victory, timers/metadata, jump warnings, reset, invalid-load rejection, and failed-save dirty state |
| x64 inline assembly | Executed grayscale conversion on 24- and 32-bit images, including the final pixel |
| Graphical startup | Launched and visually inspected: maximized window, welcome/room text, embedded presentation, direction and torch indicators appeared without an immediate fatal error |
| Physical keyboard/dialogs/themes | F5 was verified in the rebuilt graphical application in both directions. F1/F2, HELP paging, text editing/history, confirmations, and other physical input still require owner testing |
| x86, Linux, macOS | Not built or run |

The harness includes the actual game modules and draws text to an offscreen image. Targeted edge cases use explicit world fixtures. The complete walkthrough uses normal commands without teleporting or granting items; it advances the opening watchman's timer directly instead of waiting. This validates engine behavior, not the keyboard/rendering event loop or every possible command ordering.

## Preliminary review reconciliation

| Significant finding | Disposition |
|---|---|
| Unprepared lich combat leaves input paused/grayscale | **Confirmed and fixed.** `LICHDEATH` and `LICHINSTANT` share the established burrow revival, light reset, band update, and input/color restoration. Executed in the harness; physical visual timing remains manual. |
| King permits victory before finding Rynn | **Confirmed and fixed.** Requires dead lich plus the Prince room's existing visited/rescued state. The prince takes the scepter and Eldred pays only once. |
| Duplicate lich timer routing | **Confirmed and fixed.** Removed the separate duplicated instant-death branch. |
| Coin noun plus separate quantity can diverge | **Confirmed and fixed at identified transitions.** Transfers derive old location from the noun, remove previous membership, and count inventory from its map. Payments require carried coins and successful spending. Treasury exchanges and rewards restore coin membership. |
| Petition King TODO | **Confirmed and fixed.** Added vocabulary/dispatch using the four-letter `PETI` form. |
| Guard says “kneel ... nave” TODO | **Design intent clarified by the owner and implemented.** The throne-room Defender now says “Kneel before the king, knave!” on TALK/SPEAK until the torch has received its everlasting-light blessing. The original review incorrectly classified the missing clue as obsolete. Existing friendly/hostile responses remain, with the clue appended before the blessing. |
| Dug bottle should disappear | **Confirmed and fixed.** Bottle moves to ITEMGONE, birch description changes, potion becomes available; drinking removes the potion. |
| LOG/LOGS in village and town hall | **Confirmed and fixed.** Contextual resolution selects village buildings or the hall's supporting log. |
| Missing ceiling and circlet | **Confirmed and fixed.** Added fixed scenery nouns based on descriptions already present; circlet cannot be taken. |
| Belzar versus Zyland naming | **Already consistent in current runtime content.** Belzar is used; no rename based on the uncertain historical note. |
| Damben repeats payment dialog | **Confirmed and fixed.** Paid dialog and repeated-payment guard, including older saves whose barricade is already open. |
| Crypt light and dagger historical reminders | **Confirmed relevant defects and fixed.** Corrected the DSL torch target; blessed light fills the crypt, departure clears the crypt torch/dagger effects, and defeated lich cannot trigger another combat/death. |
| Map behavior historical reminder | **Confirmed a purchase-state defect and fixed.** Dropping an owned map no longer permits another purchase. Maze/parser design retained. |
| Climbing and parser historical reminders | **Partly already implemented.** Existing rope/tree routes work in the walkthrough. Added fixes for unreachable full-word verb comparisons and contextual water. Did not treat every old note as a live bug. |
| Save/load is a thorough snapshot | **Qualified; defects fixed.** Timers lost room/metadata, reset retained timers/actions, membership could duplicate, pseudo-room coordinates could overwrite movement, and one-time text was destructively cleared. These are corrected. |
| Large Handlers file, string identifiers, overloaded state bits | **Intentionally unchanged architecture.** Named aliases added only for rescue/reward and jump warning fixes; no broad split/type-system rewrite. |
| Cross-platform intent and assembly/API hotspots | **Confirmed limitation.** Windows function pointer guarded; x64 grayscale tested. Portability is not established by the Windows build. |
| DSL/awareness/contextual vocabulary/resource embedding | **Confirmed design and preserved.** Added regression coverage instead of replacing the engine. |
| Add transcript tests | **Implemented.** `RegressionTests.pb` exercises actual parser and game state. |
| Split Handlers by region | **Intentionally not followed.** The task explicitly excludes splitting it merely for size. |

## Additional confirmed corrections

- GET/GET ALL and DROP guard absent nouns; capacity is checked after relevant ownership/gettable checks. Lost-axe inventory count no longer decrements twice. Mealbar capacity accounts for spending the last coin. Worn bracelet stays on the player when the backpack is dropped.
- The iron key must actually be carried to unlock the cell; the cell tests the correct locked bit. The prisoner's granite-gate actions occur when freed, after feeding and conversation, rather than on feeding alone. Treasury notes cannot be redeemed anywhere in the world.
- New/load resets transient timers and UI state, validates required room/noun references before replacing the world, rebuilds membership from noun locations, closes preferences, and preserves dirty state when saving fails. One-time descriptions retain their source text so earlier saves can show them again.
- Cliff/chasm warning counters were static procedure locals: New Game did not reset them and saves omitted them. They now use previously unused bit 7 on each respective noun, preserving the existing alternating warning/death behavior.
- Text search respects buffer bounds; wrapping progresses with trailing CR or very narrow widths. Missing randomized-message pointers are guarded, and a missing initialization error string was added.
- Keyboard state is sampled once per frame, and release edges are captured before command-line processing can consume them. This restores F5 theme switching; both directions were verified in the graphical application. History cursor movement resets correctly, and function-key overlays cannot interrupt paused death sequences.
- Torch lighting consumes one turn; unchanged state assignments no longer mark saves dirty. Font fallback returns a PureBasic font identifier rather than a Windows handle. An unused no-op text helper was removed.

## Remaining limits and intentionally unfinished content

- HINT's placeholder and the hidden trap stub were not expanded into invented puzzles. Localization beyond the existing English content was not implemented.
- The embedded custom text reader still trusts authored resource sentinels and formatting. Save validation guards required references/structure, not every possible malicious or hand-edited state combination.
- Existing three-field timer records remain accepted; the old watchman room target is inferred. Old saves never recorded all timer metadata, so missing historical information cannot always be recovered. Real-time timers intentionally expire on load, preserving the existing policy.
- Old already-broken victory saves do not contain a reliable once-only reward marker or proof of the correct rescue sequence. New saves preserve those states; arbitrary old corrupted progression is not guaranteed to be reconstructed.
- Native title-bar close still follows the existing immediate exit path. Use the game's EXIT command to exercise its unsaved-progress confirmation. High-DPI, alternate monitors/fonts, theme contrast, dialog paging, and physical keyboard handling need manual verification.
- The build/test pass does not establish every optional puzzle branch, all death animations, x86 assembly, or other operating systems.

## Exact manual walkthrough and checkpoints

Each `|` below means **press Enter, then enter the next command**; do not paste a whole line into the game's 30-character command field. Start a new game. Use distinct save names if these names already exist. SAVE/LOAD take a name without `.EOS`; accept the in-game confirmation when loading over changed progress.

1. Enter `LIGHT TORCH | KNOCK GATE`, then wait until the watchman appears (about three seconds).
2. Reach the large tree in the woods:

   ```text
   PAY WATCHMAN | N | N | TALK KING | TALK KING | KNEEL KING | W | TALK CLERK | E | S | BUY MEALBAR | W | PAY DROW | E | E | S | GET DAGGER | N | N | N | E | S | DIG BOTTLE | GET POTION | E | S
   ```

3. Obtain the ward at the town hall:

   ```text
   CLIMB TREE | CLIMB TREE | CLIMB DOWN | CLIMB DOWN | W | S | E | SEARCH TENT | S | PAY DAMBEN | W | W | W | TALK BELZAR | TALK BELZAR
   ```

4. Reach the glowing fish pond:

   ```text
   E | E | E | E | TIE ROPE | CLIMB DOWN | GET MUSHROOM | N | GET STONE | SWIM RIVER | SMASH BOX | GET KEY | SWIM RIVER | S | E | LIGHT TORCH | N | N
   ```

5. Obtain the scepter and free the prisoner. Temporarily dropping the key makes room for the fish/scepter:

   ```text
   DROP KEY | GET POLE | BAIT POLE | DROP MUSHROOM | CATCH FISH | N | THROW FISH | GET SCEPTER | S | GET KEY | S | S | S | USE KEY | S | W | UNLOCK DOOR | W | W | FEED PRISONER | TALK PRISONER | TALK PRISONER
   ```

6. Defeat the skeleton and save just outside the crypt:

   ```text
   E | E | S | W | FIGHT SKELETON | W | W | W | SAVE EOARCH
   ```

7. Test unprepared combat: `DROP DAGGER | W | FIGHT LICH`. Expect death, gray/paused input, then revival in the burrow after about five seconds, color/input restored and torch extinguished. Enter `LOAD EOARCH` to restore the prepared state. Separately test dark entry with `EXTINGUISH TORCH | W`, wait for the same recovery, then `LOAD EOARCH` again.
8. Prepared combat: `W | FIGHT LICH | SAVE EOMID | DRINK POTION | FIGHT LICH | SAVE EODEAD`. Expect staged battle then a defeated lich. `LOAD EOMID | DRINK POTION | FIGHT LICH` must produce the same result. `LOAD EODEAD | FIGHT LICH` must say she is already defeated.
9. Rescue: `SEARCH SARCOPHAGUS | PRESS BUTTON | N | SAVE EORYNN`. Expect Rynn's thanks and removal of the scepter from inventory. `LOAD EORYNN | S | N` must not repeat the rescue or restore the scepter. End this test in the prince's room.
10. Return to Eldred:

    ```text
    S | E | E | E | E | E | N | E | N | N | W | CLIMB UP | W | W | W | W | W | N | E | N | N | TALK KING | TALK KING | INVENTORY | SAVE EOWIN
    ```

    Expect one reward and **10001 coins** on this route. `LOAD EOWIN | TALK KING | INVENTORY` must keep that total.

To verify the blocked premature ending, load EODEAD and leave east without searching the sarcophagus or visiting Rynn. From the crypt use the return sequence above **omitting its initial S**, then TALK KING. There must be no victory/reward. Restore EORYNN for the completed-rescue return.

## Short edge-case/UI checklist

- At Damben immediately after the first payment: `INVENTORY | PAY DAMBEN | TALK DAMBEN | SPEAK DAMBEN | INVENTORY`. Expect paid dialog and unchanged coins. `DROP BACKPACK | PAY DAMBEN | GET BACKPACK` must not charge or duplicate contents.
- At the inn after buying the map: `DROP MAP | PAY DROW | GET MAP`. No second charge or duplicate map. At the town hall: `LOOK LOG | LOOK LOGS | LOOK CEILING | LOOK CIRCLET | GET CIRCLET` gives scenery responses and refuses taking the circlet.
- At the courtyard while carrying the King's note: `GIVE NOTE | INVENTORY`. Keep the note until reaching the clerk. At the buried bottle: `DIG BOTTLE | LOOK | GET POTION`; the empty bottle must not remain described as buried.
- At the cliff, save after the first `JUMP CLIFF`, load, and repeat it: the second attempt triggers death. Start NEW and return there: the first attempt must warn again. Chasm follows the same warning/second-attempt pattern.
- Physical UI: F1/About, F2/Credits, HELP paging/close, F5 both themes; type and edit a command, use Up/Down history and Esc, then Enter. Confirm output wraps, directions and flame update, and overlays cannot interrupt the paused lich-death period. Test NEW/LOAD/EXIT confirmations with unsaved progress and cancel each once before accepting.
- In the throne room before the torch blessing: `TALK GUARD | SPEAK GUARDS | KNEEL KING | TALK GUARD`. Both initial conversations should include “Kneel before the king, knave!” Kneeling with the torch grants everlasting light; the final conversation should omit the now-completed clue.

## Git delivery

Work was performed directly on `master`, with each logical change checked, built, reviewed, committed, and pushed to `origin/master`. No branch, PR, rebase, force push, or history rewrite was used. Executables remain ignored local artifacts. Exact resulting HEAD and remote equality are reported with the task completion, avoiding a self-referential commit hash in this document.
