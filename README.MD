Copyright © 2026 HeartWare. All rights reserved.

This UNIT is released under the **HeartWare FreeWare License**.

You may freely use, copy, modify, and redistribute this software and its
source code for private, hobby, educational, and other non-commercial
purposes.

You may not use, sell, distribute, include, publish, bundle, or otherwise
make this software, or any modified or derivative version of it, available
in any commercial context without prior permission from HeartWare. This
includes direct or indirect commercial use or distribution, including paid
download sites, subscription services, commercial software collections,
magazines, books, paid media, or products or services for which money is
charged. It also includes putting this software or links to it on sites
that are supported by ads.

If you redistribute a modified or derivative version, it must be released
under this **exact same license**. You may neither add nor remove
permissions, restrictions, or licensing terms.

The copyright notice and this license must remain with all redistributed
copies and derivative versions.

**Commercial use requires separate permission from HeartWare.**

The software is provided "as is", without warranty of any kind.

If you are not completely satisfied, return it to where you obtained it for
a full monetary refund of the price you paid for it.

---

# HeartWare.VCL.Countdown

`HeartWare.VCL.Countdown` provides a family of modal countdown-dialog functions for VCL applications.

The dialog is created completely at runtime and displays:

- a caller-supplied window title;
- a caller-supplied descriptive caption;
- a live countdown showing the remaining hours, minutes, and seconds;
- an optional checkbox;
- an **Ignore** action;
- an optional **Abort** action;
- and, when enabled, the normal window close action.

The dialog automatically sizes itself to its contents, uses the monitor DPI of the current form, and centers itself on the current modal form when one exists. If there is no current modal form, it falls back to the active VCL form or the primary monitor.

Long captions are automatically word-wrapped. The caption text area is limited to 66% of the width of the intended parent form (or monitor work area) and the completed dialog is limited to 80% of the corresponding height. If the full caption still cannot fit within that space, it is truncated and terminated with `...`. Explicit CR, LF, CR/LF, and LF/CR line breaks in the supplied caption are preserved as hard line breaks.

When the requested countdown expires normally, `Countdown` returns `mrOK`.

## Basic usage

A simple countdown in milliseconds:

```delphi
VAR R:=Countdown('Cooldown','Please wait...',62000);
```

A caller can test the returned `TModalResult` in the normal VCL manner:

```delphi
CASE Countdown('Cooldown','Please wait...',62000,TRUE,TRUE,FALSE) OF
  TModalResult.Abort : Abort
END;
```

The default call enables **Ignore**, disables normal window closing, and does not show **Abort**.

## Countdown display

The remaining time is displayed in a human-readable form with correct singular/plural wording.

Examples:

```text
8 seconds
1 minute, 4 seconds
12 minutes, 1 second
1 hour, 0 minutes, 15 seconds
2 hours, 7 minutes, 3 seconds
```

Hours are omitted when zero.

Minutes are omitted when both hours and minutes are zero.

The countdown is based on `GetTickCount64`, so the elapsed time is measured from the system monotonic tick count rather than by decrementing a counter every time the VCL timer fires. This avoids accumulated drift if the UI thread is temporarily busy.

A timeout of zero or less returns immediately with `mrOK` and does not display the dialog.

# Full parameter set

The most complete form of the API is:

```delphi
FUNCTION Countdown(
  CONST Title,Caption,CheckBoxText : STRING;
  VAR Checked : BOOLEAN;
  ms : Integer;
  AllowIgnore : BOOLEAN = TRUE;
  AllowClose : BOOLEAN = FALSE;
  AllowAbort : BOOLEAN = FALSE
) : TModalResult; OVERLOAD;
```

This overload contains the actual dialog implementation. The other overloads ultimately route to this version or to its equivalent `TModalResults` form.

## `Title`

The caption of the countdown window.

Example:

```delphi
'Cooldown'
```

## `Caption`

The explanatory text displayed at the top of the dialog.

Example:

```delphi
'Please wait before performing this operation again.'
```

The dialog widens and grows vertically as necessary to accommodate this text, within the available size limits.

Long captions are word-wrapped automatically. The maximum caption width is 66% of the width of the intended parent form, or 66% of the monitor work area when no parent form is available. The overall dialog height is limited to 80% of the corresponding parent-form or monitor height; space required by the countdown, checkbox, buttons, margins, and the window's non-client area is reserved before determining how much height remains for the caption.

