#!/usr/bin/env node

import { readFileSync, readdirSync, statSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import Ajv2020 from 'ajv/dist/2020.js';
import addFormats from 'ajv-formats';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rootDir = join(__dirname, '..');

// Load schema
const schemaPath = join(rootDir, 'schemas', 'manifest.schema.json');
const schema = JSON.parse(readFileSync(schemaPath, 'utf8'));

// Initialize validator
const ajv = new Ajv2020({ allErrors: true });
addFormats(ajv);
const validate = ajv.compile(schema);

// Find all plugins
const categories = ['skills', 'agents', 'mcp-servers', 'hooks'];
const pluginsDir = join(rootDir, 'plugins');
let errors = [];
let validated = 0;

for (const category of categories) {
  const categoryDir = join(pluginsDir, category);

  if (!existsSync(categoryDir)) continue;

  const plugins = readdirSync(categoryDir).filter(f => {
    const fullPath = join(categoryDir, f);
    return statSync(fullPath).isDirectory();
  });

  for (const plugin of plugins) {
    const manifestPath = join(categoryDir, plugin, 'manifest.json');

    if (!existsSync(manifestPath)) {
      errors.push(`Missing manifest: ${manifestPath}`);
      continue;
    }

    try {
      const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
      const valid = validate(manifest);

      if (!valid) {
        errors.push(`Invalid manifest ${manifestPath}:`);
        validate.errors.forEach(err => {
          errors.push(`  - ${err.instancePath} ${err.message}`);
        });
      } else {
        // Additional validations
        if (manifest.category !== category) {
          errors.push(`${manifestPath}: category '${manifest.category}' doesn't match directory '${category}'`);
        }
        if (manifest.name !== plugin) {
          errors.push(`${manifestPath}: name '${manifest.name}' doesn't match directory '${plugin}'`);
        }
        validated++;
      }
    } catch (e) {
      errors.push(`Failed to parse ${manifestPath}: ${e.message}`);
    }
  }
}

console.log(`Validated ${validated} plugin manifests`);

if (errors.length > 0) {
  console.error('\nErrors found:');
  errors.forEach(e => console.error(e));
  process.exit(1);
}

console.log('All manifests valid!');
