using System.Net.Http;
using System.IO;
using System.Text.Json;
using System.Text;
using System.Text.Json.Nodes;
using System.Diagnostics;

//  .NET version: 6.0+
//  C# version: 10

// Ensure you replace all <please enter your ...> with your parameters
namespace TukeyApi
{
    public class Program
    {
        const string TukeyAddress = "https://<please enter your domain>/tukey/tukey/api/";
        static readonly CancellationTokenSource s_cts = new CancellationTokenSource();
        
        static List<Dictionary<string, string>> ConvertCsvToJson (string filePath)
        {
            if (!File.Exists(filePath))
            {
                throw new InvalidOperationException("File Not Exist");
                
            }
            string[] lines = File.ReadAllLines(filePath);
            if (lines.Length == 0)
            {
                throw new InvalidOperationException("Null Content");
            }
            string[] headers = lines[0].Split(',');
            List<Dictionary<string, string>> jsonData = new List<Dictionary<string, string>>();
            for (int i = 1 ; i < lines.Length ; i++)
            {
                string[] values = lines[i].Split(',');
                var jsonObject = new Dictionary<string, string>();
                for (int j = 0 ; j < headers.Length ; j++)
                {
                    jsonObject[headers[j]] = values[j];
                }

                jsonData.Add(jsonObject);
            }
            return jsonData;
        }

        // Start Prediction
        static async Task<string> ApiPost (HttpClient httpClient, string ApiToken, CancellationToken token, String filePath)
        {

            List<Dictionary<string, string>> CsvContent = ConvertCsvToJson(filePath);
            var requestContent = new
            {
                api_token = ApiToken,
                data = CsvContent
            };
            string requestPayload = JsonSerializer.Serialize(requestContent);
            httpClient.DefaultRequestHeaders.Add("Accept", "application/json");
            var postContent = new StringContent(requestPayload, Encoding.UTF8, "application/json");
            HttpResponseMessage response = await httpClient.PostAsync("", postContent, token);

            if (response.IsSuccessStatusCode)
            {
                string responseContent = await response.Content.ReadAsStringAsync();
                JsonNode responseObject = JsonSerializer.Deserialize<JsonNode>(responseContent);
                string postId = (string)responseObject["id"];
                return postId;
            }
            else
            {
                Console.WriteLine($"\nfail {response.StatusCode}");
                return "failed";
            }

        }

        // Get Prediction Result 
        static async Task ApiGet (HttpClient httpClient, string ApiToken, CancellationToken token)
        {
            string status = "";
            while (status != "success")
            {
                HttpResponseMessage response = await httpClient.GetAsync(ApiToken + "/", token);
                response.EnsureSuccessStatusCode();
                if (response.IsSuccessStatusCode)
                {
                    string responseContent = await response.Content.ReadAsStringAsync();
                    JsonNode responseObject = JsonSerializer.Deserialize<JsonNode>(responseContent);
                    status = (string)responseObject["data"]["status"];
                    if (status == "fail")
                    {
                        Console.WriteLine("predict failed");
                        break;
                    }
                    if (status == "success")
                    {
                        string data = responseObject["data"].ToString();
                        Console.WriteLine(data);
                    }
                    else
                    {
                        await Task.Delay(3000);
                    }
                }
                else
                {
                    Console.WriteLine($"\nfail {response.StatusCode}");
                }
            }
        }


        static async Task Main (string[] args)
        {
            try
            {
                // Task would be canceld after 30 minutes
                s_cts.CancelAfter(1000 * 60 * 30);
                HttpClient httpClient = new() { BaseAddress = new Uri(TukeyAddress) };
                string filePath = @"<please enter your csv path>";
                string apitoken = @"<please enter your api_token>";
                string result_id = await ApiPost(httpClient, apitoken, s_cts.Token, filePath);
                await ApiGet(httpClient, result_id, s_cts.Token);
            }
            catch (OperationCanceledException)
            {
                Console.WriteLine("predict failed: request exceed time_limit");
            }
            catch (InvalidOperationException e)
            {
                Console.WriteLine(e.Message);
            }
            finally
            {
                s_cts.Dispose();
                Console.ReadKey();
            }
        }

    }
}