If the complete wrapped caption cannot fit within the available caption area, the text is truncated and `...` is appended.

Line breaks supplied by the caller are respected. CR, LF, CR/LF, and LF/CR input is normalized internally and treated as explicit hard line breaks rather than as ordinary word-wrapping opportunities.

## `CheckBoxText`

The caption of the optional checkbox.

If `CheckBoxText` is an empty string, no checkbox is displayed and the buttons are centered at the bottom of the dialog.

If it is non-empty, the checkbox is displayed left-aligned on the same bottom row as the buttons. The form is widened when necessary to provide room for both the checkbox and the button group, and the buttons are moved to the right side rather than centered.

Example:

```delphi
'Do not show this again'
```

## `Checked`

The initial and final state of the dynamically created checkbox.

Before the dialog is shown, the checkbox receives the value of `Checked`.

When the dialog closes, the current checkbox state is written back to `Checked`.

Example:

```delphi
VAR DontShowAgain:=FALSE;

Countdown(
  'Cooldown',
  'Please wait...',
  'Do not show this again',
  DontShowAgain,
  62000
);
```

After the function returns, `DontShowAgain` contains the state selected by the user.

When `CheckBoxText` is empty, no checkbox is created and `Checked` is not used for UI purposes.

## `ms`

The duration of the countdown in milliseconds.

Example:

```delphi
62000
```

represents 62 seconds.

The parameter is an `Integer`, deliberately allowing negative values. A value less than or equal to zero means that the requested deadline has already passed; in that case the function returns `mrOK` immediately without displaying a dialog.

This is useful when the remaining duration is calculated directly:

```delphi
CONST CooldownSeconds = 62;
VAR Elapsed:=Int64(GetTickCount64-CooldownTimer);

CASE Countdown(
       'Cooldown',
       'Please wait...',
       CooldownSeconds*MilliSecsPerSecond-Elapsed
     ) OF
  TModalResult.Abort : Abort
END;
```

There is therefore no need for the caller to test separately whether the cooldown has already expired.

## `AllowIgnore`

Controls whether the **Ignore** action is available.

Default:

```delphi
TRUE
```

The Ignore button returns:

```delphi
mrIgnore
```

When `AllowIgnore` is `FALSE`, the Ignore button remains part of the dialog layout but is disabled.

## `AllowClose`

Controls whether the user may close the dialog using the normal window close mechanism.

Default:

```delphi
FALSE
```

When disabled, the system-menu close action is removed and the dialog prevents an unintended close result.

When enabled, normal modal-form closing is allowed. In normal VCL modal-form behaviour, closing the window through the system close action results in an `mrClose` return value, rather than `mrOK`.

## `AllowAbort`

Controls whether an **Abort** button is displayed.

Default:

```delphi
FALSE
```

The Abort button returns:

```delphi
mrAbort
```

# Overload families

The API provides overloads along four independent axes:

1. milliseconds or `TTime`;
2. no checkbox, checkbox text plus a Boolean variable, or an existing `TCheckBox`;
3. individual Boolean action parameters or a `TModalResults` set;
4. optional parameters for the commonly used default configuration.

This allows the caller to choose whichever form best matches the data already available.

# Millisecond overloads

The millisecond overloads take:

```delphi
ms : Integer
```

These are the most direct versions when the duration comes from tick counts, elapsed-time calculations, network cooldowns, retry delays, or other code already working in milliseconds.

Without a checkbox:

```delphi
FUNCTION Countdown(
  CONST Title,Caption : STRING;
  ms : Integer;
  AllowIgnore : BOOLEAN = TRUE;
  AllowClose : BOOLEAN = FALSE;
  AllowAbort : BOOLEAN = FALSE
) : TModalResult; OVERLOAD;
```

and:

```delphi
FUNCTION Countdown(
  CONST Title,Caption : STRING;
  ms : Integer;
  CONST Buttons : TModalResults
) : TModalResult; OVERLOAD;
```

With a dynamically created checkbox:

```delphi
FUNCTION Countdown(
  CONST Title,Caption,CheckBoxText : STRING;
  VAR Checked : BOOLEAN;
  ms : Integer;
  AllowIgnore : BOOLEAN = TRUE;
  AllowClose : BOOLEAN = FALSE;
  AllowAbort : BOOLEAN = FALSE
) : TModalResult; OVERLOAD;
```

