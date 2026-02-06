const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const SEED_DIR = path.join(__dirname, 'seeders');
const SCRIPT_MAP = {
    'shop': ['seedGoldCatalog.js'],
};

// Colors for console output
const colors = {
    reset: "\x1b[0m",
    bright: "\x1b[1m",
    green: "\x1b[32m",
    yellow: "\x1b[33m",
    red: "\x1b[31m",
    cyan: "\x1b[36m",
};

function printHelp() {
    console.log(`${colors.bright}ARBOR MED SEED MANAGER${colors.reset}`);
    console.log(`Usage: node seed_manager.js [mode]`);
    console.log(`\nAvailable Modes:`);
    Object.keys(SCRIPT_MAP).forEach(mode => {
        console.log(`  ${colors.cyan}${mode.padEnd(15)}${colors.reset} -> Runs: ${SCRIPT_MAP[mode].join(', ')}`);
    });
    console.log(`  ${colors.cyan}help${colors.reset}            -> Show this help message`);
}

function runScript(scriptName) {
    const scriptPath = path.join(SEED_DIR, scriptName);
    if (!fs.existsSync(scriptPath)) {
        console.error(`${colors.red}Error: Script not found at ${scriptPath}${colors.reset}`);
        return false;
    }

    console.log(`${colors.yellow}▶ Running ${scriptName}...${colors.reset}`);
    try {
        execSync(`node "${scriptPath}"`, { stdio: 'inherit' });
        console.log(`${colors.green}✔ Success: ${scriptName}${colors.reset}\n`);
        return true;
    } catch (e) {
        console.error(`${colors.red}✘ Failed: ${scriptName}${colors.reset}\n`);
        return false;
    }
}

async function main() {
    const args = process.argv.slice(2);
    const mode = args[0];

    if (!mode || mode === 'help') {
        printHelp();
        process.exit(0);
    }

    if (!SCRIPT_MAP[mode]) {
        console.error(`${colors.red}Unknown mode: ${mode}${colors.reset}\n`);
        printHelp();
        process.exit(1);
    }

    console.log(`${colors.bright}Starting Seed Sequence for mode: ${mode}${colors.reset}\n`);

    const scripts = SCRIPT_MAP[mode];
    for (const script of scripts) {
        const success = runScript(script);
        if (!success) {
            console.error(`${colors.red}Sequence aborted due to error.${colors.reset}`);
            process.exit(1);
        }
    }

    console.log(`${colors.bright}${colors.green}All scripts completed successfully!${colors.reset}`);
}

main();
