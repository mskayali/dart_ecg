# Handoff — NeuroKit ECG to Dart Port Agent

## 1. Handoff Purpose

This document defines how work is transferred between agents, developers, reviewers, and production maintainers while porting the ECG processing portion of NeuroKit2 into a Dart package.

The handoff process must preserve algorithmic fidelity, numerical traceability, source-code provenance, test evidence, API decisions, and production readiness state.

The target output is a Dart ECG processing library that mirrors NeuroKit2 ECG behavior where practical, while using Dart-native data structures, deterministic tests, clear API contracts, and deployment-ready package conventions.

---

## 2. Source Baseline

Primary upstream source:

```text
https://github.com/neuropsychology/NeuroKit
```

ECG module source path:

```text
neurokit2/ecg/
```

Observed ECG source files from the upstream repository structure:

```text
neurokit2/ecg/__init__.py
neurokit2/ecg/ecg_analyze.py
neurokit2/ecg/ecg_clean.py
neurokit2/ecg/ecg_delineate.py
neurokit2/ecg/ecg_eventrelated.py
neurokit2/ecg/ecg_findpeaks.py
neurokit2/ecg/ecg_intervalrelated.py
neurokit2/ecg/ecg_invert.py
neurokit2/ecg/ecg_peaks.py
neurokit2/ecg/ecg_phase.py
neurokit2/ecg/ecg_plot.py
neurokit2/ecg/ecg_process.py
neurokit2/ecg/ecg_quality.py
neurokit2/ecg/ecg_rsp.py
neurokit2/ecg/ecg_segment.py
neurokit2/ecg/ecg_simulate.py
```

Reference documentation:

```text
https://neuropsychology.github.io/NeuroKit/functions/ecg.html
```

Every implementation handoff must record the exact upstream revision used:

```text
UPSTREAM_REPO=https://github.com/neuropsychology/NeuroKit
UPSTREAM_BRANCH_OR_TAG=<branch/tag/commit>
UPSTREAM_COMMIT=<full_commit_hash>
UPSTREAM_ECG_PATH=neurokit2/ecg/
UPSTREAM_DOC_VERSION=<doc_version_if_available>
HANDOFF_DATE=<yyyy-mm-dd>
HANDOFF_OWNER=<agent_or_person>
```

If no commit hash is pinned, the handoff is incomplete.

---

## 3. Handoff Roles

### 3.1 Source Analysis Agent

Responsibilities:

- Inspect NeuroKit2 ECG Python code.
- Identify public functions, internal helpers, method variants, default parameters, edge-case behavior, warnings, exceptions, and returned structures.
- Extract algorithm notes without copying unnecessary Python implementation details.
- Produce source maps for each Python file.
- Mark unsupported, ambiguous, or dependency-heavy behavior.

Required output:

```text
artifacts/source_maps/<module_name>.source_map.md
artifacts/source_maps/<module_name>.call_graph.md
artifacts/source_maps/<module_name>.parameter_contract.md
```

### 3.2 DSP Port Agent

Responsibilities:

- Convert ECG signal-processing logic into Dart.
- Replace NumPy/SciPy/Pandas behavior with Dart-native equivalents.
- Implement filtering, convolution, interpolation, peak detection, thresholding, segmentation, and numerical helpers.
- Preserve deterministic behavior.
- Avoid hidden global state.

Required output:

```text
lib/src/ecg/*.dart
lib/src/signal/*.dart
test/golden/*.json
test/ecg/*_test.dart
```

### 3.3 API Design Agent

Responsibilities:

- Define Dart public API surface.
- Keep naming readable for Dart users while maintaining traceability to NeuroKit2 names.
- Decide whether to expose synchronous, streaming, or isolate-friendly variants.
- Keep low-level methods available for embedded and IoT workflows.

Required output:

```text
lib/neurokit_ecg.dart
lib/src/ecg/ecg_result.dart
docs/api_mapping.md
```