and:

```delphi
FUNCTION Countdown(
  CONST Title,Caption,CheckBoxText : STRING;
  VAR Checked : BOOLEAN;
  ms : Integer;
  CONST Buttons : TModalResults
) : TModalResult; OVERLOAD;
```

With an existing `TCheckBox` mirrored into the countdown dialog:

```delphi
FUNCTION Countdown(
  CONST Title,Caption : STRING;
  CheckBox : TCheckBox;
  ms : Integer;
  AllowIgnore : BOOLEAN = TRUE;
  AllowClose : BOOLEAN = FALSE;
  AllowAbort : BOOLEAN = FALSE
) : TModalResult; OVERLOAD;
```

and:

```delphi
FUNCTION Countdown(
  CONST Title,Caption : STRING;
  CheckBox : TCheckBox;
  ms : Integer;
  CONST Buttons : TModalResults
) : TModalResult; OVERLOAD;
```

# `TTime` overloads

Every millisecond form also has a `TTime` equivalent.

For example:

```delphi
Countdown('Cooldown','Please wait...',EncodeTime(0,1,2,0));
```

represents one minute and two seconds.

The `TTime` overloads are convenient when the duration already exists as a Delphi time value or when the caller prefers `EncodeTime`.

They deliberately contain special handling for integral values.

Because `TTime` is a floating-point type, Delphi overload resolution can sometimes select the `TTime` overload even when the caller supplies an integer expression. To prevent such a value from being interpreted as a Delphi date/time value, an integral `TTime` value is forwarded to the millisecond overload as an `Integer`.

Conceptually:

```delphi
IF Time<0.0 THEN
  Result:=mrOK
ELSE IF Frac(Time)=0.0 THEN
  Result:=Countdown(...,Integer(Trunc(Time)),...)
ELSE
  Result:=Countdown(...,ConvertedTimeInMilliseconds,...)
```

This preserves the expected meaning of calls involving integer expressions while still allowing genuine `TTime` values.

A negative `TTime` value returns `mrOK` immediately.

The available `TTime` forms are:

```delphi
FUNCTION Countdown(
  CONST Title,Caption : STRING;
  Time : TTime;
  AllowIgnore : BOOLEAN = TRUE;
  AllowClose : BOOLEAN = FALSE;
  AllowAbort : BOOLEAN = FALSE
) : TModalResult; OVERLOAD;
```

```delphi
FUNCTION Countdown(
  CONST Title,Caption : STRING;
  Time : TTime;
  CONST Buttons : TModalResults
) : TModalResult; OVERLOAD;
```

```delphi
FUNCTION Countdown(
  CONST Title,Caption,CheckBoxText : STRING;
  VAR Checked : BOOLEAN;
  Time : TTime;
  AllowIgnore : BOOLEAN = TRUE;
  AllowClose : BOOLEAN = FALSE;
  AllowAbort : BOOLEAN = FALSE
) : TModalResult; OVERLOAD;
```

```delphi
FUNCTION Countdown(
  CONST Title,Caption,CheckBoxText : STRING;
  VAR Checked : BOOLEAN;
  Time : TTime;
  CONST Buttons : TModalResults
) : TModalResult; OVERLOAD;
```

```delphi
FUNCTION Countdown(
  CONST Title,Caption : STRING;
  CheckBox : TCheckBox;
  Time : TTime;
  AllowIgnore : BOOLEAN = TRUE;
  AllowClose : BOOLEAN = FALSE;
  AllowAbort : BOOLEAN = FALSE
) : TModalResult; OVERLOAD;
```

```delphi
FUNCTION Countdown(
  CONST Title,Caption : STRING;
  CheckBox : TCheckBox;
  Time : TTime;
  CONST Buttons : TModalResults
) : TModalResult; OVERLOAD;
```

# Checkbox-less overloads

The simplest overloads omit checkbox parameters completely:

```delphi
Countdown(Title,Caption,ms,...)
```

or:

```delphi
Countdown(Title,Caption,Time,...)
```

These are wrappers around the checkbox-capable implementation.

Internally they pass an empty checkbox caption, causing no checkbox to be created.

Because there is no checkbox occupying the left side of the bottom row, the available buttons are centered.

Use these versions when the countdown only needs to communicate the delay and provide the requested actions.

# `CheckBoxText` and `VAR Checked` overloads

