---
type: Reference
title: OKF v0.2 Overview
status: stable
version: 1.0
description: Open Knowledge Format overview and design principles.
tags: [okf, standards, provenance]
---
> [!IMPORTANT]
> **OKF now lives in its own repository:
> [GoogleCloudPlatform/open-knowledge-format](https://github.com/GoogleCloudPlatform/open-knowledge-format).**
>
> That repository is the canonical home of the specification, the reference
> agent, and the sample bundles. Please read the spec, file issues, and open
> pull requests there.
>
> **Stop using the copy under `okf/` in this repository.** It is a frozen
> snapshot, no longer maintained, and anything built against it will drift out
> of date.

# Open Knowledge Format (OKF)

### 📖 [Read the Open Knowledge Format v0.2 specification → SPEC.md](SPEC.md)

> **This directory is primarily about the [Open Knowledge Format
> (OKF)](SPEC.md).**
>
> OKF is a **universal, vendor-neutral format** for representing knowledge
> as plain markdown files with YAML frontmatter. It is **not tied to any
> particular agent, framework, model provider, or serving system**. The
> goal is simple:
>
> - **Anyone can produce** OKF - humans authoring by hand, agents built on
>   any framework (Google ADK, LangChain, custom), export pipelines from
>   existing catalogs (Dataplex, Unity Catalog, Collibra, …), or scripts
>   walking a database.
> - **Anyone can serve and consume** OKF - a static file server, a
>   knowledge-management UI (Obsidian, Notion, MkDocs), an LLM loading
>   files into context, a search index, or a graph viewer like the one
>   bundled in this repo.
>
> The agent below is a **proof of concept** demonstrating *one* way to
> produce OKF bundles automatically. The format itself is the
> contribution; this agent and the visualizer exist to make the format
> tangible at both ends - production and consumption.
>
> **See OKF in practice** - three ready-to-browse bundles produced by this
> agent, checked into [`bundles/`](bundles/):
>
> - [`bundles/ga4/`](bundles/ga4/) - GA4 e-commerce dataset
>   ([viz.html](bundles/ga4/viz.html))
> - [`bundles/stackoverflow/`](bundles/stackoverflow/) - Stack Overflow
>   public dataset ([viz.html](bundles/stackoverflow/viz.html))
> - [`bundles/crypto_bitcoin/`](bundles/crypto_bitcoin/) - Bitcoin
>   blocks/transactions ([viz.html](bundles/crypto_bitcoin/viz.html))
> - [`bundles/acme_retail/`](bundles/acme_retail/) - Acme Retail
>   ([viz.html](bundles/acme_retail/viz.html))

## Why OKF?

OKF represents catalog knowledge as plain markdown files with YAML
frontmatter, organized in a directory hierarchy. That choice unlocks a few
properties that are hard to get from a service-owned metadata store:

- **Human- and agent-readable.** No SDK or query language stands between a
  reader and the content. An engineer can `cat` a concept; an LLM can ingest
  it verbatim into context.
- **Version-controllable out of the box.** Bundles live in git. Pull
  requests, line-by-line diffs, blame, and review workflows just work -
  knowledge curation becomes a normal software-engineering activity.
- **Portable and lock-in free.** A bundle is a directory. Ship it as a
  tarball, host it in any repo, mount it from any filesystem, or sync it to
  any system that speaks files. No proprietary API stands between you and
  your metadata.
- **Mixes structured and unstructured data deliberately.** Use frontmatter
  for the few fields you want to query, filter, or index on (`type`,
  `resource`, `tags`, `generated`, `status`); use the markdown body for the
  prose, schemas, and example queries that LLMs and humans actually read.
- **Trust, provenance, and freshness are first-class.** v0.2 puts queryable
  signals in frontmatter - where a concept came from (`sources` with per-source
  credibility signals), who produced and confirmed it (`generated`, `verified`,
  from which consumers derive a trust tier), and whether it is still current
  (`status`, `stale_after`) - so an agent-maintained corpus stays trustable
  without any bespoke runtime.
- **Minimally opinionated, freely extensible.** A small set of required
  keys ensures interoperability, but bundles can carry arbitrary extra
  frontmatter keys and arbitrary body sections without breaking
  consumers.
- **Composes with existing tooling.** Many knowledge tools - Notion,
  Obsidian, MkDocs, Hugo, Jekyll - already speak markdown plus YAML
  frontmatter, so bundles can be browsed, edited, or rendered without
  custom UI.
- **Progressive disclosure built in.** Auto-generated `index.md` files
  let an agent or human navigate the hierarchy one level at a time
  instead of loading the entire bundle into context.
- **Graph-shaped, not just tree-shaped.** Concepts link to each
