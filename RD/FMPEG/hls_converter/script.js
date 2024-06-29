const { exec } = require('child_process');
const ffprobe = require('ffprobe-static');
const fs = require('fs-extra');
const { promisify } = require('util');
const execPromise = promisify(exec);

const inputFile = 'output.mp4';
const targetResolutions = [
  { width: 1080, height: 1920, bitrate: 3500 },
  { width: 720, height: 1280, bitrate: 2000 },
  { width: 480, height: 854, bitrate: 1000 },
  { width: 360, height: 640, bitrate: 600 }
];

// Function to get the video resolution
const getVideoResolution = async (file) => {
  try {
    const { stdout } = await execPromise(`${ffprobe.path} -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 ${file}`);
    const [width, height] = stdout.trim().split('x').map(Number);
    return { width, height };
  } catch (error) {
    throw new Error(`Error getting resolution: ${error.message}`);
  }
};

// Function to create the ffmpeg command
const createFfmpegCommand = (inputFile, resolutions, originalResolution) => {
  let filterComplex = '';
  let map = '';
  let index = 0;

  resolutions.forEach((res, i) => {
    const { width, height, bitrate } = res;
    if (i > 0) filterComplex += ',';
    filterComplex += `[0:v]scale=w=${width}:h=trunc(ow/a/2)*2[v${index}]`;
    map += `-map [v${index}] -map 0:a? -c:v:${index} libx264 -b:v:${index} ${bitrate}k -maxrate:v:${index} ${bitrate * 1.07}k -bufsize:v:${index} ${bitrate * 1.5}k -preset fast -g 48 -sc_threshold 0 -c:a aac -b:a 128k -f hls -hls_time 4 -hls_playlist_type vod -hls_segment_filename "${height}p_%03d.ts" ${height}p.m3u8 `;
    index++;
  });

  if (resolutions.length === 0) {
    const { width, height, bitrate } = originalResolution;
    filterComplex += `[0:v]scale=w=${width}:h=trunc(ow/a/2)*2[v${index}]`;
    map += `-map [v${index}] -map 0:a? -c:v:${index} libx264 -b:v:${index} ${bitrate}k -maxrate:v:${index} ${bitrate * 1.07}k -bufsize:v:${index} ${bitrate * 1.5}k -preset fast -g 48 -sc_threshold 0 -c:a aac -b:a 128k -f hls -hls_time 4 -hls_playlist_type vod -hls_segment_filename "${height}p_%03d.ts" ${height}p.m3u8 `;
  }

  return `ffmpeg -i ${inputFile} -filter_complex "${filterComplex}" ${map}`;
};

// Function to create the master playlist
const createMasterPlaylist = (resolutions) => {
  let masterPlaylist = '#EXTM3U\n';

  resolutions.forEach((res) => {
    const { height, bitrate } = res;
    masterPlaylist += `#EXT-X-STREAM-INF:BANDWIDTH=${bitrate * 1000},RESOLUTION=${res.width}x${res.height}\n${height}p.m3u8\n`;
  });

  return masterPlaylist;
};

// Main function
const convertToHls = async (inputFile, targetResolutions) => {
  try {
    const { width, height } = await getVideoResolution(inputFile);
    const originalResolution = { width, height, bitrate: 1500 }; // Default bitrate for original resolution
    const resolutions = targetResolutions.filter(res => res.width <= width);
    
    const command = createFfmpegCommand(inputFile, resolutions, originalResolution);
    console.log('Executing command:', command);

    exec(command, async (error, stdout, stderr) => {
      if (error) {
        console.error(`Error executing ffmpeg: ${stderr}`);
      } else {
        console.log('HLS conversion completed successfully.');

        const masterPlaylist = createMasterPlaylist(resolutions.length > 0 ? resolutions : [originalResolution]);
        await fs.writeFile('master.m3u8', masterPlaylist);
        console.log('Master playlist created successfully.');
      }
    });
  } catch (error) {
    console.error(error.message);
  }
};

// Run the conversion
convertToHls(inputFile, targetResolutions);
