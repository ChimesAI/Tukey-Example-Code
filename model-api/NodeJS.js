// Node.js version: 12 or higher
// dependencies: axios, csv-parser, fs

const axios = require('axios');
const csv = require('csv-parser');
const fs = require('fs');

const getSecondsSinceEpoch = () => {
  const now = new Date();
  return Math.round(now.getTime() / 1000);
};

const readCsv = filePath => {
  return new Promise((resolve, reject) => {
    const results = [];
    fs.createReadStream(filePath)
      .pipe(csv())
      .on('data', data => results.push(data))
      .on('end', () => {
        resolve(results);
      })
      .on('error', error => {
        reject(error);
      });
  });
};

async function main() {
  // Please enter your api_token
  const apiToken = '<please enter your api_token>';

  // Please enter your CSV file path
  const csvFilePath = '<please enter your csv path>';

  // Read CSV file and convert to JSON
  const predictInfo = await readCsv(csvFilePath);

  // Start prediction
  const postApiPath = 'https://<your_domain>/tukey/tukey/api/';
  const requestJson = { api_token: apiToken, data: predictInfo };

  try {
    const postResult = await axios.post(postApiPath, requestJson);
    const getApiPath = postResult.data.link;

    // Prediction time should not exceed 30 minutes
    const timeLimit = 60 * 30;
    const timeStart = getSecondsSinceEpoch();

    while (true) {
      if (getSecondsSinceEpoch() - timeStart >= timeLimit) {
        throw new Error('predict failed: request exceed time_limit');
      }

      const result = await axios.get(getApiPath);
      const predictedData = result.data.data;
      const status = predictedData.status;

      if (status === 'success') {
        // Status is success, the predicted data is ready
        console.log(predictedData);
        break;
      } else if (status === 'fail') {
        // Status is fail, please check your data or contact support
        throw new Error('predict failed');
      } else {
        // Status is init, still processing
        await new Promise(resolve => setTimeout(resolve, 3000));
      }
    }
  } catch (error) {
    console.error(error.message);
  }
}

main();
