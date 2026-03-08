import { mkdtempSync, readFileSync, rmSync, writeFileSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { execSync } from 'node:child_process';

const outputDir = resolve('packages/dart-api-client');
const sourceUrl = process.env.OPENAPI_SOURCE_URL ?? 'http://localhost:4000/api/docs-json';
const fallbackYaml = resolve('docs/openapi.yaml');

const tempDir = mkdtempSync(join(tmpdir(), 'shared-cab-openapi-'));
const tempSpecPath = join(tempDir, 'openapi.json');

const fetchLiveSpec = async () => {
  try {
    const response = await fetch(sourceUrl);
    if (!response.ok) {
      return null;
    }

    const rawText = await response.text();
    writeFileSync(tempSpecPath, rawText, 'utf8');
    return tempSpecPath;
  } catch {
    return null;
  }
};

const run = async () => {
  const liveSpec = await fetchLiveSpec();
  const inputSpec = liveSpec ?? (existsSync(fallbackYaml) ? fallbackYaml : null);

  if (!inputSpec) {
    throw new Error('No OpenAPI source was found. Start API or provide docs/openapi.yaml.');
  }

  rmSync(outputDir, { recursive: true, force: true });

  const additionalProperties = [
    'pubName=shared_cab_api_client',
    'pubVersion=1.0.0',
    'serializationLibrary=json_serializable',
    'dateLibrary=core'
  ].join(',');

  execSync(
    `openapi-generator-cli generate -i "${inputSpec}" -g dart-dio -o "${outputDir}" --additional-properties "${additionalProperties}"`,
    { stdio: 'inherit' }
  );

  const pubspecPath = resolve(outputDir, 'pubspec.yaml');
  if (!existsSync(pubspecPath)) {
    writeFileSync(
      pubspecPath,
      [
        'name: shared_cab_api_client',
        'description: Generated Dart client for Shared Cab Platform',
        'version: 1.0.0',
        'environment:',
        "  sdk: '>=3.3.0 <4.0.0'",
        'dependencies:',
        '  dio: ^5.7.0',
        '  json_annotation: ^4.9.0',
        'dev_dependencies:',
        '  build_runner: ^2.4.13',
        '  json_serializable: ^6.9.0'
      ].join('\n') + '\n',
      'utf8'
    );
  }

  if (liveSpec) {
    console.log(`Generated Dart client from live OpenAPI: ${sourceUrl}`);
  } else {
    const firstLine = readFileSync(fallbackYaml, 'utf8').split('\n')[0] ?? 'docs/openapi.yaml';
    console.log(`Live OpenAPI unavailable. Generated from fallback spec (${firstLine}).`);
  }
};

run()
  .catch((error) => {
    console.error(error instanceof Error ? error.message : 'Generation failed.');
    process.exitCode = 1;
  })
  .finally(() => {
    rmSync(tempDir, { recursive: true, force: true });
  });
