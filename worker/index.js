const sharp = require('sharp');
const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// Pixelation configuration per zoom level
const PIXELATION_CONFIG = {
  0: 1,    // No pixelation
  1: 2,    // Light
  2: 4,    // Medium
  3: 8,    // Heavy
  4: 16    // Very heavy
};

/**
 * Process a tile with pixelation effect
 */
async function processTile(tileUrl, zoomLevel) {
  try {
    // Download tile
    const response = await axios.get(tileUrl, {
      responseType: 'arraybuffer',
      timeout: 10000
    });

    const pixelSize = PIXELATION_CONFIG[zoomLevel] || 4;
    const tileSize = 256;

    // Process with Sharp
    const processed = await sharp(Buffer.from(response.data))
      .resize(Math.floor(tileSize / pixelSize), Math.floor(tileSize / pixelSize), {
        kernel: sharp.kernel.nearest
      })
      .resize(tileSize, tileSize, {
        kernel: sharp.kernel.nearest
      })
      .modulate({
        brightness: 0.9,
        saturation: 0.8
      })
      .toBuffer();

    return processed.toString('base64');
  } catch (error) {
    console.error('Error processing tile:', error.message);
    throw error;
  }
}

/**
 * Save processed tile to cache
 */
async function saveTileToCache(tileKey, pixelatedData, zoomLevel) {
  try {
    const { error } = await supabase
      .from('tile_cache')
      .upsert({
        tile_key: tileKey,
        pixelated_data: pixelatedData,
        z: zoomLevel,
        processed_at: new Date().toISOString()
      });

    if (error) throw error;
    console.log(`Tile ${tileKey} cached successfully`);
  } catch (error) {
    console.error('Error saving tile to cache:', error.message);
    throw error;
  }
}

/**
 * Process tile request from queue
 */
async function processTileRequest(request) {
  const { tile_key, tile_url, zoom_level } = request;
  
  console.log(`Processing tile: ${tile_key} at zoom ${zoom_level}`);
  
  try {
    const pixelatedData = await processTile(tile_url, zoom_level);
    await saveTileToCache(tile_key, pixelatedData, zoom_level);
    return { success: true, tile_key };
  } catch (error) {
    return { success: false, tile_key, error: error.message };
  }
}

// Main worker loop
async function startWorker() {
  console.log('PixelMap Tile Worker started');
  
  // In a real implementation, this would listen to a Redis queue or Supabase realtime
  // For now, we'll just demonstrate the processing capability
  
  // Example: Process a test tile
  const testTile = {
    tile_key: '10/512/340',
    tile_url: 'https://tile.openstreetmap.org/10/512/340.png',
    zoom_level: 2
  };
  
  const result = await processTileRequest(testTile);
  console.log('Test tile processed:', result);
}

// Run worker
startWorker().catch(console.error);

module.exports = { processTile, saveTileToCache, processTileRequest };
