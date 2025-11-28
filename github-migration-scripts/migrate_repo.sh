#!/bin/bash
set -euo pipefail

origin_repo="$1"
target_repo="$2"
origin_name="$(basename "${origin_repo}" .git)"
target_name="$(basename "${target_repo}" .git)"

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <origin_repo_url> <target_repo_url>"
  exit 1
fi

echo "[INFO] Migrating ${origin_repo} to ${target_repo}"
echo "[INFO] Backing up existing repositories"

mkdir -p backup
cd backup

echo "[INFO] Backing up origin repo..."
rm -rf origin-backup.git || true
git clone --mirror "${origin_repo}" "${origin_name}-backup.git"

echo "[INFO] Backing up target repo..."
rm -rf target-backup.git || true
git clone --mirror "${target_repo}" "${target_name}-backup.git"

cd ..
echo "[INFO] Done backing up existing repositories"

echo "[INFO] Cloning target repo as migration base"
rm -rf migration || true
git clone "${target_repo}" $target_name
cd $target_name

if [[ ! -d ".github" ]]; then
  echo "[WARN] Target repo does not have a .github folder to preserve."
  echo "[WARN] Continuing without .github template..."
else
  echo "[INFO] Creating .github template from target repo"
  # Copy template outside the repo so we can reuse it per branch
  rm -rf ../.github_template || true
  cp -R .github ../.github_template
fi

echo "[INFO] Adding origin repo as 'source' remote and fetching"
git remote remove source 2>/dev/null || true
git remote add source "${origin_repo}"

git fetch source --prune --tags

echo "[INFO] Migrating branches from origin and injecting .github"

origin_branches=$(git ls-remote --heads source | awk '{print $2}' | sed 's@refs/heads/@@')

for branch in $origin_branches; do
  echo "[INFO] Processing branch: ${branch}"

  git checkout -B "${branch}" "source/${branch}"
  if [[ -d "../.github_template" ]]; then
    rm -rf .github
    cp -R ../.github_template .github

    if [[ -n "$(git status --porcelain -- .github)" ]]; then
      git add .github
      git commit -m "Preserve .github workflows from original target repo"
    else
      echo "[INFO] No .github changes to commit on branch ${branch}"
    fi
  fi
done

git push origin --all --force
git push origin --tags --force

cd ..
rm -rf .github_template
echo "[INFO] Deleted template folder"
echo "[INFO] Migration complete."
echo "[INFO] All branches & tags from ${origin_repo} are now in ${target_repo},"
echo "[INFO] with the .github folder from the target repo applied to every migrated branch."
