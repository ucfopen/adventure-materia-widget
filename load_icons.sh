#! /bin/bash
# Creates JS file containing an array of icon data (icon name and url)
# Used to bypass writing out 100 objects in the initIcons function in creator-assets/controllers.coffee 
# ------------------------------------------------

# Outputs list of file names into lsoutput.log
ls -a ./src/assets/icons > lsoutput.log

last_line=$(wc -l < lsoutput.log)
current_line_number=0
output="./src/assets/icons.js"

FMT='{name:"%s",url:"%s"},'
FMT_LAST_LINE='{name:"%s",url:"%s"}'

printf 'icons = [' > $output

# Reads lsoutput.log and inserts each filename into JSON file
while read -r CURRENT_LINE
    current_line_number=$(($current_line_number + 1))
    do
        if [[ $current_line_number -ne $last_line ]]; then 
            if [[ $CURRENT_LINE == *".png" ]]; then
                printf "$FMT" "$CURRENT_LINE" "assets/icons/$CURRENT_LINE" >> $output
            fi
        else
            printf "$FMT_LAST_LINE" "$CURRENT_LINE" "assets/icons/$CURRENT_LINE" >> $output
            break
        fi
done < lsoutput.log

printf "]" >> $output

rm lsoutput.log