These versions dynamically create a checkbox inside the countdown dialog:

```delphi
Countdown(
  Title,
  Caption,
  CheckBoxText,
  Checked,
  ...
);
```

They are useful when the calling code has a Boolean setting but no existing visual checkbox.

Example:

```delphi
VAR SuppressFutureWarnings:=FALSE;

VAR R:=Countdown(
  'Retry delay',
  'The server is temporarily unavailable.',
  'Do not show this warning again',
  SuppressFutureWarnings,
  30000,
  TRUE,
  FALSE,
  TRUE
);
```

The Boolean value is copied into the checkbox before the dialog is shown and copied back when the dialog closes.

This is the fundamental checkbox-enabled form of the API.

# `TCheckBox` overloads

The `TCheckBox` overloads are convenience wrappers intended for cases where the calling form already contains a checkbox representing the desired option.

Example:

```delphi
Countdown(
  'Cooldown',
  'Please wait...',
  DontShowAgainCheckBox,
  62000
);
```

The countdown dialog does not re-parent or display the original VCL checkbox.

Instead, it mirrors its state:

```delphi
B:=CheckBox.Checked;
Result:=Countdown(...,CheckBox.Caption,B,...);
CheckBox.Checked:=B;
```

Therefore:

- the existing checkbox caption becomes the caption of the temporary countdown checkbox;
- the existing `Checked` value becomes its initial state;
- when the countdown dialog closes, the final value is copied back into the original checkbox.

This is useful when a normal configuration form already contains exactly the option that should also be offered while waiting.

# Individual action parameters

The overloads containing:

```delphi
AllowIgnore : BOOLEAN = TRUE;
AllowClose  : BOOLEAN = FALSE;
AllowAbort  : BOOLEAN = FALSE
```

are convenient when the desired actions are known directly at the call site.

Example:

```delphi
Countdown(
  'Cooldown',
  'Please wait...',
  62000,
  TRUE,   // AllowIgnore
  FALSE,  // AllowClose
  TRUE    // AllowAbort
);
```

This form is especially readable when using named constants or when only the defaults are needed:

```delphi
Countdown('Cooldown','Please wait...',62000);
```

# `TModalResults` action sets

For callers that already work naturally with modal results, corresponding overloads accept:

```delphi
CONST Buttons : TModalResults
```

`TModalResults` is conceptually declared as:

```delphi
TYPE TModalResults = SET OF TModalResult;
```

The countdown implementation recognises the following members:

```delphi
mrIgnore
mrClose
mrAbort
```

They correspond to:

```delphi
mrIgnore IN Buttons  -> AllowIgnore
mrClose  IN Buttons  -> AllowClose
mrAbort  IN Buttons  -> AllowAbort
```

For example:

```delphi
Countdown(
  'Cooldown',
  'Please wait...',
  62000,
  [mrIgnore,mrAbort]
);
```

enables Ignore and Abort while leaving normal window closing disabled.

A close-only configuration can be expressed as:

```delphi
Countdown(
  'Cooldown',
  'Please wait...',
  62000,
  [mrClose]
);
```

The set form is particularly useful when the desired actions are assembled dynamically or stored in a variable:

```delphi
VAR Actions : TModalResults;

Actions:=[mrIgnore];
IF CanAbort THEN Include(Actions,mrAbort);
IF CanClose THEN Include(Actions,mrClose);

Result:=Countdown('Cooldown','Please wait...',62000,Actions);
```

Any `TModalResults` members other than `mrIgnore`, `mrClose`, and `mrAbort` are not used when configuring the countdown dialog.

# Return values

The important return values are:

┌──────────┬───────────────────────────────────────────────────┐
│ Result   │ Meaning                                           │
├──────────┼───────────────────────────────────────────────────┤
│ mrOK     │ The countdown completed normally, or the          │
│          │ supplied duration was already zero/negative.      │
│ mrIgnore │ The user selected Ignore.                         │
│ mrAbort  │ The user selected Abort.                          │
│ mrClose  │ The user closed the form through the normal       │
│          │ window close mechanism when closing was enabled.  │
└──────────┴───────────────────────────────────────────────────┘
The most common pattern is therefore:

```delphi
CASE Countdown(...) OF
  mrAbort  : Abort;
  mrIgnore : { continue immediately };
  mrOK     : { countdown completed }
END;
```

# Dialog sizing and DPI handling

