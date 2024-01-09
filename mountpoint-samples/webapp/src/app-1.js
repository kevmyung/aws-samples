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

function IsDirExists() {
  if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
  }
  if (!fs.existsSync(resizedDir)) {
    fs.mkdirSync(resizedDir, { recursive: true });
  }
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    IsDirExists();
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    cb(null, file.originalname);
  }
});

const upload = multer({ storage: storage });

app.post('/upload', upload.single('image'), async (req, res) => {
  try {
    console.log(`Server got request for file: ${req.file.originalname}`);
    IsDirExists();
    const resolutions = [720, 480, 360];
    for (const width of resolutions) {
        const resizedPath = path.join(resizedDir, `${width}-${req.file.originalname}`);
        await sharp(req.file.path)
            .resize(width)
            .toFile(resizedPath);
    }
    res.send('Image uploaded and resized');
  } catch (error) {
    console.error('Error processing image:', error);
    res.status(500).send('Error processing image');
  }
});

app.get('/images', async (req, res) => {
  try {
    IsDirExists();
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
    console.log(`Server running on port ${PORT}`);
});