"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.prisma = void 0;
require("dotenv/config");
const client_1 = require("@prisma/client");
const adapter_libsql_1 = require("@prisma/adapter-libsql");
const path_1 = __importDefault(require("path"));
let dbUrl = process.env.DATABASE_URL;
if (!dbUrl) {
    dbUrl = `file:${path_1.default.resolve(__dirname, '../dev.db')}`;
}
// Convert backslashes for Windows path format issues in LibSQL
dbUrl = dbUrl.replace(/\\/g, '/');
console.log('DEBUG: Connecting to DB URL:', dbUrl);
const adapter = new adapter_libsql_1.PrismaLibSql({
    url: dbUrl
});
exports.prisma = new client_1.PrismaClient({ adapter, log: ['error', 'warn'] });
