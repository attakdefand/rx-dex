# Branch Protection Rules

This document outlines the branch protection rules that should be configured for the RX-DEX repository.

## Master Branch Protection

The `master` branch should have the following protection rules configured in GitHub:

### Required Status Checks
- CI workflow must pass before merging
- All conversations on code reviews must be resolved

### Required Pull Request Reviews
- At least 1 approved review is required
- Code owners review is required for specific paths:
  - `services/**` - Requires approval from backend team
  - `clients/**` - Requires approval from frontend team
  - `contracts/**` - Requires approval from smart contract team

### Required Commit Signing
- All commits must be signed

### Branch Restrictions
- Only administrators can push directly to `master`
- Force pushes are disabled

### Additional Rules
- Include administrators in restrictions
- Allow deletions is disabled
- Allow force pushes is disabled

## Configuration Steps

To configure these rules in GitHub:

1. Go to the repository settings
2. Click on "Branches" in the left sidebar
3. Under "Branch protection rules", click "Add rule"
4. Set the branch name pattern to `master`
5. Enable the following options:
   - Require status checks to pass before merging
   - Require branches to be up to date before merging
   - Require pull request reviews before merging
   - Require review from Code Owners
   - Require signed commits
   - Restrict who can push to matching branches
   - Include administrators
6. Save the changes