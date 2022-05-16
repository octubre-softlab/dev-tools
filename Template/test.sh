echo "Replace files"
TEMPLATE_VAR="Obelisco"
NEW_NAME="Tango"
for file in $(find ./ -type f -iname *${TEMPLATE_VAR}* -print)
do
    FILE="${file##*/}"
    # echo "File Path:        ${file}"
    # echo "File Name:        ${file##*/}"
    # echo "New File Name:    ${FILE/$TEMPLATE_VAR/$NEW_NAME}"
    # echo "New File Path:    ${file%/*}/${FILE/$TEMPLATE_VAR/$NEW_NAME}"
    echo "mv Command:       mv ${file} ${file%/*}/${FILE/$TEMPLATE_VAR/$NEW_NAME}"
    echo ""
done

echo "Repalce Folders"
find ./ -type d -iname *${TEMPLATE_VAR}* -printf '%h\0%d\0%p\n' | sort -t '\0' -nr | awk -F '\0' '{print $3}' | while read folder; do
    FOLDER="${folder##*/}"
    echo "Folder Path:        ${folder}"
    echo "Folder Name:        ${folder##*/}"
    echo "New Folder Name:    ${FOLDER/$TEMPLATE_VAR/$NEW_NAME}"
    echo "New Folder Path:    ${folder%/*}/${FOLDER/$TEMPLATE_VAR/$NEW_NAME}"
    echo "mv Command:       mv ${folder} ${folder%/*}/${FOLDER/$TEMPLATE_VAR/$NEW_NAME}"
    echo ""
done