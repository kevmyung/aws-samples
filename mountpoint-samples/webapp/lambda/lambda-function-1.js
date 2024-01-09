const AWS = require('aws-sdk');
const sharp = require('sharp');
const path = require('path');
const rekognition = new AWS.Rekognition();
const s3 = new AWS.S3();

exports.handler = async (event, context) => {
  const bucket = event.Records[0].s3.bucket.name;
  const key = event.Records[0].s3.object.key;

  const downloadParams = { Bucket: bucket, Key: key };
  const originalImage = await s3.getObject(downloadParams).promise();

  const rekognitionParams = {
    Image: {
      S3Object: {
        Bucket: bucket,
        Name: key
      }
    }
  };

  let labels;
  try {
    const rekognitionResponse = await rekognition.detectLabels(rekognitionParams).promise();
    labels = rekognitionResponse.Labels.map(label => label.Name).join('-');
  } catch (error) {
    console.error('Error detecting labels:', error);
    throw error;
  }

  const fileName = path.basename(key); 
  const resolutions = [720, 480, 360];
  const resizePromises = resolutions.map(async (width) => {
    const resizedKey = `resized/${width}-${labels}-${fileName}`; 
    const resizedImage = await sharp(originalImage.Body)
      .resize({ width })
      .toBuffer();

    const s3Params = {
      Bucket: bucket,
      Key: resizedKey,
      Body: resizedImage
    };

    return s3.upload(s3Params).promise();

  });

  try {
    await Promise.all(resizePromises);
  } catch (error) {
    console.error('Error in parallel image resizing/uploading:', error);
    throw error;
  }

  return `Successfully processed ${key}`;
};
