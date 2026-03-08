import { execSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

export default async function globalSetup(): Promise<void> {
  if (!process.env.CI) {
    return;
  }

  const currentDir = dirname(fileURLToPath(import.meta.url));
  const workspaceRoot = resolve(currentDir, '../../..');

  execSync('corepack pnpm db:seed', {
    cwd: workspaceRoot,
    stdio: 'inherit'
  });
}