# Javascript Style Guide

## General TypeScript Rules

### Function Declarations

- Prefer arrow functions for short, pure functions
- Use function declarations for named functions that may be hoisted
- Use async/await over Promises.then() for better readability

### Variable Declarations

- Use `const` by default
- Use `let` only when reassignment is needed
- Never use `var`

### Error Handling

- Always handle errors explicitly
- Use try/catch blocks for async operations
- Provide meaningful error messages

## TypeScript Type Safety

### Discriminated Union Types

- Use discriminated union types instead of optional properties with boolean flags
- Eliminates need for non-null assertions (!.)
- Provides compile-time type safety for conditional properties

**Example:**

```typescript
// ❌ Avoid - requires non-null assertion
interface Result<T> {
  success: boolean;
  data?: T;
  error?: string;
}

// Usage requires unsafe non-null assertion
if (result.success) {
  return result.data!; // ❌ Non-null assertion needed
}

// ✅ Prefer - type-safe without assertions
type Result<T> = { success: true; data: T } | { success: false; error: string };

// Usage is type-safe
if (result.success) {
  return result.data; // ✅ TypeScript knows data exists
}
```

### Non-null Assertions

- Avoid non-null assertions (!.) when possible
- Use discriminated unions or type guards instead
- Only use when you have absolute certainty the value exists
- Consider refactoring to make null safety explicit in types

### Type Guards

- Use type guards for runtime type checking
- Combine with discriminated unions for comprehensive type safety
- Prefer `typeof` and `instanceof` checks over custom type predicates when possible

**Example:**

```typescript
// ✅ Type guard with discriminated union
function isValidResult<T>(
  result: Result<T>
): result is { success: true; data: T } {
  return result.success;
}

if (isValidResult(result)) {
  console.log(result.data); // Type-safe access
}
```

### Zod Schema Validation

- Use zod for runtime type validation and parsing
- Leverage zod's built-in error messages when appropriate
- Use `z.coerce.number()` instead of manual string-to-number conversion
- Prefer declarative schema over manual validation logic

**Example:**

```typescript
// ✅ Clean zod schema
const configSchema = z.object({
  apiKey: z.string().min(1),
  timeout: z.coerce.number().positive().default(30000),
  retries: z.coerce.number().int().min(0).default(3),
});

// ❌ Avoid manual validation
if (!config.apiKey || config.apiKey.length === 0) {
  throw new Error("API key required");
}
```

## Code Organization

### Imports and Exports

- Group imports: external libraries first, then internal modules
- Use named exports over default exports for better tree-shaking
- Keep imports organized and remove unused imports

### File Structure

- One main export per file
- Keep related types and interfaces in the same file as their implementation
- Use index files to create clean public APIs
