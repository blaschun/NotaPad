#!/bin/bash
# Pusht den aktuellen Stand, wartet auf den Mac-Build und zeigt Compilerfehler. Aufruf: bash tools/ci.sh "Commit-Text"
GH="/c/Program Files/GitHub CLI/gh.exe"
cd "$(dirname "$0")/.."
git add -A
git -c user.name="serap" -c user.email="seraphin09@icloud.com" commit -q -m "${1:-Korrektur}

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>" 2>&1 | grep -v warning
git push -q origin HEAD:main 2>&1 | tail -1
sleep 20
ID=$("$GH" run list --limit 1 --json databaseId -q '.[0].databaseId')
for i in $(seq 1 17); do S=$("$GH" run view $ID --json status -q .status); [ "$S" = "completed" ] && break; sleep 30; done
echo "RUN $ID: $("$GH" run view $ID --json status,conclusion -q '"\(.status) \(.conclusion)"')"
"$GH" run view $ID --log 2>&1 | sed 's/^build\t[^\t]*\t[0-9T:.Z-]* //' | grep -E "error:|warning: .*(will never|unused)" | sort -u | sed 's#/Users/runner/work/NotaPad/NotaPad/AppSources/##' | head -60
