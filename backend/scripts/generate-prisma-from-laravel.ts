/*
  Lightweight generator: parses Laravel migrations and emits Prisma schema.
  Handles common Blueprint methods used in this repo.
*/
import fs from 'fs';
import path from 'path';

type Column = {
  name: string;
  type:
    | 'id'
    | 'string'
    | 'text'
    | 'boolean'
    | 'integer'
    | 'bigint'
    | 'tinyInteger'
    | 'decimal'
    | 'json'
    | 'timestamp'
    | 'enum';
  precision?: number | undefined;
  scale?: number | undefined;
  length?: number | undefined;
  nullable?: boolean | undefined;
  default?: string | undefined;
  enumValues?: string[] | undefined;
  primary?: boolean | undefined;
};

type ForeignKey = {
  column: string;
  references: string; // primary key column (typically 'id')
  on: string; // table name
  onDelete?: string | null;
  onUpdate?: string | null;
  nullable?: boolean;
};

type Unique = { columns: string[]; name?: string | undefined };
type Index = { columns: string[]; name?: string | undefined };

type Table = {
  name: string;
  columns: Column[];
  uniques: Unique[];
  indexes: Index[];
  foreigns: ForeignKey[];
};

const repoRoot = path.resolve(__dirname, '..', '..');
const migrationsDir = path.join(repoRoot, 'api', 'database', 'migrations');
const enumFile = path.join(repoRoot, 'api', 'app', 'Enums', 'ShopGenre.php');
const prismaDir = path.join(repoRoot, 'backend', 'prisma');
const prismaSchema = path.join(prismaDir, 'schema.prisma');

const MODEL_NAME_MAP: Record<string, string> = {
  users: 'User',
  shops: 'Shop',
  posts: 'Post',
  post_images: 'PostImage',
  comments: 'Comment',
  likes: 'Like',
  bookmarks: 'Bookmark',
  favorites: 'Favorite',
  ai_chat_logs: 'AiChatLog',
  shop_proposals: 'ShopProposal',
  personal_access_tokens: 'PersonalAccessToken',
  sessions: 'Session',
  cache: 'Cache',
  cache_locks: 'CacheLock',
  password_reset_tokens: 'PasswordResetToken',
};

function parseShopGenreEnum(): { name: string; value: string }[] {
  try {
    const php = fs.readFileSync(enumFile, 'utf-8');
    const pairs = [...php.matchAll(/case\s+(\w+)\s*=\s*'([^']+)'/g)]
      .map((m) => ({ name: m[1]!, value: m[2]! }))
      .filter((p) => p.name && p.value);
    return pairs;
  } catch {
    return [];
  }
}

