findValue=$1
replaceValue=$2
inputValue=$3
tmpFile=.tmp.txt

echo $inputValue > $tmpFile

ESCAPED_REPLACE=$(printf '%s\n' "$findValue" | sed -e 's/[\/&]/\\&/g')
ESCAPED_KEYWORD=$(printf '%s\n' "$findValue" | sed -e 's/[]\/$*.^[]/\\&/g');

sed -i -e "s+$findValue+$replaceValue+g" $tmpFile
sed "s/$ESCAPED_KEYWORD/$ESCAPED_REPLACE/g" $tmpFile