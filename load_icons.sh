#! /bin/bash
# Creates JSON file with the files in the icons folder
# ------------------------------------------------

# Outputs list of file names into lsoutput.log
ls -a ./src/assets/icons > lsoutput.log

last_line=$(wc -l < lsoutput.log)
current_line_number=0
json_output="./src/assets/icons.json"

JSON_FMT='\t\t{"name":"%s"},\n'
JSON_FMT_LAST_LINE='\t\t{"name":"%s"}\n'

printf '{\n\t"icons": [\n' > $json_output

# Reads lsoutput.log and inserts each filename into JSON file
while read -r CURRENT_LINE
    current_line_number=$(($current_line_number + 1))
    do
        if [[ $current_line_number -ne $last_line ]]; then 
            if [[ $CURRENT_LINE == *".png" ]]; then
                printf "$JSON_FMT" "$CURRENT_LINE" >> $json_output
            fi
        else
            printf "$JSON_FMT_LAST_LINE" "$CURRENT_LINE" >> $json_output
            break
        fi
done < lsoutput.log

printf "\t]\n}" >> $json_output

rm lsoutput.log
