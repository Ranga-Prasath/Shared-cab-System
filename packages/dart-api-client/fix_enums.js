const fs = require('fs');
const path = require('path');

function replaceInDir(dir) {
    for (const file of fs.readdirSync(dir)) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            replaceInDir(fullPath);
        } else if (fullPath.endsWith('.dart')) {
            let content = fs.readFileSync(fullPath, 'utf8');
            if (content.includes("''")) {
                // Find enum pattern: name_(''value''); or name_('value');
                const before = content;
                content = content.replace(/\_\(\'\'(.*?)\'\'\)/g, "_('$1')");
                if (content !== before) {
                    console.log("Fixed syntax error in:", fullPath);
                    fs.writeFileSync(fullPath, content, 'utf8');
                }
            }
        }
    }
}

replaceInDir('d:/Shared-cab-app/packages/dart-api-client/lib/src');
console.log('Done.');
