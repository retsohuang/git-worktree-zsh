# Agent OS Configuration

Configure actions that run after individual task completion.

## Configuration File

Edit `post-task-actions.yml` to customize post-task behavior:

### Quick Start

1. **Enable basic logging**: Set `enabled: true` for `completion_log`
2. **Add custom actions**: Copy an example and modify it
3. **Test**: Run a task and check if actions execute

### Structure

```yaml
# Global actions run after every task
global_actions:
  - name: action_name
    type: log|sound|prompt|command
    enabled: true
    description: What this action does

# Conditional actions run when conditions match
conditional_actions:
  - name: action_name
    enabled: true
    condition:
      # when to run
    action:
      # what to do
```

### Action Types

- **`log`**: Record task completion
- **`sound`**: Play notification sound
- **`prompt`**: Execute AI prompt with task context
- **`command`**: Run shell command

### Conditions

Target specific tasks:
```yaml
# Task description contains word
task_description_contains: test

# Modified files match pattern
files_modified_pattern: src/*

# Multiple conditions (any match)
OR:
  - task_description_contains: auth
  - files_modified_pattern: "*auth*"

# Multiple conditions (all match)
AND:
  - files_modified_pattern: src/components/*
  - task_description_contains: implement
```

### Context Variables

Use task information in actions:
- `{{TASK_DESCRIPTION}}` - What the task does
- `{{FILES_MODIFIED}}` - Which files changed
- `{{COMPLETION_STATUS}}` - Success/blocked status
- `{{SPEC_FOLDER}}` - Current specification

### Examples

**Enable completion sound:**
```yaml
- name: completion_sound
  type: sound
  enabled: true
  sound_file: /System/Library/Sounds/Ping.aiff
```

**Review React components:**
```yaml
- name: react_review
  enabled: true
  condition:
    files_modified_pattern: src/components/*
  action:
    type: prompt
    content: Review React components: {{FILES_MODIFIED}}
```

**Run tests after implementation:**
```yaml
- name: test_after_impl
  enabled: true
  condition:
    task_description_contains: implement
  action:
    type: command
    content: npm test
```

## Configuration Priority

1. **Spec-specific**: `[spec-folder]/post-task-actions.yml` (highest)
2. **Global**: `.agent-os/config/post-task-actions.yml`
3. **Default**: Minimal actions if no config found

## Getting Started

1. Edit `post-task-actions.yml`
2. Set some actions to `enabled: true`
3. Run a task to test the configuration
4. Check `.agent-os/logs/` for execution logs

## Tips

- Use `#` for comments in YAML
- Indentation matters (use spaces, not tabs)
- Strings with special characters need quotes
- Multi-line content uses `|` or `>`