---
name: api-conventions
description: REST API naming conventions
disable-model-invocation: false
---

# API Conventions

Apply these conventions when working with API code:

## URL Paths
- Use kebab-case for URL paths (e.g., `/user-profiles`, `/order-items`)
- Use plural nouns for collections (e.g., `/users`, `/orders`)
- Use lowercase letters only

## JSON Properties
- Use camelCase for JSON property names (e.g., `firstName`, `orderDate`)
- Use consistent naming across all endpoints

## Pagination
- Always include pagination for list endpoints
- Use `page` and `limit` query parameters
- Return total count in response metadata

## HTTP Methods
- GET: Read operations
- POST: Create operations
- PUT: Full update operations
- PATCH: Partial update operations
- DELETE: Delete operations

## Response Format
```json
{
  "data": [...],
  "meta": {
    "total": 100,
    "page": 1,
    "limit": 10
  }
}
```