### 3.4 Validation Agent

Responsibilities:

- Generate Python reference outputs from pinned NeuroKit2 source.
- Compare Dart outputs against Python outputs.
- Define tolerances per method.
- Maintain golden fixtures.
- Record known deviations.

Required output:

```text
test/golden/reference_manifest.json
test/golden/ecg_process/*.json
test/golden/ecg_clean/*.json
test/golden/ecg_peaks/*.json
docs/validation_report.md
```

### 3.5 Production Agent

Responsibilities:

- Check package layout, linting, CI, documentation, examples, changelog, license notes, and publish readiness.
- Verify performance constraints for mobile, desktop, server, and embedded use cases.
- Confirm no accidental Python runtime dependency remains.

Required output:

```text
pubspec.yaml
analysis_options.yaml
.github/workflows/ci.yml
CHANGELOG.md
LICENSE_NOTICE.md
```

---

## 4. Handoff Package Format

Every handoff package must be a directory with this shape:

```text
handoffs/
└── <yyyy-mm-dd>_<module>_<handoff_id>/
    ├── HANDOFF.md
    ├── source_revision.txt
    ├── scope.md
    ├── decisions.md
    ├── blockers.md
    ├── validation_summary.md
    ├── changed_files.txt
    ├── test_results.txt
    ├── benchmark_results.txt
    └── artifacts/
        ├── source_maps/
        ├── golden_inputs/
        ├── golden_outputs/
        └── screenshots_or_plots/
```

Minimum valid package:

```text
HANDOFF.md
source_revision.txt
scope.md
changed_files.txt
test_results.txt
```

No work can be handed off with only code changes and no notes.

---

## 5. Standard Handoff Template

Each handoff `HANDOFF.md` must use this template:

```markdown
# Handoff: <module_or_feature>

## Summary
<what changed>

## Upstream Reference
- Repository: <url>
- Commit: <hash>
- Source files:
  - <file>

## Dart Target
- Package path: <path>
- Public API: <symbols>
- Internal API: <symbols>

## Completed Work
- [x] <item>

## Incomplete Work
- [ ] <item>

## Algorithm Notes
<important equations, thresholds, assumptions, method branches>

## Parameter Mapping
| Python parameter | Dart parameter | Default | Notes |
|---|---|---:|---|

## Return Mapping
| Python output | Dart output | Notes |
|---|---|---|

## Numerical Tolerance
| Output | Tolerance | Justification |
|---|---:|---|

## Test Evidence
- Unit tests: <status>
- Golden tests: <status>
- Property tests: <status>
- Performance tests: <status>

## Known Deviations
| Area | Deviation | Reason | Risk |
|---|---|---|---|

## Blockers
- <blocker or none>

## Next Agent Instructions
<exact next steps>
```

---

## 6. ECG Module Handoff Boundaries

### 6.1 `ecg_clean`

Handoff must include:

- Supported methods.
- Filter type and filter order.
- Bandpass/highpass/lowpass cutoff behavior.
- Padding strategy.
- NaN handling.
- Sampling-rate assumptions.
- Numerical comparison against Python output.

Expected Dart targets:

```text
lib/src/ecg/ecg_clean.dart
lib/src/signal/signal_filter.dart
lib/src/signal/filter_design.dart
lib/src/signal/signal_sanitize.dart
```

Required tests:

```text
test/ecg/ecg_clean_test.dart
test/golden/ecg_clean/*.json
```

### 6.2 `ecg_findpeaks` and `ecg_peaks`

Handoff must include:

- Detector methods.
- Method-specific thresholds.
- Refractory period rules.
- Peak correction rules.
- Returned peak indices.
- Binary peak signal construction.
- Artifact correction behavior.

Expected Dart targets:

```text
lib/src/ecg/ecg_findpeaks.dart
lib/src/ecg/ecg_peaks.dart
lib/src/signal/signal_findpeaks.dart
lib/src/signal/peak_correction.dart
```

