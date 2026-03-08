const fs = require('fs');
const content = fs.readFileSync('build_log.txt', 'utf16le');
fs.writeFileSync('build_log_utf8.txt', content, 'utf8');
