# Jobcard Scanning Diagnosis

## Your OCR Text Analysis

Looking at your OCR output, here's what the parser sees:

```
Line 1: QUALITY PLASTIC PRODUCTS
Line 2: FG Code:
Line 3: Quantity to Manufacture:
Line 4: TRADING
Line 5: Daily Output (Units):
Line 6: Target Cycle Day:
Line 7: Traget Cycle Night:
...
Line X: 50LT Coolbox Outer- CampMastr Blue
Line Y: Works Order / Batch Sheet
Line Z: JC031351
```

## Problem Identified

The OCR is reading text in **column order** (top to bottom in each column) rather than **row order** (left to right across the page).

### Example:
```
Physical layout:
FG Code: 50LT Coolbox Outer    Works Order No: JC031351

OCR reads as:
Line 1: FG Code:
Line 2: Works Order No:
Line 3: 50LT Coolbox Outer
Line 4: JC031351
```

This breaks the parser's assumption that labels and values are on consecutive lines.

## Why Original Parser Was Better

The original `JobcardParserService` has specific logic for this:

1. **Looks for "Works Order / Batch Sheet"** as anchor
2. **Takes next non-empty line** as job name
3. **Splits on dash** to separate name and color
4. **Searches for "Works Order No:"** then takes next line

This works because it uses **context clues** rather than spatial positioning.

## Why Improved Parser Failed

The `ImprovedJobcardParser` uses spatial positioning (bounding boxes) which should work better, but:

1. **Too strict proximity** - values might be further than expected
2. **Single element matching** - doesn't combine multiple text elements
3. **Column confusion** - OCR reads columns not rows

## Solution

### Option 1: Use Original Parser (Current)
✅ Already switched back
- Works with your jobcard format
- Handles column-based OCR
- Uses context clues

### Option 2: Fix Improved Parser
Need to:
1. Increase search radius
2. Combine multiple nearby elements
3. Handle column-based text flow
4. Add fallback to line-by-line

### Option 3: Hybrid Approach
1. Try spatial first
2. Fall back to line-by-line
3. Use confidence scores to pick best

## Expected Results with Original Parser

Based on your OCR text:

**Works Order No:**
- Looks for: "Works Order No:" or "JC" pattern
- Should find: JC031351 ✅

**Job Name:**
- Looks for: "Works Order / Batch Sheet"
- Takes next line: "50LT Coolbox Outer- CampMastr Blue"
- Splits on dash: "50LT Coolbox Outer" ✅

**Color:**
- Same line as job name, after dash
- Should extract: "CampMastr Blue" ✅

**Quantity:**
- Looks for: "Quantity to Manufacture:"
- Takes next number: 3,000.00 → 3000 ✅

**Daily Output:**
- Looks for: "Daily Output"
- Takes next number: 1016.00 → 1016 ✅

**Cycle Weight:**
- Looks for: "Cycle Weight" or "gram"
- Should find: 1767 ✅

**Target Cycles:**
- Looks for: "Target Cycle Day/Night"
- Should find: 466 and 551 ✅

## Testing Steps

1. **Capture jobcard** with current parser
2. **Check review screen** - which fields are populated?
3. **Check logs** - what did parser extract?
4. **Compare** with expected values above

## If Still Not Working

### Check These:

1. **OCR Quality**
   - Is text clear in logs?
   - Any missing characters?
   - Correct spelling?

2. **Pattern Matching**
   - Are labels spelled correctly?
   - Case sensitivity issues?
   - Extra spaces/characters?

3. **Line Breaks**
   - Where do lines break?
   - Are values on expected lines?

### Debug Commands

Add to parser to see what's happening:

```dart
// In jobcard_parser_service.dart
LogService.debug('=== ALL LINES ===');
for (int i = 0; i < lines.length; i++) {
  LogService.debug('Line $i: ${lines[i]}');
}
LogService.debug('=== END LINES ===');
```

## Recommendation

**Keep using original parser** (`JobcardParserService`) because:

1. ✅ Designed for your jobcard format
2. ✅ Handles column-based OCR
3. ✅ Uses context clues
4. ✅ Already tested and working
5. ✅ Simpler and more reliable

The "improved" parser was over-engineered for this use case.

## Next Steps

1. Test with original parser
2. Check which fields populate
3. If issues remain, we'll add specific fixes
4. Focus on what's actually broken, not theoretical improvements

---

**Status:** Reverted to original parser  
**Expected:** Should work better now  
**Action:** Test and report which fields are still wrong
