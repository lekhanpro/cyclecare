#!/usr/bin/env node
// Generates lib/features/tracking/domain/logging_catalog_data.dart from the
// redesign logging catalogue (redesign/logging-catalog.json).
//
// Usage (from the repository root):
//   node tool/logging_catalog/generate.js <path/to/logging-catalog.json> [out.dart]
//   dart format lib/features/tracking/domain/logging_catalog_data.dart
//
// Only data is generated: groups, fields and options with their exact labels,
// spellings, order and semantic icon names. The DailyLog bindings are written
// by hand in logging_catalog.dart. The script refuses to write anything if the
// catalogue's own `counts` block disagrees with what it contains, or if a
// field or option cannot be mapped onto the DailyLog schema.
'use strict';

const fs = require('fs');
const path = require('path');

const [, , source, outArg] = process.argv;
if (!source) {
  console.error(
    'usage: node tool/logging_catalog/generate.js <logging-catalog.json> [out.dart]',
  );
  process.exit(64);
}
const out =
  outArg ||
  path.join(__dirname, '..', '..', 'lib', 'features', 'tracking', 'domain',
    'logging_catalog_data.dart');

const catalog = JSON.parse(fs.readFileSync(source, 'utf8'));

const KINDS = new Set([
  'date', 'single', 'multi', 'scale', 'number', 'text', 'textarea', 'custom',
]);

// Stored FlowIntensity for each flow label.
const FLOW = {
  None: 'none',
  Spotting: 'spotting',
  Light: 'light',
  Medium: 'medium',
  Heavy: 'heavy',
  'Very heavy': 'veryHeavy',
};

// medicineTaken is a bool in DailyLog.
const MEDICINE_TAKEN = { Taken: 'true', 'Not taken': 'false' };

// Never shared with a partner or sent to an AI service.
const PRIVATE = new Set([
  'intimacy', 'protection', 'libido', 'pregnancyTest', 'ovulationTest',
  'testNote',
]);

// Accepted ranges, matching DailyLogValidator. Values present in the JSON
// take precedence (they agree; a test checks the validator against these).
const LIMITS = {
  painLevel: { min: 0, max: 10, step: 1 },
  temperatureCelsius: { min: 34, max: 43 },
  weightKg: { min: 20, max: 350 },
  heightCm: { min: 50, max: 250 },
  sleepHours: { min: 0, max: 24 },
  waterMl: { min: 0, max: 10000 },
  exerciseMinutes: { min: 0, max: 1440 },
};

function fail(message) {
  console.error(`generate.js: ${message}`);
  process.exit(1);
}

