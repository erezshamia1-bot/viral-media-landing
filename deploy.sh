#!/usr/bin/env bash
# העלאת האתר ל-GitHub + הפעלת GitHub Pages.
# להרצה פעם אחת, אחרי `gh auth login`.
set -u

REPO="viral-media-landing"
cd "$(dirname "$0")" || exit 1

echo "=============================================="
echo "  העלאת דף הנחיתה ל-GitHub Pages"
echo "=============================================="
echo

# --- 1. בדיקת התחברות -------------------------------------------------
if ! gh auth status >/dev/null 2>&1; then
  echo "✗ לא מחובר ל-GitHub."
  echo "  הרץ קודם:  gh auth login"
  exit 1
fi
USER_LOGIN=$(gh api user --jq .login 2>/dev/null)
echo "✓ מחובר כ: $USER_LOGIN"

# --- 2. ודא שאנחנו במאגר הנכון (ולא בתיקיית הבית!) --------------------
ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
case "$ROOT" in
  *"פאנל 3 תכנים"*) ;;
  *)
    echo "✗ עצירה: המאגר מושרש ב-$ROOT — לא בתיקיית הפרויקט."
    echo "  דחיפה משם עלולה לחשוף קבצים אישיים. בטלתי."
    exit 1 ;;
esac
echo "✓ מאגר מבודד: $(git ls-files | wc -l) קבצים"

# --- 3. ודא שיש commit ------------------------------------------------
if ! git rev-parse HEAD >/dev/null 2>&1; then
  git add -A && git commit -q -m "העלאה ראשונית"
fi
# קלוט שינויים שטרם נשמרו
if [ -n "$(git status --porcelain)" ]; then
  git add -A && git commit -q -m "עדכון לפני העלאה"
  echo "✓ נשמרו שינויים אחרונים"
fi

# --- 4. צור את המאגר ודחוף -------------------------------------------
if git remote get-url origin >/dev/null 2>&1; then
  echo "• origin כבר קיים — דוחף"
  git push -u origin main
else
  echo "• יוצר מאגר ציבורי: $REPO"
  gh repo create "$REPO" --public --source=. --remote=origin --push || {
    echo "✗ יצירת המאגר נכשלה (אולי השם תפוס). נסה שם אחר בתוך הסקריפט."; exit 1; }
fi
echo "✓ הקוד נדחף"

# --- 5. הפעל GitHub Pages --------------------------------------------
echo "• מפעיל GitHub Pages..."
if gh api "repos/$USER_LOGIN/$REPO/pages" >/dev/null 2>&1; then
  echo "✓ Pages כבר מופעל"
else
  gh api -X POST "repos/$USER_LOGIN/$REPO/pages" \
     -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 \
    && echo "✓ Pages הופעל" \
    || echo "! לא הצלחתי דרך ה-API — הפעל ידנית: Settings → Pages → main / (root)"
fi

URL="https://$USER_LOGIN.github.io/$REPO/"

# --- 6. המתן שהאתר יעלה ----------------------------------------------
echo "• ממתין שהאתר יעלה (עד ~2 דקות)..."
for i in $(seq 1 24); do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL" 2>/dev/null)
  if [ "$CODE" = "200" ]; then echo "✓ האתר חי!"; break; fi
  sleep 5
done

echo
echo "=============================================="
echo "  הדף:        $URL"
echo "  עמוד תודה:  ${URL}thank-you.html"
echo "=============================================="
echo
echo "פעולה אחרונה שנשארה לך:"
echo "  ב-SUMIT → הגדרות המוצר → עמוד תודה/הצלחה, הדבק:"
echo "  ${URL}thank-you.html"
echo
