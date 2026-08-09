export type JsonSchema = {
  type: "object" | "array" | "string" | "number" | "integer" | "boolean";
  properties?: Record<string, JsonSchema>;
  required?: string[];
  additionalProperties?: boolean;
  items?: JsonSchema;
  enum?: Array<string | number | boolean>;
  minItems?: number;
  maxItems?: number;
  minLength?: number;
};

export interface SchemaValidation {
  valid: boolean;
  issues: string[];
}

export function validateSchema(
  value: unknown,
  schema: JsonSchema,
  path = "$",
): SchemaValidation {
  const issues: string[] = [];
  validate(value, schema, path, issues);
  return { valid: issues.length === 0, issues };
}

function validate(
  value: unknown,
  schema: JsonSchema,
  path: string,
  issues: string[],
): void {
  if (schema.enum && !schema.enum.some((item) => item === value)) {
    issues.push(`${path} is not an allowed value`);
    return;
  }

  if (schema.type === "object") {
    if (!isRecord(value)) {
      issues.push(`${path} must be an object`);
      return;
    }
    const properties = schema.properties ?? {};
    for (const required of schema.required ?? []) {
      if (!(required in value)) issues.push(`${path}.${required} is required`);
    }
    if (schema.additionalProperties === false) {
      for (const key of Object.keys(value)) {
        if (!(key in properties)) issues.push(`${path}.${key} is not allowed`);
      }
    }
    for (const [key, propertySchema] of Object.entries(properties)) {
      if (key in value) {
        validate(value[key], propertySchema, `${path}.${key}`, issues);
      }
    }
    return;
  }

  if (schema.type === "array") {
    if (!Array.isArray(value)) {
      issues.push(`${path} must be an array`);
      return;
    }
    if (schema.minItems != null && value.length < schema.minItems) {
      issues.push(`${path} has too few items`);
    }
    if (schema.maxItems != null && value.length > schema.maxItems) {
      issues.push(`${path} has too many items`);
    }
    if (schema.items) {
      value.forEach((item, index) =>
        validate(item, schema.items!, `${path}[${index}]`, issues)
      );
    }
    return;
  }

  if (schema.type === "string") {
    if (typeof value !== "string") {
      issues.push(`${path} must be a string`);
    } else if (schema.minLength != null && value.length < schema.minLength) {
      issues.push(`${path} is too short`);
    }
    return;
  }

  if (schema.type === "boolean" && typeof value !== "boolean") {
    issues.push(`${path} must be a boolean`);
  } else if (
    (schema.type === "number" || schema.type === "integer") &&
    typeof value !== "number"
  ) {
    issues.push(`${path} must be a number`);
  } else if (schema.type === "integer" && !Number.isInteger(value)) {
    issues.push(`${path} must be an integer`);
  }
}

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