function str(value) {
  return (
    "'" +
    String(value)
      .replace(/\\/g, '\\\\')
      .replace(/'/g, "\\'")
      .replace(/\$/g, '\\$')
      .replace(/\r?\n/g, '\\n') +
    "'"
  );
}

const optStr = (value) =>
  value === undefined || value === null || value === '' ? 'null' : str(value);

const num = (value) =>
  value === undefined || value === null ? 'null' : String(value);

function implemented(item, where) {
  if (item.implementation === 'implemented') return true;
  if (item.implementation === 'planned') return false;
  return fail(`${where}: unknown implementation "${item.implementation}"`);
}

function optionValue(field, option) {
  const label = option.label;
  if (field.id === 'flow') {
    if (!FLOW[label]) fail(`flow option "${label}" has no FlowIntensity`);
    return `FlowIntensity.${FLOW[label]}`;
  }
  if (field.id === 'painLevel') {
    const value = Number.parseInt(label, 10);
    if (String(value) !== label) fail(`pain option "${label}" is not 0-10`);
    return String(value);
  }
  if (field.id === 'medicineTaken') {
    if (!MEDICINE_TAKEN[label]) fail(`medicine option "${label}" unmapped`);
    return MEDICINE_TAKEN[label];
  }
  return str(label);
}

let optionCount = 0;
let implementedOptions = 0;

function emitOption(field, option) {
  if (typeof option !== 'object' || !option.label) {
    fail(`${field.id}: option without a label`);
  }
  optionCount++;
  const isImplemented = implemented(option, `${field.id}/${option.label}`);
  if (isImplemented) implementedOptions++;
  return (
    `LogOption(value: ${optionValue(field, option)}, ` +
    `label: ${str(option.label)}, icon: ${str(option.icon)}, ` +
    `implemented: ${isImplemented})`
  );
}

function emitField(field, indent) {
  if (!KINDS.has(field.type)) fail(`${field.id}: unknown type ${field.type}`);
  const limits = LIMITS[field.id] || {};
  const pad = ' '.repeat(indent);
  const lines = [
    `id: ${str(field.id)}`,
    `label: ${str(field.label)}`,
    `icon: ${str(field.icon)}`,
    `kind: LogFieldKind.${field.type}`,
    `implemented: ${implemented(field, field.id)}`,
    `jsonKey: ${str(field.storageKey || field.id)}`,
  ];
  const optional = {
    unit: optStr(field.unit),
    min: num(field.min ?? limits.min),
    max: num(field.max ?? limits.max),
    step: num(field.step ?? limits.step),
    hint: optStr(field.hint),
    placeholder: optStr(field.placeholder),
    note: optStr(field.note),
    preview: num(field.preview),
  };
  for (const [key, value] of Object.entries(optional)) {
    if (value !== 'null') lines.push(`${key}: ${value}`);
  }
  if (field.required) lines.push('required: true');
  if (PRIVATE.has(field.id)) lines.push('private: true');
  const options = field.options || [];
  if (options.length) {
    lines.push(
      'options: [\n' +
        options.map((o) => `${pad}    ${emitOption(field, o)},`).join('\n') +
        `\n${pad}  ]`,
    );
  }
  return `LogField(\n${lines.map((l) => `${pad}  ${l},`).join('\n')}\n${pad})`;
}

function emitGroup(group) {
  const lines = [
    `id: ${str(group.id)}`,
    `title: ${str(group.title)}`,
    `icon: ${str(group.icon)}`,
  ];
  if (group.tone) lines.push(`tone: ${str(group.tone)}`);
  if (group.description) lines.push(`description: ${str(group.description)}`);
  if (group.model_notes) lines.push(`modelNotes: ${str(group.model_notes)}`);
  lines.push(
    'fields: [\n' +
      group.fields.map((f) => `      ${emitField(f, 6)},`).join('\n') +
      '\n    ]',
  );
  return `  LogGroup(\n${lines.map((l) => `    ${l},`).join('\n')}\n  )`;
}

const groups = catalog.groups.map(emitGroup);
const dateField = emitField(catalog.date_field, 0);
const fieldCount =
  1 + catalog.groups.reduce((sum, group) => sum + group.fields.length, 0);

const expected = catalog.counts || {};
const actual = {
  groups: catalog.groups.length,
  fields: fieldCount,
  options: optionCount,
  implemented_options: implementedOptions,
  planned_options: optionCount - implementedOptions,
};
for (const [key, value] of Object.entries(actual)) {
  if (expected[key] !== value) {
    fail(`counts.${key} is ${expected[key]} but the catalogue holds ${value}`);
  }
}

const dart = `// GENERATED FILE. Do not edit by hand.
//
// Source: redesign/logging-catalog.json, version ${catalog.version}.
// Regenerate: node tool/logging_catalog/generate.js <logging-catalog.json>
// then run dart format on this file.

part of 'logging_catalog.dart';

const String _catalogVersion = ${str(catalog.version)};

const _sourceCounts = (
  groups: ${actual.groups},
  fields: ${actual.fields},
  options: ${actual.options},
  implementedOptions: ${actual.implemented_options},
  plannedOptions: ${actual.planned_options},
);

const LogField _dateField = ${dateField};

const List<LogGroup> _groups = [
${groups.join(',\n')},
];
`;

fs.writeFileSync(out, dart, 'utf8');
console.log(
  `wrote ${out}: ${actual.groups} groups, ${actual.fields} fields, ` +
    `${actual.options} options`,
);