Required tests:

```text
test/ecg/ecg_findpeaks_test.dart
test/ecg/ecg_peaks_test.dart
test/golden/ecg_peaks/*.json
```

### 6.3 `ecg_rate`

Handoff must include:

- RRI calculation.
- Instantaneous heart-rate interpolation.
- Output length behavior.
- Missing peak behavior.
- Sampling-rate conversion.

Expected Dart targets:

```text
lib/src/ecg/ecg_rate.dart
lib/src/signal/signal_interpolate.dart
```

Required tests:

```text
test/ecg/ecg_rate_test.dart
test/golden/ecg_rate/*.json
```

### 6.4 `ecg_quality`

Handoff must include:

- Supported quality methods.
- Signal quality index semantics.
- Windowing behavior.
- Degraded-signal behavior.
- Whether output is scalar, vector, or label-like.

Expected Dart targets:

```text
lib/src/ecg/ecg_quality.dart
lib/src/ecg/ecg_quality_result.dart
```

Required tests:

```text
test/ecg/ecg_quality_test.dart
test/golden/ecg_quality/*.json
```

### 6.5 `ecg_delineate`

Handoff must include:

- Supported delineation methods.
- P, Q, R, S, T peak/onset/offset mapping.
- Wavelet, derivative, or peak-based assumptions.
- Missing-wave behavior.
- Output index conventions.

Expected Dart targets:

```text
lib/src/ecg/ecg_delineate.dart
lib/src/ecg/ecg_waves.dart
lib/src/signal/wavelet.dart
```

Required tests:

```text
test/ecg/ecg_delineate_test.dart
test/golden/ecg_delineate/*.json
```

### 6.6 `ecg_phase`

Handoff must include:

- Atrial and ventricular phase logic.
- Completion percentage behavior.
- Required delineation inputs.
- Missing delineation fallback behavior.

Expected Dart targets:

```text
lib/src/ecg/ecg_phase.dart
lib/src/ecg/ecg_phase_result.dart
```

Required tests:

```text
test/ecg/ecg_phase_test.dart
test/golden/ecg_phase/*.json
```

### 6.7 `ecg_process`

Handoff must include:

- Complete pipeline order.
- Default method values.
- Signals table equivalent.
- Info dictionary equivalent.
- Error behavior when a stage fails.
- Optional stage toggles, if introduced in Dart.

Expected Dart targets:

```text
lib/src/ecg/ecg_process.dart
lib/src/ecg/ecg_process_result.dart
lib/neurokit_ecg.dart
```

Required tests:

```text
test/ecg/ecg_process_test.dart
test/golden/ecg_process/*.json
```

---

## 7. Python-to-Dart Data Handoff

### 7.1 Python Structures

Common NeuroKit2 Python structures:

```text
list
numpy.ndarray
pandas.Series
pandas.DataFrame
dict
None
NaN
```

### 7.2 Dart Structures

Preferred Dart equivalents:

```text
List<double>
List<int>
List<bool>
Map<String, Object?>
class-based result objects
nullable fields
Double.nan only where mathematically unavoidable
```

### 7.3 DataFrame Replacement Rule

Do not create a generic DataFrame clone unless required.

For `ecg_process`, prefer:

```dart
class EcgProcessResult {
  final List<double> raw;
  final List<double> clean;
  final List<int> rPeaks;
  final List<double> rate;
  final EcgQualityResult? quality;
  final EcgDelineateResult? delineation;
  final EcgPhaseResult? phase;
  final Map<String, Object?> info;
}
```

For tabular export, provide adapters:

```dart
Map<String, List<num?>> toColumns();
List<Map<String, num?>> toRows();
```

The internal implementation should not depend on table-like dynamic structures.

---

## 8. Numerical Handoff Rules

### 8.1 Tolerance Classes

