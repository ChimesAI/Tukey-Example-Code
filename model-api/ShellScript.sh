#!/bin/bash
# dependencies: cURL and jq
# notice: The contents of cell in the CSV cannot be null or whitespace
# notice: The newline character (\n) should only appear at the end of each row.
# notice: Add an extra blank line at the end of CSV

# please enter your api_token in step 1
api_token="<please enter your api_token>"

# please import your csv file which corresponding to your model
predict_info=""
read_csv_to_json_data(){
    # read csv_file line by line and convert to specific JSON format
    csv_file="<please enter your csv path>"
    json_data="["
    columns=""
    first_line=true
    while IFS=',' read -a row ; do
        if [ "$first_line" = true ]; then
			# if it's the first line, extract column names and skip
            columns=("${row[@]}")
            first_line=false
        else
            json_object=""
            total_column_count=${#columns[@]}
			# get value in each row by iterating count of columns
            for ((i=0; i<$total_column_count; i++)); do
                dusty_key=${columns[$i]}
                dusty_value=${row[$i]}
				# remove spaces and newline characters, build key-value pair
                key=$(echo "$dusty_key" | tr -d '\n[:space:]')
                value=$(echo "$dusty_value" | tr -d '\n[:space:]')
                # add json_object based on the type of value
                if [[ "$value" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                    json_object+="\"$key\": $value"
                else
                    json_object+="\"$key\": \"$value\""
                fi
				# add comma separator if it's not the last column
                if [ $i -lt $(($total_column_count-1)) ]; then
                    json_object+=","
                fi
            done
			# add json_object to the json_data array
            json_data+="{ $json_object },"
        fi
    done < $csv_file

	# remove the trailing comma and done the json_data array
    json_data=${json_data%?}
    json_data+="]"
    predict_info=${json_data}
}
read_csv_to_json_data

# start prediction
post_api_path="https://<your_domain>/tukey/tukey/api/"
request_json='{"api_token": "'$api_token'", "data": '$predict_info'}'
echo "request json: $request_json"
echo "post to $post_api_path"
post_result=$(curl -X POST "$post_api_path" -L -H "Content-Type: application/json" -d "$request_json")
get_api_path=$(echo "$post_result" | jq -r '.link')

# the prediction time should not exceed the time_limit: 30 mins
time_limit=$((60 * 30))
time_start=$(date +%s)
while true; do
    current_time=$(date +%s)
    elapsed_time=$(($current_time - $time_start))
    if [[ $elapsed_time -ge $time_limit ]]; then
        echo "predict failed: request exceed time_limit"
        exit 1
    fi
    # get result and data.status
    echo "get from $get_api_path"
    result=$(curl -X GET "$get_api_path")
    status=$(echo "$result" | jq -r '.data.status')
    if [[ $status == "success" ]]; then
		# status is success, the predicted_data is ready
        predicted_data=$(echo "$result" | jq -r '.data')
        echo "$predicted_data"
        break
    elif [[ $status == "fail" ]]; then
        # status is fail, please check your data or call for support
        echo "predict failed"
        exit 1
    else
        # status is init, still process
        sleep 3
    fi
done