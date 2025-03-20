const cloudinary = require('cloudinary').v2;

// Configure Cloudinary with fallback values if env vars are not set
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME || 'demo',
  api_key: process.env.CLOUDINARY_API_KEY || '123456789012345',
  api_secret: process.env.CLOUDINARY_API_SECRET || 'abcdefghijklmnopqrstuvwxyz12'
});

/**
 * Upload base64 image to Cloudinary
 * @param {string} base64Image - Base64 encoded image string
 * @param {string} folder - Folder name in Cloudinary (optional)
 * @returns {Promise<string>} - URL of the uploaded image
 */
const uploadBase64Image = async (base64Image, folder = 'profiles') => {
  try {
    // Check if Cloudinary credentials are properly set
    if (process.env.CLOUDINARY_CLOUD_NAME === undefined || 
        process.env.CLOUDINARY_API_KEY === undefined || 
        process.env.CLOUDINARY_API_SECRET === undefined) {
      console.warn('[Cloudinary] Using local storage fallback as Cloudinary credentials are not set');
      // Return the base64 image directly as a data URL
      return base64Image.startsWith('data:') ? base64Image : `data:image/jpeg;base64,${base64Image}`;
    }
    
    // Remove header from base64 string if present
    const base64Data = base64Image.replace(/^data:image\/\w+;base64,/, '');
    
    // Upload to Cloudinary
    const result = await cloudinary.uploader.upload(
      `data:image/jpeg;base64,${base64Data}`,
      {
        folder: folder,
        resource_type: 'image',
        transformation: [
          { width: 500, height: 500, crop: 'limit' },
          { quality: 'auto:good' }
        ]
      }
    );
    
    console.log('[Cloudinary] Image uploaded successfully:', result.public_id);
    return result.secure_url;
  } catch (error) {
    console.error('[Cloudinary] Upload error:', error);
    // Fallback to returning the base64 image directly
    return base64Image.startsWith('data:') ? base64Image : `data:image/jpeg;base64,${base64Image}`;
  }
};

module.exports = {
  uploadBase64Image
};
