# auth.md - Bori's Day Agent Registration & Access Policy

## Audience
Automated AI search, scholarly retrieval, research, and coding agents accessing `https://boriasanai.github.io/bori-blog`.

## Supported Authentication & Identity Model
- `identity_types_supported`: `["anonymous"]`
- `registration_required`: `false`
- Every article, Markdown twin (`/posts/<slug>/index.md`, `/index.md`, `/about/index.md`), corpus export (`/llms.txt`, `/llms-full.txt`), OpenAPI specification (`/openapi.json`), and API catalog (`/.well-known/api-catalog`) is a **public read-only (`GET` / `HEAD`)** resource.

## Registration & Provisioning Endpoints
No API key, OAuth 2.0 bearer token, or automated agent account provisioning (`POST /agent/auth`) is required or supported.

## Credential Usage & Etiquette
- Issue standard unauthenticated `GET` or `HEAD` requests without `Authorization` headers.
- Fetch `<article_url>index.md` or `/bori-blog/llms-full.txt` when clean Markdown text is preferred over full HTML layout.

## Non-Commerce Scope
`Bori's Day` is an open research and reflection journal, not a transactional store; commerce and payment protocols (`ACP`, `AP2`) do not apply.
