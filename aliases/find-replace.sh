findValue=$1
replaceValue=$2
inputValue=$3

tmpFile=.tmp.txt
echo $inputValue > $tmpFile
sed -i -e "s+$findValue+$replaceValue+g" $tmpFile
ESCAPED_REPLACE=$(printf '%s\n' "$findValue" | sed -e 's/[\/&]/\\&/g')
ESCAPED_KEYWORD=$(printf '%s\n' "$findValue" | sed -e 's/[]\/$*.^[]/\\&/g');

# Now you can use it inside the original sed statement to replace text
sed "s/$ESCAPED_KEYWORD/$ESCAPED_REPLACE/g" $tmpFile