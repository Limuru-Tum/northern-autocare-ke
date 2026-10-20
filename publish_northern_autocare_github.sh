#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT="${HOME}/Desktop/northern-autocare-ke"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="${HOME}/Desktop/northern-autocare-github-backup-${TIMESTAMP}"

log() { printf '[%s] %s\n' "$1" "$2"; }
die() { log error "$1" >&2; exit 1; }

[[ -d "$PROJECT" ]] || die "Project folder not found: $PROJECT"
cd "$PROJECT"
[[ -f package.json ]] || die "package.json not found in $PROJECT"
[[ -f package-lock.json ]] || die "package-lock.json not found; run npm install in the project first."
[[ -f src/App.tsx || -f src/App.jsx ]] || die "Could not find src/App.tsx or src/App.jsx. Stopping without changes."
command -v git >/dev/null 2>&1 || die "Git is not installed. Install it first, then rerun this script."
command -v npm >/dev/null 2>&1 || die "npm is not installed."

# Verify the package has a production build command.
node - <<'NODE'
const fs = require('node:fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
if (!pkg.scripts || !pkg.scripts.build) {
  console.error('[error] package.json has no build script.');
  process.exit(1);
}
NODE

# Do not publish local environment files by accident.
mapfile -t ENV_FILES < <(find . \
  -path './.git' -prune -o \
  -path './node_modules' -prune -o \
  -path './dist' -prune -o \
  -type f \( -name '.env' -o -name '.env.*' \) ! -name '.env.example' -print)
if ((${#ENV_FILES[@]})); then
  printf '\n[warning] Found environment files that could contain secrets:\n'
  printf '  %s\n' "${ENV_FILES[@]}"
  die "Move these files outside the project or confirm they contain no secrets and are properly ignored before publishing. No push was attempted."
fi

# Determine the GitHub target safely: reuse an existing origin, use gh CLI when
# authenticated, or ask for an already-created empty GitHub repository URL.
REMOTE_URL=""
OWNER=""
REPO=""
USE_GH=0
CREATE_REPO=0

if [[ -d .git ]]; then
  REMOTE_URL="$(git remote get-url origin 2>/dev/null || true)"
fi

if [[ -n "$REMOTE_URL" ]]; then
  log info "Existing origin detected: $REMOTE_URL"
else
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    USE_GH=1
    OWNER="$(gh api user --jq .login)"
    read -r -p "GitHub repository name [northern-autocare-ke]: " REPO
    REPO="${REPO:-northern-autocare-ke}"
    [[ "$REPO" =~ ^[A-Za-z0-9._-]+$ ]] || die "Invalid repository name: $REPO"
    REMOTE_URL="https://github.com/${OWNER}/${REPO}.git"
    if gh repo view "${OWNER}/${REPO}" >/dev/null 2>&1; then
      log info "Repository already exists: https://github.com/${OWNER}/${REPO}"
    else
      CREATE_REPO=1
    fi
  else
    cat <<'HELP'
GitHub CLI (gh) is not available/authenticated, so create the repository in your browser first:
  1. Open https://github.com/new
  2. Repository name: northern-autocare-ke (or another name you prefer)
  3. Choose Public if you want everyone, including the workshop managers, to open the site.
  4. Leave “Add a README”, .gitignore, and license unchecked so the repository is empty.
  5. Click Create repository, then paste its HTTPS or SSH URL below.
HELP
    read -r -p "GitHub repository URL: " REMOTE_URL
  fi
fi

# Parse GitHub owner/repository from HTTPS or SSH URL.
URL_FOR_PARSE="${REMOTE_URL%.git}"
if [[ "$URL_FOR_PARSE" =~ ^https://github\.com/([^/]+)/([^/]+)/?$ ]]; then
  OWNER="${BASH_REMATCH[1]}"
  REPO="${BASH_REMATCH[2]}"
elif [[ "$URL_FOR_PARSE" =~ ^git@github\.com:([^/]+)/([^/]+)/?$ ]]; then
  OWNER="${BASH_REMATCH[1]}"
  REPO="${BASH_REMATCH[2]}"
else
  die "Unrecognized GitHub URL: $REMOTE_URL. Use https://github.com/OWNER/REPO or git@github.com:OWNER/REPO.git."
fi
REPO="${REPO%.git}"

# Initialize Git only if this project does not already have a repository.
if [[ ! -d .git ]]; then
  git init -b main
  log ok "Initialized Git on branch main."
fi
BRANCH="$(git branch --show-current 2>/dev/null || true)"
if [[ -z "$BRANCH" ]]; then
  git checkout -b main
  BRANCH="main"
fi

# Refuse to redirect an existing origin to a different repository.
EXISTING_ORIGIN="$(git remote get-url origin 2>/dev/null || true)"
if [[ -n "$EXISTING_ORIGIN" && "$EXISTING_ORIGIN" != "$REMOTE_URL" ]]; then
  die "Existing origin is '$EXISTING_ORIGIN' but the requested target is '$REMOTE_URL'. No remote was changed. To avoid overwriting another repo, inspect 'git remote -v' and rerun with the matching target."
fi

mkdir -p "$BACKUP/.github/workflows"
if [[ -f .gitignore ]]; then cp .gitignore "$BACKUP/.gitignore"; else : > "$BACKUP/.gitignore.missing"; fi
if [[ -f .github/workflows/deploy-pages.yml ]]; then cp .github/workflows/deploy-pages.yml "$BACKUP/.github/workflows/deploy-pages.yml"; fi
log backup "Saved files being updated to $BACKUP"

# Append safe ignore rules without rewriting the existing ignore file.
touch .gitignore
for pattern in \
  'node_modules/' \
  'dist/' \
  'coverage/' \
  '.env' \
  '.env.*' \
  '!.env.example' \
  '.repair-backups/' \
  '.vite/' \
  '.DS_Store'; do
  grep -Fqx "$pattern" .gitignore || printf '%s\n' "$pattern" >> .gitignore
done
log fix "Ensured dependencies, build output, local env files, and local backup folders are ignored."

mkdir -p .github/workflows
cat > .github/workflows/deploy-pages.yml <<'WORKFLOW'
name: Deploy Northern Autocare KE to GitHub Pages

on:
  push:
    branches: ["__DEPLOY_BRANCH__"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: github-pages
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm

      - name: Configure GitHub Pages
        uses: actions/configure-pages@v5

      - name: Install dependencies
        run: npm ci

      - name: Build Vite site for GitHub Pages
        env:
          GITHUB_REPOSITORY: ${{ github.repository }}
        run: |
          REPO_NAME="${GITHUB_REPOSITORY#*/}"
          OWNER_NAME="${GITHUB_REPOSITORY%%/*}"
          if [[ "$REPO_NAME" == "$OWNER_NAME.github.io" ]]; then
            BASE_PATH="/"
          else
            BASE_PATH="/${REPO_NAME}/"
          fi
          echo "Building with Vite base path: $BASE_PATH"
          npm run build -- --base="$BASE_PATH"

      - name: Upload site artifact
        uses: actions/upload-pages-artifact@v4
        with:
          path: dist

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
WORKFLOW
# Replace only the branch placeholder. Restrict branch names to characters safe for this line.
[[ "$BRANCH" =~ ^[A-Za-z0-9._/-]+$ ]] || die "Branch name contains characters this script cannot safely place in the workflow: $BRANCH"
sed -i "s|__DEPLOY_BRANCH__|$BRANCH|g" .github/workflows/deploy-pages.yml
log fix "Added the GitHub Actions workflow for building and deploying the Vite app."

# Run a local production build before any commit/push. GitHub Pages uses the repo subpath
# unless this is the account-level USER.github.io repository.
if [[ "$REPO" == "$OWNER.github.io" ]]; then
  BASE_PATH="/"
else
  BASE_PATH="/${REPO}/"
fi
log check "Running local production build with base path $BASE_PATH"
npm run build -- --base="$BASE_PATH"
log ok "Local production build passed."

# Create a new GitHub repo only after local preflight succeeds.
if (( USE_GH == 1 )); then
  if (( CREATE_REPO == 1 )); then
    gh repo create "${OWNER}/${REPO}" --public --description "Northern Autocare KE — automotive services website in Lodwar, Kenya"
    log ok "Created public repository https://github.com/${OWNER}/${REPO}"
  else
    VISIBILITY="$(gh repo view "${OWNER}/${REPO}" --json visibility --jq .visibility 2>/dev/null || true)"
    if [[ "$VISIBILITY" == "PRIVATE" ]]; then
      log warning "The existing repo is private. The deployed Pages site may not be available on all GitHub plans. Check your GitHub Pages plan/settings before proceeding."
    fi
  fi
fi

if [[ -z "$(git remote get-url origin 2>/dev/null || true)" ]]; then
  git remote add origin "$REMOTE_URL"
fi

# Ensure we do not force-push or overwrite remote history.
git add -A
if git diff --cached --quiet; then
  log info "No new changes to commit; existing commit will be pushed."
else
  git commit -m "Prepare Northern Autocare KE for GitHub Pages"
fi

log check "Pushing branch '$BRANCH' to $REMOTE_URL (no force push)."
git push -u origin "$BRANCH"

# If authenticated gh CLI is available, try enabling Pages via the API. Otherwise user can do it in Settings.
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  if gh api --method POST "repos/${OWNER}/${REPO}/pages" -f build_type=workflow >/dev/null 2>&1; then
    log ok "Enabled GitHub Pages using the GitHub API."
  elif gh api --method PUT "repos/${OWNER}/${REPO}/pages" -f build_type=workflow -f "source[branch]=${BRANCH}" -f 'source[path]=/' >/dev/null 2>&1; then
    log ok "Configured existing GitHub Pages site to use GitHub Actions."
  else
    log warning "Could not enable Pages automatically. Enable it manually: repository Settings → Pages → Build and deployment → Source → GitHub Actions."
  fi
else
  log warning "Enable Pages manually: repository Settings → Pages → Build and deployment → Source → GitHub Actions."
fi

printf '\n[done] Source pushed to GitHub.\n'
printf 'Repository: https://github.com/%s/%s\n' "$OWNER" "$REPO"
if [[ "$REPO" == "$OWNER.github.io" ]]; then
  printf 'Expected website URL: https://%s.github.io/\n' "$OWNER"
else
  printf 'Expected website URL: https://%s.github.io/%s/\n' "$OWNER" "$REPO"
fi

cat <<'NEXT'

NEXT STEPS
1. Open the repository's Actions tab and check the “Deploy Northern Autocare KE to GitHub Pages” workflow.
2. If the workflow did not start or Pages is not enabled, open Settings → Pages and choose “GitHub Actions” as the source.
3. Wait for the workflow to finish successfully, then open the website URL shown above.
4. If the workflow fails, open its log and share the first actual error; do not force-push.

Note: this initial deployment workflow runs the production build (including TypeScript). The current Vitest lazy-booking test issue is not used as a deployment gate, so we can get the demo online while fixing that test separately. Before wider production use, resolve the test failure and add npm run test to the workflow.
NEXT