The dialog is created dynamically and uses the monitor containing the current modal or active form to determine its DPI.

Hard-coded layout dimensions are defined as 96-DPI values and passed through a local scaling function.

The dialog width is automatically expanded as necessary for:

- the main caption;
- the widest expected countdown text;
- the minimum button-area width;
- and, when present, the checkbox plus the right-aligned button group.

The main caption is measured as a wrapped rectangular text area rather than as a single line. Its maximum width is 66% of the intended parent form or monitor work-area width. The completed dialog is constrained to 80% of the corresponding parent-form or monitor height.

The layout calculation reserves the space needed for the window's non-client area, margins, countdown row, and button/checkbox row before determining the maximum usable caption height. If the wrapped caption exceeds that remaining space, the longest fitting portion is displayed and terminated with `...`.

Explicit line breaks in the caption are preserved. CR, LF, CR/LF, and LF/CR input are normalized internally to a single hard-break representation before measurement and display.

Without a checkbox, the buttons are centered.

With a checkbox, the checkbox is left-aligned and the buttons are right-aligned on the same row.

# Positioning

`CurrentModalForm` searches the Windows Z-order for the first VCL form whose `FormState` contains `fsModal`.

This is preferable to relying solely on `Screen.ActiveCustomForm`, because a modal form may have displayed a non-modal status or tool window which subsequently became the active form.

The countdown uses the current modal form as its owner and positioning reference when available.

If no modal form exists, it falls back to `Screen.ActiveCustomForm`, and ultimately to the primary monitor.

# Supporting functions

The unit also exposes several small utility functions used by or related to the countdown implementation.

## `CurrentModalForm`

```delphi
FUNCTION CurrentModalForm : TCustomForm;
```

Returns the currently relevant modal VCL form by inspecting Windows Z-order.

Returns `NIL` when no modal VCL form is found.

## `CaptionWidth`

```delphi
FUNCTION CaptionWidth(L : TLabel) : Integer; OVERLOAD;
FUNCTION CaptionWidth(L : TLabel ; CONST Caption : STRING) : Integer; OVERLOAD;
FUNCTION CaptionWidth(F : TFont ; CONST Caption : STRING) : Integer; OVERLOAD;
```

Measures label text using the label's actual font without relying on the label's `AutoSize` property.

The first overload measures `L.Caption`.

The second overload measures an explicitly supplied string using `L.Font`.

The third one take a specific TFont and an explicitly supplied string.

## `ModalStr`

```delphi
FUNCTION ModalStr(R : TModalResult) : STRING;
```

Returns a readable name for the standard VCL modal results.

For example:

```delphi
ModalStr(mrOK)     // 'OK'
ModalStr(mrAbort)  // 'Abort'
ModalStr(mrIgnore) // 'Ignore'
```

Unknown/custom modal-result values are returned in the form:

```text
Custom: <numeric value>
```

# Requirements

The unit uses standard Delphi RTL, WinAPI, and VCL units:

```delphi
WinAPI.Windows,
System.Types,
System.Classes,
System.SysUtils,
System.Math,
System.DateUtils,
System.UITypes,
VCL.Graphics,
VCL.Controls,
VCL.Forms,
VCL.StdCtrls,
VCL.ExtCtrls
```

It is intended for VCL applications running on Windows.

# Version History

```text
┌─────────────┬─────────────┬──────────────────────────────────────────────────────────────┐
│ Date        │ UNIT Name   │ Changes                                                      │
├─────────────┼─────────────┼──────────────────────────────────────────────────────────────┤
│3 Sep 2026   │Countdown    │Initial release.                                              │
├─────────────┼─────────────┼──────────────────────────────────────────────────────────────┤
│29 Sep 2026  │Countdown    │Added long-caption support. Caption text now word-wraps within│
│             │             │a maximum width of 66% of the intended parent form or monitor │
│             │             │work area. The completed dialog is limited to 80% of the     │
│             │             │corresponding height, with space reserved for the title bar,  │
│             │             │countdown, buttons, optional checkbox, gaps, and margins. If  │
│             │             │the full caption cannot fit, it is truncated and terminated  │
│             │             │with "...". Explicit CR, LF, CR/LF, and LF/CR line breaks are │
│             │             │preserved as hard line breaks.                                │
└─────────────┴─────────────┴──────────────────────────────────────────────────────────────┘
```
