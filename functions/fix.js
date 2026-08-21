const fs = require('fs');
const path = 'C:/Users/HP ZBOOK/Downloads/KAIRO/functions/index.js';
let c = fs.readFileSync(path, 'utf16le'); // Read as UTF16 because PowerShell might have saved it as UTF16
if (!c.includes('exports')) {
    c = fs.readFileSync(path, 'utf8'); // fallback
}

// Remove null bytes
c = c.replace(/\x00/g, '');

c = c.replace('const { onRequest } = require("firebase-functions/v2/https");', 'const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");');

fs.writeFileSync(path, c, 'utf8');