Use these default tolerance classes unless a module-specific reason overrides them:

```text
Exact index match:
  peak locations, onset/offset indices, segment boundaries

Small absolute tolerance:
  filtered signal, interpolated rate, quality score

Small relative tolerance:
  energy-like values, normalized scores, moving averages

Behavioral equivalence:
  warning paths, fallback selection, missing-signal handling
```

Recommended initial thresholds:

```text
filtered_signal_abs_tolerance = 1e-6 to 1e-4
heart_rate_abs_tolerance = 1e-3 to 1e-1
quality_score_abs_tolerance = 1e-4 to 1e-2
peak_index_tolerance = 0 samples unless documented
wave_boundary_tolerance = 0 to 3 samples depending on method
```

Any tolerance larger than these values requires written justification in `validation_summary.md`.

### 8.2 Floating-Point Notes

Dart `double` is IEEE-754 double precision. Python NumPy usually uses double precision for common operations, but differences can appear due to:

- filter coefficient calculation,
- convolution boundary handling,
- interpolation method,
- sort stability,
- NaN propagation,
- integer rounding,
- peak tie-breaking.

The handoff must identify the source of every non-trivial deviation.

---

## 9. Golden Fixture Handoff

Golden fixtures must be JSON to remain language-neutral.

Fixture layout:

```text
test/golden/
├── manifest.json
├── signals/
│   ├── synthetic_clean_250hz.json
│   ├── synthetic_noisy_250hz.json
│   ├── short_signal_250hz.json
│   └── irregular_peaks_500hz.json
├── ecg_clean/
├── ecg_peaks/
├── ecg_rate/
├── ecg_quality/
├── ecg_delineate/
├── ecg_phase/
└── ecg_process/
```

Each fixture must contain:

```json
{
  "fixture_id": "synthetic_clean_250hz_neurokit_clean",
  "upstream_commit": "<hash>",
  "source_function": "ecg_clean",
  "method": "neurokit",
  "sampling_rate": 250,
  "input_signal": [0.0],
  "expected": [0.0],
  "metadata": {
    "created_by": "reference_generation_agent",
    "created_at": "yyyy-mm-dd",
    "python_version": "<version>",
    "neurokit_version": "<version>",
    "numpy_version": "<version>",
    "scipy_version": "<version>"
  }
}
```

Large fixtures may split input and expected output into separate files, but the manifest must reference both.

---

## 10. Decision Handoff

Every non-obvious design decision must be recorded in `decisions.md`.

Use this format:

```markdown
## Decision <number>: <title>

Date: <yyyy-mm-dd>
Owner: <agent/person>
Status: proposed | accepted | superseded

### Context
<why the decision exists>

### Decision
<what was chosen>

### Alternatives
- <alternative>

### Consequences
- <positive or negative consequence>

### Validation Needed
- <test, benchmark, or review required>
```

Examples of decisions requiring records:

- Not supporting a NeuroKit2 method in first release.
- Replacing Pandas DataFrame output with class-based result objects.
- Using a different interpolation implementation.
- Introducing a streaming API.
- Relaxing peak-index tolerance.
- Omitting plotting functions from the Dart package.
- Handling `NaN` differently from NumPy.

---

## 11. Blocker Handoff

Blockers must be classified:

```text
B0 — prevents build or package import
B1 — prevents algorithm correctness
B2 — prevents validation confidence
B3 — prevents production release
B4 — documentation or polish issue
```

Blocker format:

```markdown
## Blocker <id>

Severity: B0 | B1 | B2 | B3 | B4
Owner: <agent/person>
Module: <module>
Status: open | mitigated | resolved

### Problem
<clear description>

### Evidence
<test failure, missing source detail, numerical mismatch>

### Required Action
<exact next step>
```

A handoff with B0 or B1 blockers cannot be marked implementation-complete.

---

## 12. Review Handoff Gates

### 12.1 Analysis Complete Gate

