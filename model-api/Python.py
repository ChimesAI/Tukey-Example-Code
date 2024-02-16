# python version: higher than python3
# dependencies: pandas and requests

import time

import pandas as pd
import requests


def main():
    # please enter your api_token in step 1
    api_token = "<please enter your api_token>"

    # please import your csv file which corresponding to your model
    predict_info = None
    with open("<please enter your csv path>") as csvfile:
        csv_dataframe = pd.read_csv(csvfile)
        original_data = csv_dataframe.to_dict("records")
        predict_info = original_data

    # start prediction
    post_api_path = "https://<your_domain>/tukey/tukey/api/"
    request_json = {"api_token": api_token, "data": predict_info}
    post_result = requests.post(post_api_path, json=request_json)
    # raises HTTPError, if one occurred.
    post_result.raise_for_status()
    post_result_json = post_result.json()
    get_api_path = post_result_json.get("link")

    # the prediction time should not exceed the time_limit: 30 mins
    time_limit = 60 * 30
    time_start = time.time()
    while True:
				current_time = time.time()
        if current_time - time_start >= time_limit:
            raise Exception("predict failed: request exceed time_limit")

        result = requests.get(get_api_path)
        result.raise_for_status()
        result_json = result.json()

        predicted_data = result_json.get("data")
        status = predicted_data.get("status")
        if status == "success":
            # status is success, the "predicted_data" is ready
            print(predicted_data)
            break
        elif status == "fail":
            # status is fail, please check your data or call for support
            raise Exception("predict failed")
        else:
            # status is init, still process
            time.sleep(3)


if __name__ == "__main__":
    main()
