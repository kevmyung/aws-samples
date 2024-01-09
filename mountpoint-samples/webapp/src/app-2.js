const express = require('express');
const multer = require('multer');
const sharp = require('sharp');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const app = express();
app.use(cors());
app.use('/resized', express.static('/app/images/resized'));
app.use('/uploads', express.static('/app/images/uploads'));

const uploadDir = '/app/images/uploads';
const resizedDir = '/app/images/resized';

function IsDirExists(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}
IsDirExists(uploadDir);

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    cb(null, file.originalname);
  }
});

const upload = multer({ storage: storage });

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.post('/upload', (req, res, next) => {
  IsDirExists(uploadDir);
  next();
  }, upload.single('image'), (req, res) => {
  try {
    console.log(`Server got request for file: ${req.file.originalname}`);
    res.send('Image uploaded successfully');
  } catch (error) {
    console.error('Error uploading image:', error);
    res.status(500).send('Error uploading image');
  }
});



app.get('/images', async (req, res) => {
  try {
    IsDirExists(uploadDir);
    IsDirExists(resizedDir);
    const uploadFiles = await fs.promises.readdir('/app/images/uploads');
    const resizedFiles = await fs.promises.readdir('/app/images/resized');
    res.json({ uploadFiles, resizedFiles });
  } catch (error) {
    console.error(error);
    res.status(500).send('Unable to retrieve images');
  }
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
