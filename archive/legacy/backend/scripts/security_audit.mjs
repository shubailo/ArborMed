import fs from 'fs';
import path from 'path';

const API_BASE = process.env.API_BASE || 'http://localhost:3000';
const RECON_MAP_PATH = 'C:/Users/shuba/.gemini/antigravity/brain/3edaf529-1a30-4646-ab96-aa3010a9a863/recon_map.json';

class RedTeamAgent {
    constructor() {
        this.tokens = {
            student: null,
            admin: null,
            attacker: null
        };
        this.results = [];
    }

    async log(message, type = 'info') {
        const timestamp = new Date().toISOString();
        console.log(`[${timestamp}] [${type.toUpperCase()}] ${message}`);
    }

    async probe(endpoint, options = {}) {
        const url = `${API_BASE}${endpoint.path}`;
        const method = endpoint.method;
        const headers = {
            'Content-Type': 'application/json',
            ...options.headers
        };

        if (options.authType && this.tokens[options.authType]) {
            headers['Authorization'] = `Bearer ${this.tokens[options.authType]}`;
        }

        try {
            this.log(`Probing ${method} ${url}...`);
            const response = await fetch(url, {
                method,
                headers,
                body: options.body ? JSON.stringify(options.body) : null
            });
            const data = await response.json().catch(() => ({}));
            this.log(`Result: ${response.status} - ${JSON.stringify(data).substring(0, 50)}`);
            return { status: response.status, data };
        } catch (error) {
            this.log(`Error probing ${url}: ${error.message}`, 'error');
            return { status: 500, error: error.message };
        }
    }

    async runAudit() {
        this.log('Starting Security Audit...');
        const reconData = JSON.parse(fs.readFileSync(RECON_MAP_PATH, 'utf8'));

        for (const endpoint of reconData.endpoints) {
            this.log(`Probing ${endpoint.method} ${endpoint.path} (Auth: ${endpoint.auth})`);

            // Test 1: No Auth
            const noAuth = await this.probe(endpoint);
            this.log(`No Auth Result: ${noAuth.status}`);

            if (endpoint.auth !== 'None' && noAuth.status < 400) {
                this.results.push({
                    path: endpoint.path,
                    vuln: 'Authentication Bypass',
                    severity: 'High',
                    evidence: `Endpoint returned ${noAuth.status} without token.`
                });
            }
        }

        this.generateReport();
    }

    generateReport() {
        const reportPath = 'C:/Users/shuba/.gemini/antigravity/brain/3edaf529-1a30-4646-ab96-aa3010a9a863/SECURITY_REPORT.md';
        let report = '# 🛡️ Red Team Security Report\n\n';
        report += `Generated on: ${new Date().toISOString()}\n\n`;

        if (this.results.length === 0) {
            report += '✅ No immediate critical vulnerabilities found during initial probe.\n';
        } else {
            report += '## 🚩 Findings\n\n';
            this.results.forEach(f => {
                report += `### [${f.severity}] ${f.vuln}\n- **Location**: ${f.path}\n- **Evidence**: ${f.evidence}\n\n`;
            });
        }

        fs.writeFileSync(reportPath, report);
        this.log(`Report generated at ${reportPath}`);
    }
}

const agent = new RedTeamAgent();
agent.runAudit();
