const { spawn } = require('child_process');
const fs = require('fs-extra');
const path = require('path');

const serverUrl = process.argv[2];
const specFile = process.argv[3];

if (!serverUrl || !specFile) {
    console.error('Usage: node test-contract.js <server-url> <spec-file>');
    process.exit(1);
}

function runCommand(command, args) {
    return new Promise((resolve, reject) => {
        console.log(`> ${command} ${args.join(' ')}`);
        const child = spawn(command, args, { stdio: 'inherit' });

        child.on('close', (code) => {
            if (code === 0) {
                resolve();
            } else {
                reject(new Error(`Command failed with exit code ${code}`));
            }
        });

        child.on('error', (err) => {
            reject(err);
        });
    });
}

async function testContract() {
    try {
        const reportDir = path.join(process.cwd(), 'out', 'reports');
        await fs.ensureDir(reportDir);
        await runCommand('wiretap', ['-u', serverUrl, '-s', specFile, '--stream-report', '--report-filename', 'out/reports/cf.json']);
    } catch (error) {
        console.error(error.message);
        process.exit(1);
    }
}

testContract();
