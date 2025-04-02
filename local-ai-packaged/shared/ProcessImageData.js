// Extract the image data from the response
const responseData = $input.item.json;
let imageData;

// Check if the expected path exists, otherwise look for alternatives
if (responseData.body && responseData.body.images && responseData.body.images.length > 0) {
  imageData = responseData.body.images[0];
} else if (responseData.images && responseData.images.length > 0) {
  imageData = responseData.images[0];
} else {
  // Create a 1x1 transparent pixel as fallback
  imageData = "R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7";
  console.log("Using fallback image - no image data found in response");
}

// Get index from batch processing, but ensure it's unique
const index = $input.item.json.index || 0;
const sectionName = $input.item.json.section_name || `section_${index}`;

// Add timestamp to ensure uniqueness if needed
const timestamp = Date.now();
const uniqueSuffix = timestamp.toString().slice(-4);
const formattedIndex = index.toString().padStart(2, '0');

// Ensure filename is unique by adding timestamp suffix
const uniqueFilename = `image_${formattedIndex}_${uniqueSuffix}`;

// Decode base64 image
const imageBuffer = Buffer.from(imageData, 'base64');

// Return with binary data and unique filename
return [{
  json: {
    ...responseData,
    currentIndex: index,
    sectionName: sectionName,
    uniqueFilename: uniqueFilename
  },
  binary: {
    data: {
      data: imageBuffer,
      mimeType: 'image/png',
      fileName: `${uniqueFilename}.png`
    }
  }
}];