# Contract: Clipboard Capture Pipeline

## Trigger

- Monitoring starts when NextPaste launches.
- Monitoring stops only when NextPaste terminates.
- While the app is running, clipboard changes are evaluated even if the app is backgrounded or minimized.

## Pipeline

```text
Clipboard Changed
  -> Detect
  -> Validate
  -> Deduplicate
  -> Persist
  -> Refresh UI
```

## Stage Requirements

### Detect

- Observe clipboard state changes from the system pasteboard.
- Read text content only for this feature.
- Ignore unchanged pasteboard versions.

### Validate

- Ignore non-text clipboard content.
- Ignore empty strings.
- Ignore whitespace-only strings after trimming for validation.

### Deduplicate

- Compare the candidate text against saved local text clips.
- Treat exact text equality as a duplicate.
- If duplicate, leave history unchanged.

### Persist

- Create one new local `ClipItem` for each valid distinct observed text value.
- Save through SwiftData.
- Keep capture local-first and on-device only.

### Refresh UI

- The history list must refresh in the same app session after a successful save.
- The new history entry is the only required visible confirmation of capture.
- No separate notification, toast, analytics event, or remote callback is required.

## Failure / Skip Contract

- If detection yields non-text, empty, whitespace-only, or duplicate text, persistence must be skipped and history must remain unchanged.
- If persistence fails, the app must not insert a partial or duplicate history item.
- Clipboard monitoring must not break existing manual clip creation or row actions.
