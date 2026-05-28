# The Clo-Author: AI Research Architecture for Economics

[![Version](https://img.shields.io/github/v/release/hugosantanna/clo-author?style=flat-square&color=b44dff&label=version)](CHANGELOG.md)

> **Work in progress.** This repo is evolving as I learn, and I share it in case others find it useful and would like to build upon it. Expect rough edges.

An open-source [Claude Code](https://docs.anthropic.com/en/docs/claude-code) scaffold for empirical economics research. Provides structured workflows from literature review to journal submission. Can be adapted to other fields (finance, accounting, marketing, management) by customizing the domain profile and journal profiles.

**Live guide:** [hugosantanna.github.io/clo-author](https://hugosantanna.github.io/clo-author/)
<br>**Built on:** [Pedro Sant'Anna's claude-code-my-workflow](https://github.com/pedrohcgs/claude-code-my-workflow)

---

## Quick Start

```bash
# 1. Fork and clone
gh repo fork hugosantanna/clo-author --clone
cd clo-author

# 2. Open Claude Code
claude
```

Then paste this prompt:

> I am starting a new empirical research project in **[YOUR FIELD]** on **[YOUR TOPIC]**.
> Read CLAUDE.md and help me set up the project structure.
> Start with a literature review on [YOUR TOPIC].

Claude reads the configuration, fills in your project details, and plans the approach — you approve the plan, it implements and runs review agents, and you review the results.

**Using VS Code?** Open the Claude Code panel instead. Everything works the same.

---

## What It Does

### How It Works

You describe a task. Claude plans the approach (you approve), implements it, runs specialized review agents, fixes issues, re-verifies, and scores against quality gates. You review the output at each stage.

### Specialized Agents in Worker-Critic Pairs

Every creator has a paired critic. Critics can't edit files; creators can't score themselves.

| Phase | Worker (Creates) | Critic (Reviews) |
|-------|-----------------|-----------------|
| Discovery | Librarian | librarian-critic |
| Discovery | Explorer | explorer-critic |
| Strategy | Strategist | strategist-critic |
| Execution | Coder | coder-critic |
| Execution | Data-engineer | coder-critic |
| Paper | Writer | writer-critic |
| Peer Review | Editor → domain-referee + methods-referee | — |
| Presentation | Storyteller | storyteller-critic |
| Infrastructure | Orchestrator, Verifier | — |

### Simulated Peer Review

`/review --peer [journal]` simulates a full journal submission:

1. **Editor desk review** — reads your paper, verifies novelty claims via web search, decides: desk reject or send to referees
2. **Referee assignment** — editor selects two referees with intellectual dispositions (Structuralist, Credibility, Measurement, Policy, Theory, Skeptic) weighted by journal culture
3. **Independent blind reports** — each referee scores on 5 dimensions with pet peeves (1 critical, 1 constructive), and every major comment includes "what would change my mind"
4. **Editorial decision** — editor classifies each concern as FATAL / ADDRESSABLE / TASTE, sides with one referee when they disagree, produces MUST / SHOULD / MAY action items

Additional modes:
- `--stress [journal]` — adversarial referees for pre-submission battle testing
- `--peer --r2 [journal]` — R&R second round with referee memory (checks whether prior concerns were addressed)
- Max 3 rounds, then the editor's patience runs out — just like real life

**30 journal profiles** across economics and adjacent fields (all top-tier, A* in the Australian Business Deans Council ranking), each with configured referee pools based on published style guides and common review culture.

### 10 Slash Commands

| Category | Commands |
|----------|----------|
| **Research** | `/new-project`, `/discover`, `/strategize`, `/analyze`, `/write` |
| **Review** | `/review`, `/revise` |
| **Output** | `/talk`, `/submit` |
| **Tools** | `/tools` (commit, compile, validate-bib, journal, learn, deploy, context) |

### Quality Gates

Weighted aggregate scoring with per-component minimums:

| Score | Gate | Applies To |
|-------|------|------------|
| 80 | Commit | Weighted aggregate (blocking) |
| 90 | PR | Weighted aggregate (blocking) |
| 95 | Submission | Aggregate + all components >= 80 |
| -- | Advisory | Talks (reported, non-blocking) |

---

## Project Structure

```
your-project/
├── CLAUDE.md                    # Project configuration (fill in placeholders)
├── .claude/                     # Agents, skills, rules, references, hooks
├── Bibliography_base.bib        # Centralized bibliography
├── paper/                       # Main LaTeX manuscript (source of truth)
│   ├── main.tex
│   ├── sections/
│   ├── figures/
│   ├── tables/
│   ├── talks/                   # Beamer presentations
│   ├── quarto/                  # Quarto RevealJS presentations
│   ├── preambles/               # Shared LaTeX headers
│   ├── supplementary/           # Online appendix
│   └── replication/             # Replication package for deposit
├── data/                        # Raw and cleaned datasets
├── scripts/                     # Analysis code (R, Python, Julia)
├── quality_reports/             # Plans, session logs, reviews, scores
├── explorations/                # Research sandbox
└── master_supporting_docs/      # Reference papers and data docs
```

---

## Prerequisites

| Tool | Required For | Install |
|------|-------------|---------|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | Everything | `npm install -g @anthropic-ai/claude-code` |
| XeLaTeX | Paper compilation | [TeX Live](https://tug.org/texlive/) or [MacTeX](https://tug.org/mactex/) |
| R | Analysis & figures | [r-project.org](https://www.r-project.org/) |
| [gh CLI](https://cli.github.com/) | GitHub integration | `brew install gh` (macOS) |

Optional: Python, Julia (for multi-language analysis), [Quarto](https://quarto.org) (web slides).

---

## Setup

1. **Fill in `CLAUDE.md`** — replace `[BRACKETED PLACEHOLDERS]` with your project details
2. **Fill in the domain profile** (`.claude/references/domain-profile.md`) — your journals, data sources, identification strategies, conventions, and seminal references. Use `/discover interview` to populate it interactively.
3. **Add journal profiles** — 30 profiles are included (economics and adjacent fields). Add your own to `.claude/references/journal-profiles.md` using the template at the bottom of the file.
4. **Configure your language** — R is the default; Python and Julia are also supported. Set your preference in CLAUDE.md.

**Adapting to other fields:** The pipeline assumes economics by default (causal inference methods, working paper format, AEA-style conventions). To adapt for finance, accounting, marketing, or management, customize the domain profile and journal profiles. The agents, rules, and section templates will follow the domain profile's field specification.

---

## Origin

This project builds on [Pedro Sant'Anna's claude-code-my-workflow](https://github.com/pedrohcgs/claude-code-my-workflow), which was built for Econ 730 at Emory University. The Clo-Author reorients that infrastructure from lecture production to empirical economics research.

Maintained by [Hugo Sant'Anna](https://hsantanna.org) at UAB.

---

## Upgrading from 2.x

Your files are safe. The upgrade only touches `.claude/` (infrastructure). Your paper, scripts, data, and bibliography are never modified.

1. **Download** the [latest release](https://github.com/hugosantanna/clo-author/releases) or clone clo-author into a temp folder
2. **Delete** your old `.claude/` directory
3. **Copy** the new `.claude/` into your project
4. **Done** — your CLAUDE.md, paper, scripts, and data are untouched

No git merge, no upstream remote, no conflicts. Once on 4.0, future upgrades can use `/tools upgrade`.

---

## Context Efficiency

The architecture loads fewer tokens per session by demand-loading reference files (journal profiles, domain profiles, coding standards) only when agents need them. Rules are path-scoped where possible.

---

## Limitations

- **Scaffold, not autopilot.** Every output — drafts, analysis, reviews — needs human review. Claude plans and executes; you decide what ships.
- **Simulated peer review** catches structural issues (missing robustness, identification gaps, notation errors) but does not replicate actual referee expertise or field-specific judgment.
- **Journal profiles** are based on published style guides and common review culture, not empirical calibration against actual editorial decisions.
- **Quality scores** are heuristic deduction rubrics. They flag problems reliably but do not measure publishability.
- **The writer produces drafts.** It does not replace your writing process — it gives you structured first drafts to revise.

---

## License

MIT License. Fork it, customize it, make it yours.
