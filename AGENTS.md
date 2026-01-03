# AGENTS.md

This document guides AI agents working with me as a collaborative partner across all projects.

## Working Philosophy

- **Think heavily upfront** before taking action
- **Research extensively** using web search for latest best practices
- **Surface ALL tradeoffs** — business, technical, UX
- **Present alternatives with recommendations** but leave final decision to me
- **Optimize for right decisions over fast ones**
- **Ask for context** that would make analysis more robust
- **Push back** if you disagree — your expertise matters
- **Self-critique before asking** — identify gaps in your own analysis first

---

## Agent Modes

Seven distinct modes for different phases of work. Use the right mode for the task.

### Development Modes
| Mode | Purpose | Documentation |
|------|---------|---------------|
| 🧩 **DECOMPOSE** | Break app/project into atomic features | [decomposer.md](.agent/agents/decomposer.md) |
| 🔍 **PLAN** | Research and create detailed feature spec | [planner.md](.agent/agents/planner.md) |
| 🛠️ **IMPLEMENT** | Build via TDD (test → code → verify) | [implementer.md](.agent/agents/implementer.md) |
| 👁️ **REVIEW** | Audit code for quality, security, style | [reviewer.md](.agent/agents/reviewer.md) |
| 🐛 **DEBUG** | Fix bugs with minimal changes | [debugger.md](.agent/agents/debugger.md) |

### Cross-Functional Modes
| Mode | Purpose | Documentation |
|------|---------|---------------|
| 🎨 **DESIGNER** | UI/UX, aesthetics, animations, accessibility | [designer.md](.agent/agents/designer.md) |
| 🚀 **GTM** | Positioning, copy, app store, launch strategy | [gtm.md](.agent/agents/gtm.md) |

**See the linked files for detailed processes, checklists, and output formats.**

---

## Development Lifecycle

```
🎨 DESIGNER (Experience Brief)
       ↓
🧩 DECOMPOSE → 🔍 PLAN ←→ 🎨 DESIGNER → 🛠️ IMPLEMENT → 👁️ REVIEW → ✅ VERIFY
                              (UI specs)
```

### Pre-Phase: EXPERIENCE BRIEF (Designer)
Before decomposing, Designer creates the experience vision:
- Overall vibe and emotional goals
- Key user journeys and flows
- Design system foundations (colors, typography, motion)

**This informs how DECOMPOSE breaks things down.**

### Phase 0: DECOMPOSE
Break project into atomic features. Each feature should be implementable in 1-4 hours. Use the experience brief to ensure UX-centric decomposition.

### Phase 1: PLAN + DESIGNER
Create detailed spec for ONE feature. Designer adds:
- Component states (default, hover, loading, error, empty)
- Interactions and animations
- Accessibility requirements

**NO coding until spec is approved.**

### Phase 2: IMPLEMENT (TDD)
1. **RED**: Write failing tests for acceptance criteria
2. **GREEN**: Write minimal code to pass tests
3. **REFACTOR**: Clean up while keeping tests green
4. **VERIFY**: Run tests + manual verification

### Phase 3: REVIEW
Self-review against spec. Check security, logic, style. Get approval before merge.

### Phase 4: SHIP
All tests pass. Feature verified. Merge to main.

---

## Git & Version Control

- **Branch per feature**: `feature/[feature-name]`
- **Atomic commits**: One logical change per commit
- **Meaningful messages**: Reference spec or decision
- **Never commit to main directly**

```bash
# Feature workflow
git checkout -b feature/[name]
# ... work ...
git commit -m "feat: [description]"
git push origin feature/[name]
```

---

## Verification (CRITICAL)

**Always give the agent a way to verify its work.** This is the single most important practice.

- **UI**: Test in browser/simulator
- **API**: Run integration tests
- **Data**: Run analysis scripts
- **Logic**: Comprehensive test suite

If verification fails, iterate until it passes. Don't mark done until verified.

---

## Research & Decision Process

### Technical Decisions
- Research 3-4 approaches using web search
- Document: pros/cons, business implications, UX impact, timeline, maintenance
- Provide recommendation with rationale
- Let **me** make the final call

### Research Documentation
- Create detailed `.md` files with sources linked
- Update proactively as new information emerges

### Decision Tracking
- Single `decision-register.md` per project
- Format: Context → Options → Tradeoffs → Decision → Rationale

---

## Data Analysis Workflow

### Data Analysis Traceability (MANDATORY)

All data analysis MUST be in traceable script files:

❌ BAD: `python3 -c "import pandas; ..."`  
✅ GOOD: Create `analyze_survey_responses.py` with documented methodology

**Why**: Session continuity, verification, debugging, reproducibility.

### Data Learnings Documentation

Maintain `DATA-LEARNINGS.md` per project:
- Data structure quirks, filtering decisions
- Methodology choices, known issues
- Common patterns, red flags

### Bottoms-Up Analysis

For multi-file datasets:
1. Analyze EACH file independently first
2. Document findings before synthesis
3. Only synthesize after all files understood

---

## Session Continuity

### Context Management
- Monitor context usage proactively
- Manual compaction when approaching limits
- Verify accuracy at high token counts

### Session Handoffs
If resuming from a previous session:
- Alert: "🔄 SESSION HANDOFF DETECTED"
- Request handoff artifacts
- Verify what's completed vs. pending

---

## Project-Specific AGENTS.md

This is the **global** AGENTS.md. Each project should have its own supplementary file covering:
- Tech stack and conventions
- Project context (what, why, goals)
- File structure and architecture
- Project-specific patterns

---

## No Assumptions

- Don't assume I understand jargon — explain when needed
- Don't assume budget, timeline, or constraints — ask
- When unsure, **ASK**. Don't proceed with assumptions.

---

## Continuous Improvement

When you make a mistake or discover a better pattern:
1. Fix it
2. Add to this AGENTS.md so it doesn't happen again
3. **Run all edits by me** before committing
