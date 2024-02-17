library(httr)
library(jsonlite)
library(readr)

main <- function() {
  # please enter your api_token in step 1
  api_token <- "<please enter your api_token>"
  
  # please import your csv file which corresponding to your model
  csv_path <- "<please enter your csv path>"
  csv_dataframe <- read.csv(csv_path)
  predict_info <- toJSON(csv_dataframe)
  
  # start prediction
  post_api_path <- "https://<your_domain>/tukey/tukey/api/"
  headers = c(`Content-Type` = 'application/json')
  data <- paste0('{"api_token": "', api_token, '","data": ', predict_info, '}')
  post_result <- httr::POST(url = post_api_path, 
                            httr::add_headers(.headers = headers), 
                            body = data)
  # raises HTTPError, if one occurred.
  stop_for_status(post_result)
  post_result_json <- content(post_result, "parsed")
  get_api_path <- post_result_json$link
  
  # the prediction time should not exceed the time_limit: 30 mins
  time_limit <- 60 * 30
  time_start <- Sys.time()
  repeat {
    current_time <- Sys.time()
    if (difftime(current_time, time_start, units = "secs") >= time_limit) {
      stop("predict failed: request exceed time_limit")
    }
    
    result <- GET(get_api_path)
    stop_for_status(result)
    result_json <- content(result, as = "text", encoding = "UTF-8") %>% 
      fromJSON
    status <- result_json$data$status
    if (status == "success") {
      # status is success, the "predicted_data" is ready
      return(result_json)
      break
    } else if (status == "fail") {
      # status is fail, please check your data or call for support
      stop("predict failed")
    } else {
      # status is init, still process
      Sys.sleep(3)
    }
  }
}

main()