const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");
const fs = require("fs");
const path = require("path");

// 1. Initialize Firebase
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

// 2. Configuration: Define your directory and file mapping
const BASE_DIRECTORY =
  "/Users/lun/Documents/Apple Developer Academy/momo/BSDGo/Resources/Data";

const FILES_TO_UPLOAD = [
  { filename: "Bus.json", collectionName: "buses" },
  { filename: "Schedule.json", collectionName: "schedules" },
  { filename: "Stops.json", collectionName: "stops" },
];

// 3. Helper function to upload a single file
async function uploadFile(fileConfig) {
  const filePath = path.join(BASE_DIRECTORY, fileConfig.filename);

  try {
    // Read and parse the JSON file manually
    const rawData = fs.readFileSync(filePath, "utf8");
    const jsonData = JSON.parse(rawData);

    console.log(
      `\n📂 Processing ${fileConfig.filename} -> Collection: '${fileConfig.collectionName}' (${jsonData.length} items)`,
    );

    const batchPromises = jsonData.map(async (item) => {
      try {
        // Using .add() lets Firestore generate the ID.
        // If your JSON has a unique ID field (like 'id'), use .doc(item.id).set(item) instead.
        const docRef = await db.collection(fileConfig.collectionName).add(item);
        return { success: true, id: docRef.id };
      } catch (error) {
        console.error(`! Error in ${fileConfig.filename}:`, error.message);
        return { success: false };
      }
    });

    await Promise.all(batchPromises);
    console.log(`✅ Finished ${fileConfig.filename}`);
  } catch (error) {
    console.error(
      `❌ Critical Error reading ${fileConfig.filename}:`,
      error.message,
    );
  }
}

// 4. Main Execution Function
async function uploadAll() {
  console.log(`🚀 Starting Multi-File Injection from: ${BASE_DIRECTORY}`);

  // Create an array of promises, one for each file
  const fileUploadPromises = FILES_TO_UPLOAD.map((config) =>
    uploadFile(config),
  );

  // Wait for ALL files to finish processing
  await Promise.all(fileUploadPromises);

  console.log("\n-----------------------------------------");
  console.log("🎉 All files processed! Press Ctrl+C to exit.");
}

uploadAll();
