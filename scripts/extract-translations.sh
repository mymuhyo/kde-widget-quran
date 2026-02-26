#!/bin/bash
POT_FILE="translations/template.pot"
mkdir -p translations
echo "Extracting strings to $POT_FILE..."
FILES=$(find contents/ui contents/js -name "*.qml" -o -name "*.js")
xgettext --from-code=UTF-8 \
         --language=JavaScript \
         --keyword=i18n:1 \
         --keyword=i18n:1,2 \
         --keyword=i18n:1,2,3 \
         --keyword=tr:1 \
         --keyword=tr:1,2 \
         --keyword=tr:1,2,3 \
         --output="$POT_FILE" \
         $FILES
echo "Done. You can now update PO files using 'msgmerge'."
echo "Example: msgmerge -U translations/ar.po translations/template.pot"