Required:

- Source files listed.
- Public functions listed.
- Internal helpers listed.
- Dependencies listed.
- Default parameters extracted.
- Return structures mapped.
- Algorithm branches identified.

### 12.2 Implementation Complete Gate

Required:

- Dart code compiles.
- Public API documented.
- No Python runtime dependency.
- No unreviewed dynamic typing in core signal code.
- Unit tests exist.
- Golden fixtures exist or are explicitly deferred.

### 12.3 Validation Complete Gate

Required:

- Python reference outputs generated from pinned upstream commit.
- Dart outputs compared.
- Tolerance table approved.
- Deviations documented.
- CI test pass recorded.

### 12.4 Production Ready Gate

Required:

- `dart analyze` passes.
- `dart test` passes.
- Package examples run.
- README usage works.
- License and attribution notes complete.
- Changelog entry exists.
- Performance baseline recorded.

---

## 13. Handoff Checklist

Before handing off, the current agent must verify:

```text
[ ] Upstream commit pinned.
[ ] Source files inspected.
[ ] Dart files listed.
[ ] Public API changes documented.
[ ] Parameter mapping complete.
[ ] Return mapping complete.
[ ] Test results attached.
[ ] Golden fixtures attached or deferred with reason.
[ ] Known deviations documented.
[ ] Blockers classified.
[ ] Next steps are explicit.
[ ] No generated file is missing from changed_files.txt.
[ ] No source-derived code lacks attribution notes.
```

---

## 14. Next-Agent Instruction Format

Never hand off vague instructions such as:

```text
Continue implementation.
Fix tests.
Improve accuracy.
```

Use exact instructions:

```text
Implement lib/src/ecg/ecg_rate.dart.
Use R-peak indices from EcgPeaksResult.rPeaks.
Compute RR intervals in milliseconds from sample distance and samplingRate.
Interpolate instantaneous rate to signalLength using linear interpolation.
Compare against test/golden/ecg_rate/synthetic_clean_250hz.json.
Expected tolerance: abs <= 0.05 bpm.
Update docs/api_mapping.md after implementation.
```

---

## 15. Handoff Failure Conditions

Reject a handoff if any of these are true:

- Upstream source revision is missing.
- The implementation claims equivalence without tests.
- Numerical tolerance is widened without explanation.
- Public API differs from documentation.
- Missing functions are not listed as deferred.
- A blocker is hidden in prose instead of listed in `blockers.md`.
- Generated golden files do not include provenance.
- Dart code depends on Python, NumPy, SciPy, or Pandas at runtime.
- License or attribution obligations are ignored.

---

## 16. Final Handoff Summary Format

When an agent finishes a stage, the final message to the next owner must be short and machine-readable:

```text
HANDOFF_ID=<yyyy-mm-dd_module_id>
MODULE=<module>
STATUS=analysis_complete|implementation_complete|validation_complete|blocked
UPSTREAM_COMMIT=<hash>
CHANGED_FILES=<path1,path2,path3>
TESTS=<passed|failed|not_run>
BLOCKERS=<none|B0:...,B1:...>
NEXT=<one exact next action>
```

Example:

```text
HANDOFF_ID=2026-05-13_ecg_rate_001
MODULE=ecg_rate
STATUS=implementation_complete
UPSTREAM_COMMIT=abc123...
CHANGED_FILES=lib/src/ecg/ecg_rate.dart,test/ecg/ecg_rate_test.dart
TESTS=passed
BLOCKERS=none
NEXT=Run Python-vs-Dart golden comparison for synthetic_noisy_250hz fixture.
```

---

## 17. Operational Principle

A valid handoff must let the next agent continue without re-discovering context.

The next owner should know:

- what upstream code was used,
- what Dart files changed,
- what behavior was intended,
- what was validated,
- what remains risky,
- what exact next action is required.

If any of these are unclear, the handoff is not complete.