function parseCreateBlocks(content: string): Table[] {
  const tables: Table[] = [];
  const re = /Schema::create\('([^']+)'\s*,\s*function\s*\(Blueprint\s*\$table\)\s*\{([\s\S]*?)\}\s*\)\s*;/gm;
  let m: RegExpExecArray | null;
  while ((m = re.exec(content))) {
    const name = m[1]!;
    const body = m[2] || '';
    const t: Table = { name, columns: [], uniques: [], indexes: [], foreigns: [] };
    const lines = body.split(/\n|;/g).map((l) => l.trim()).filter(Boolean);
    for (const line of lines) {
      if (/\$table->id\(\)/.test(line)) {
        t.columns.push({ name: 'id', type: 'id' });
        continue;
      }
      let mm;
      if ((mm = line.match(/\$table->string\('([^']+)'(?:,\s*(\d+))?\)(.*)/))) {
        const chain = mm[3] || '';
        const primary = /->primary\(\)/.test(chain);
        const nullable = /->nullable\(\)/.test(chain);
        const defStr = (chain.match(/->default\(([^)]+)\)/)?.[1] ?? '').replace(/^'|'$/g, '');
        t.columns.push({ name: mm[1]!, type: 'string', length: mm[2] ? parseInt(mm[2]!) : undefined, primary, nullable, default: defStr || undefined });
        continue;
      }
      if ((mm = line.match(/\$table->text\('([^']+)'\)(.*)/))) {
        const chain = mm[2] || '';
        const nullable = /->nullable\(\)/.test(chain);
        t.columns.push({ name: mm[1]!, type: 'text', nullable });
        continue;
      }
      if ((mm = line.match(/\$table->mediumText\('([^']+)'\)(.*)/))) {
        const chain = mm[2] || '';
        const nullable = /->nullable\(\)/.test(chain);
        t.columns.push({ name: mm[1]!, type: 'text', nullable });
        continue;
      }
      if ((mm = line.match(/\$table->longText\('([^']+)'\)(.*)/))) {
        const chain = mm[2] || '';
        const nullable = /->nullable\(\)/.test(chain);
        t.columns.push({ name: mm[1]!, type: 'text', nullable });
        continue;
      }
      if ((mm = line.match(/\$table->boolean\('([^']+)'\)(?:->default\((true|false)\))?/))) {
        t.columns.push({ name: mm[1]!, type: 'boolean', default: mm[2] });
        continue;
      }
      if ((mm = line.match(/\$table->unsignedInteger\('([^']+)'\)(.*)/)) || (mm = line.match(/\$table->integer\('([^']+)'\)(.*)/))) {
        const col = mm[1]!;
        const chain = mm[2] || '';
        const nullable = /->nullable\(\)/.test(chain);
        const defNum = chain.match(/->default\((\d+)\)/)?.[1];
        t.columns.push({ name: col, type: 'integer', nullable, default: defNum });
        continue;
      }
      if ((mm = line.match(/\$table->tinyInteger\('([^']+)'\)/))) {
        t.columns.push({ name: mm[1]!, type: 'tinyInteger' });
        continue;
      }
      if ((mm = line.match(/\$table->decimal\('([^']+)'\s*,\s*(\d+)\s*,\s*(\d+)\)(.*)/))) {
        const chain = mm[4] || '';
        const nullable = /->nullable\(\)/.test(chain);
        t.columns.push({ name: mm[1]!, type: 'decimal', precision: parseInt(mm[2]!), scale: parseInt(mm[3]!), nullable });
        continue;
      }
      if ((mm = line.match(/\$table->json\('([^']+)'\)(.*)/))) {
        const chain = mm[2] || '';
        const nullable = /->nullable\(\)/.test(chain);
        t.columns.push({ name: mm[1]!, type: 'json', nullable });
        continue;
      }
      if ((mm = line.match(/\$table->timestamp\('([^']+)'\)(.*)/))) {
        const chain = mm[2] || '';
        t.columns.push({ name: mm[1]!, type: 'timestamp', nullable: /->nullable\(\)/.test(chain) });
        continue;
      }
      if (/\$table->timestamps\(\)/.test(line)) {
        t.columns.push({ name: 'created_at', type: 'timestamp' });
        t.columns.push({ name: 'updated_at', type: 'timestamp' });
        continue;
      }
      if (/\$table->softDeletes\(\)/.test(line)) {
        t.columns.push({ name: 'deleted_at', type: 'timestamp', nullable: true });
        continue;
      }
      if ((mm = line.match(/\$table->enum\('([^']+)'\s*,\s*(\[[^\]]+\])\)/))) {
        // static enum values Inline
        const raw = mm[2]!;
        const values = [...raw.matchAll(/'([^']+)'/g)].map((x) => x[1]!).filter(Boolean) as string[];
        t.columns.push({ name: mm[1]!, type: 'enum', enumValues: values });
        continue;
      }
      if ((mm = line.match(/\$table->foreignId\('([^']+)'\)([^;]*)/))) {
        const col = mm[1]!;
        const chain = mm[2] || '';
        const nullable = /->nullable\(\)/.test(chain);
        let on = col.endsWith('_id') ? col.slice(0, -3) + 's' : '';
        const cons = chain.match(/->constrained\('([^']+)'\)/);
        if (cons) on = cons[1]!;
        if (!on) on = col.endsWith('_id') ? col.slice(0, -3) + 's' : '';
        t.columns.push({ name: col, type: 'bigint', nullable });
        t.foreigns.push({ column: col, references: 'id', on, onDelete: chain.includes('onDelete(') ? (chain.match(/onDelete\('([^']+)'\)/)?.[1] ?? null) : null, onUpdate: chain.includes('onUpdate(') ? (chain.match(/onUpdate\('([^']+)'\)/)?.[1] ?? null) : null, nullable });
        continue;
      }
      // explicit foreign($)->references()->on()
      if ((mm = line.match(/\$table->foreign\('([^']+)'\)->references\('([^']+)'\)->on\('([^']+)'\)([^;]*)/))) {
        const col = mm[1]!;
        const ref = mm[2]!;
        const on = mm[3]!;
        const rest = mm[4] || '';
        t.foreigns.push({ column: col, references: ref, on, onDelete: rest.includes('onDelete(') ? (rest.match(/onDelete\('([^']+)'\)/)?.[1] ?? null) : null, onUpdate: rest.includes('onUpdate(') ? (rest.match(/onUpdate\('([^']+)'\)/)?.[1] ?? null) : null });
        // Add column type if it doesn't exist yet
        if (!t.columns.some((c) => c.name === col)) t.columns.push({ name: col, type: 'bigint' });
        continue;
      }
      // indexes
      if ((mm = line.match(/\$table->unique\(\[(.+?)\](?:,\s*'([^']+)')?\)/))) {
        const cols = [...mm[1]!.matchAll(/'([^']+)'/g)].map((x) => x[1]!).filter(Boolean) as string[];
        t.uniques.push({ columns: cols, name: mm[2] || undefined });
        continue;
      }
      if ((mm = line.match(/\$table->index\(\[(.+?)\](?:,\s*'([^']+)')?\)/)) || (mm = line.match(/\$table->index\('([^']+)'(?:,\s*'([^']+)')?\)/))) {
        const group = mm[1]!;
        const cols = group.includes("'") ? [...group.matchAll(/'([^']+)'/g)].map((x) => x[1]!).filter(Boolean) as string[] : [group];
        t.indexes.push({ columns: cols, name: mm[2] || undefined });
        continue;
      }
    }
    tables.push(t);
  }
  return tables;
}

function applyTableAlterations(content: string, tables: Map<string, Table>) {
  // Handle posts content length change and nullable, and add shop_id
  const re = /Schema::table\('([^']+)'\s*,\s*function\s*\(Blueprint\s*\$table\)\s*\{([\s\S]*?)\}\s*\)\s*;/gm;
  let m: RegExpExecArray | null;
  while ((m = re.exec(content))) {
    const name = m[1]!;
    const body = m[2] || '';
    const t = tables.get(name);
    if (!t) continue;
    if (body.includes("->change()") && body.includes("'content'")) {
      const c = t.columns.find((c) => c.name === 'content');
      if (c) {
        c.length = 500;
        c.nullable = true;
      }
    }
    // add foreignId in alters
    const mm = body.match(/\$table->foreignId\('([^']+)'\)([^;]*)/);
    if (mm) {
      const col = mm[1]!;
      const chain = mm[2] || '';
      const nullable = /->nullable\(\)/.test(chain);
      let on = col.endsWith('_id') ? col.slice(0, -3) + 's' : '';
      const cons = chain.match(/->constrained\('([^']+)'\)/);
      if (cons) on = cons[1]!;
      if (!on) on = col.endsWith('_id') ? col.slice(0, -3) + 's' : '';
      if (!t.columns.some((c) => c.name === col)) t.columns.push({ name: col, type: 'bigint', nullable });
      t.foreigns.push({ column: col, references: 'id', on, onDelete: chain.includes('onDelete(') ? (chain.match(/onDelete\('([^']+)'\)/)?.[1] ?? null) : null, onUpdate: chain.includes('onUpdate(') ? (chain.match(/onUpdate\('([^']+)'\)/)?.[1] ?? null) : null, nullable });
    }

    // Add simple added columns in alters (boolean/integer/text/decimal/string/timestamp)
    const alterLines = body.split(/\n|;/g).map((l) => l.trim()).filter(Boolean);
    for (const line of alterLines) {
      let m2: RegExpMatchArray | null;
      if ((m2 = line.match(/\$table->boolean\('([^']+)'\)(.*)/))) {
        const col = m2[1]!;
        const chain = m2[2] || '';
        const defBool = chain.match(/->default\((true|false)\)/)?.[1];
        if (!t.columns.some((c) => c.name === col)) t.columns.push({ name: col, type: 'boolean', default: defBool });
      } else if ((m2 = line.match(/\$table->integer\('([^']+)'\)/))) {
        const col = m2[1]!;
        const defNum = line.match(/->default\((\d+)\)/)?.[1];
        if (!t.columns.some((c) => c.name === col)) t.columns.push({ name: col, type: 'integer', default: defNum });
      } else if ((m2 = line.match(/\$table->string\('([^']+)'(?:,\s*(\d+))?\)/))) {
        const col = m2[1]!;
        if (!t.columns.some((c) => c.name === col)) t.columns.push({ name: col, type: 'string' });
      } else if ((m2 = line.match(/\$table->text\('([^']+)'\)/))) {
        const col = m2[1]!;
        if (!t.columns.some((c) => c.name === col)) t.columns.push({ name: col, type: 'text' });
      } else if ((m2 = line.match(/\$table->decimal\('([^']+)'\s*,\s*(\d+)\s*,\s*(\d+)\)/))) {
        const col = m2[1]!;
        if (!t.columns.some((c) => c.name === col)) t.columns.push({ name: col, type: 'decimal', precision: parseInt(m2[2]!), scale: parseInt(m2[3]!) });
      } else if ((m2 = line.match(/\$table->timestamp\('([^']+)'\)/))) {
        const col = m2[1]!;
        if (!t.columns.some((c) => c.name === col)) t.columns.push({ name: col, type: 'timestamp' });
      }
    }
  }
}

function toPrismaScalar(c: Column): string {
  switch (c.type) {
    case 'id':
      return 'BigInt';
    case 'string':
    case 'text':
      return 'String';
    case 'boolean':
      return 'Boolean';
    case 'integer':
    case 'tinyInteger':
      return 'Int';
    case 'bigint':
      return 'BigInt';
    case 'json':
      return 'Json';
    case 'timestamp':
      return 'DateTime';
    case 'decimal':
      return 'Decimal';
    case 'enum':
      return 'String';
    default:
      return 'String';
  }
}

function generateModel(t: Table, enums: { ShopGenre?: { name: string; value: string }[] }, backrefs: Map<string, { name: string; model: string }[]>): string {
  const lines: string[] = [];
  const modelName = MODEL_NAME_MAP[t.name] ?? toPascal(t.name);
  lines.push(`model ${modelName} {`);
  for (const c of t.columns) {
    const parts: string[] = [];
    let scalar = toPrismaScalar(c);
    if (t.name === 'shop_proposals' && c.name === 'genre' && enums.ShopGenre && enums.ShopGenre.length) {
      // map to native enum
      scalar = 'ShopGenre';
    }
    parts.push(`${c.name} ${scalar}${c.nullable && c.name !== 'id' ? '?' : ''}`);
    if (c.type === 'id' && c.name === 'id') {
      parts.push('@id @default(autoincrement())');
    }
    if (c.primary && !(c.type === 'id' && c.name === 'id')) {
      parts.push('@id');
    }
    if (c.name === 'updated_at' && scalar === 'DateTime') {
      parts.push('@updatedAt');
    }
    if (c.type === 'decimal' && c.precision && c.scale) {
      parts.push(`@db.Decimal(${c.precision}, ${c.scale})`);
    }
    if (c.type === 'timestamp') {
      // Laravel timestamps default to now
      if (c.name === 'created_at') parts.push('@default(now())');
    }
    if (c.type === 'boolean' && (c.default === 'true' || c.default === 'false')) {
      parts.push(`@default(${c.default})`);
    }
    if ((c.type === 'integer' || c.type === 'tinyInteger') && c.default !== undefined) {
      const n = Number(c.default);
      if (!Number.isNaN(n)) parts.push(`@default(${n})`);
    }
    lines.push(`  ${parts.join(' ')}`);
  }

  // Relations (basic fields only; relation fields can be added later manually)
  for (const f of t.foreigns) {
    const relModel = MODEL_NAME_MAP[f.on] ?? toPascal(f.on);
    const fieldName = camelize(MODEL_NAME_MAP[f.on] ?? toPascal(f.on));
    const colDef = t.columns.find((c) => c.name === f.column);
    const isOptional = f.nullable === true || (colDef?.nullable === true) || false;
    lines.push(`  ${fieldName} ${relModel}${isOptional ? '?' : ''} @relation(fields: [${f.column}], references: [${f.references}])`);
  }

  // Back-relation list fields
  const br = backrefs.get(t.name) || [];
  for (const b of br) {
    lines.push(`  ${b.name} ${b.model}[]`);
  }

  // Unique constraints
  for (const u of t.uniques) {
    lines.push(`  @@unique([${u.columns.join(', ')}]${u.name ? `, name: \"${u.name}\"` : ''})`);
  }

  // Map to existing snake_case table name
  lines.push(`  @@map(\"${t.name}\")`);
  lines.push('}\n');
  return lines.join('\n');
}

function toPascal(name: string): string {
  return name
    .split('_')
    .map((s) => s.charAt(0).toUpperCase() + s.slice(1))
    .join('');
}

function camelize(name: string): string {
  return name.charAt(0).toLowerCase() + name.slice(1);
}

function main() {
  const files = fs.readdirSync(migrationsDir).filter((f) => f.endsWith('.php'));
  const content = files.map((f) => fs.readFileSync(path.join(migrationsDir, f), 'utf-8')).join('\n');
  const tablesArr = parseCreateBlocks(content);
  const tables = new Map<string, Table>(tablesArr.map((t) => [t.name, t]));
  applyTableAlterations(content, tables);
  const shopGenre = parseShopGenreEnum();

  // Build backrefs map parentTable -> list of back fields
  const backrefs = new Map<string, { name: string; model: string }[]>();
  for (const t of tables.values()) {
    for (const f of t.foreigns) {
      const parent = f.on;
      const childModel = MODEL_NAME_MAP[t.name] ?? toPascal(t.name);
      let fieldName = camelize(childModel) + 's';
      if (t.name === 'post_images' && parent === 'posts') fieldName = 'images';
      const list = backrefs.get(parent) || [];
      if (!list.find((x) => x.name === fieldName)) list.push({ name: fieldName, model: childModel });
      backrefs.set(parent, list);
    }
  }

  const header = `// Generated from Laravel migrations\n` +
    `generator client {\n  provider = \"prisma-client-js\"\n}\n\n` +
    `datasource db {\n  provider = \"postgresql\"\n  url      = env(\"DATABASE_URL\")\n}\n\n` +
    (shopGenre.length
      ? `enum ShopGenre {\n${shopGenre.map((p) => `  ${p.name} @map(${JSON.stringify(p.value)})`).join('\n')}\n}\n\n`
      : '');

  let body = '';
  const order = [
    'users',
    'shops',
    'posts',
    'post_images',
    'comments',
    'likes',
    'bookmarks',
    'favorites',
    'ai_chat_logs',
    'shop_proposals',
    'personal_access_tokens',
    'sessions',
  ];
  const names = Array.from(tables.keys()).sort((a, b) => order.indexOf(a) - order.indexOf(b));
  for (const name of names) {
    const t = tables.get(name)!;
    body += generateModel(t, { ShopGenre: shopGenre }, backrefs);
  }

  fs.mkdirSync(prismaDir, { recursive: true });
  fs.writeFileSync(prismaSchema, header + body, 'utf-8');
  // eslint-disable-next-line no-console
  console.log(`Generated ${path.relative(repoRoot, prismaSchema)}`);
}

main();
