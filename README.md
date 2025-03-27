# linux-admin-automation-project

## Part 1: Set up Repository

1. Create Folders

```sudo mkdir -p documentation```

```sudo mkdir -p scripts```

```sudo mkdir -p monitoring```

```sudo mkdir -p config```

```sudo mkdir -p linux-admin-automation-project/{scripts,monitoring,monitoring,documentation}

2. Create Pre-Commit Hook

```sudo touch .git/hook.pre-commit```

```
#!/bin/bash

# Pre-commit Hook Setup Script
mkdir -p .git/hooks
cat > .git/hooks/pre-commit << 'EOL'
#!/bin/bash

# Bash Script Syntax Checking
SCRIPT_ERRORS=0

# Check all shell scripts in the scripts directory
for script in scripts/*.sh; do
    if [ -f "$script" ]; then
        # Perform basic syntax check
        bash -n "$script"
        if [ $? -ne 0 ]; then
            echo "Syntax error in $script"
            SCRIPT_ERRORS=$((SCRIPT_ERRORS + 1))
        fi

        # Additional linting with shellcheck
        shellcheck "$script"
        if [ $? -ne 0 ]; then
            echo "ShellCheck found issues in $script"
            SCRIPT_ERRORS=$((SCRIPT_ERRORS + 1))
        fi
    fi
done

# File permissions check
WRONG_PERMS=$(find scripts/ -type f -not -perm 755)
if [ -n "$WRONG_PERMS" ]; then
    echo "Scripts without executable permissions:"
    echo "$WRONG_PERMS"
    SCRIPT_ERRORS=$((SCRIPT_ERRORS + 1))
fi

# Prevent commit if errors found
if [ $SCRIPT_ERRORS -ne 0 ]; then
    echo "Commit blocked: $SCRIPT_ERRORS script issues found"
    exit 1
fi

exit 0
EOL

# Commit Message Template
mkdir -p .git/templates
cat > .git/templates/commit-template << 'EOL'
# <type>(<scope>): <subject>
# 
# <body>
# 
# Ticket: <ticket-number>
# 
# Type can be:
#   - feat     (new feature)
#   - fix      (bug fix)
#   - docs     (documentation)
#   - style    (formatting)
#   - refactor (code cleanup)
#   - test     (adding tests)
#   - chore    (maintenance)
# 
# Example:
# feat(user-management): add user creation script
# 
# - Implements new user creation functionality
# - Adds input validation
# - Completes user management requirements
# 
# Ticket: LIN-42
EOL

# Git Configuration for Commit Template
git config commit.template .git/templates/commit-template

# Make pre-commit hook executable
chmod +x .git/hooks/pre-commit

# Install shellcheck (for enhanced script checking)
# Uncomment the appropriate line based on your Linux distribution
# Ubuntu/Debian
# sudo apt-get install shellcheck

# CentOS/RHEL
# sudo yum install shellcheck

# Create commit message guidelines documentation
cat > documentation/commit-guidelines.md << 'EOL'
# Git Commit Message Guidelines

## Commit Message Structure
```
<type>(<scope>): <subject>

<body>

Ticket: <ticket-number>
```

## Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code formatting
- `refactor`: Code restructuring
- `test`: Adding or modifying tests
- `chore`: Maintenance tasks

## Examples

### Feature Commit
```
feat(user-management): implement user creation script

- Adds new script for user management
- Includes input validation
- Follows security best practices

Ticket: LIN-42
```

### Bug Fix Commit
```
fix(network-monitor): resolve connectivity test failure

- Corrected timeout handling
- Improved error logging
- Enhanced network test reliability

Ticket: LIN-56
```

## Best Practices
1. Use imperative mood in subject line
2. Capitalize first letter
3. No period at the end of subject
4. Explain "why" in the body, not "how"
5. Reference relevant tickets
6. Keep subject line under 50 characters
7. Wrap body at 72 characters
```
EOL

echo "Git hooks and commit standards setup complete!"

```

## Part 2: Linux Administration 
