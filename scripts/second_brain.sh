#!/bin/bash

# =============================================================
# PARA Second Brain Setup Script for Obsidian + Google Drive
# =============================================================
# Usage:
#   chmod +x setup_para.sh
#   ./setup_para.sh
# =============================================================

VAULT_DIR="$HOME/gdrive/ai_everywhere"

# -------------------------------------------------------------
# Helpers
# -------------------------------------------------------------
info()    { echo -e "\033[1;34m[INFO]\033[0m  $*"; }
success() { echo -e "\033[1;32m[OK]\033[0m    $*"; }

# -------------------------------------------------------------
# Create PARA folder structure
# -------------------------------------------------------------
info "Creating PARA folder structure at $VAULT_DIR..."

mkdir -p "$VAULT_DIR/Projects"
mkdir -p "$VAULT_DIR/Areas/Health"
mkdir -p "$VAULT_DIR/Areas/Finances"
mkdir -p "$VAULT_DIR/Areas/Work"
mkdir -p "$VAULT_DIR/Areas/Personal"
mkdir -p "$VAULT_DIR/Resources/Bookmarks"
mkdir -p "$VAULT_DIR/Resources/Articles"
mkdir -p "$VAULT_DIR/Resources/Ideas"
mkdir -p "$VAULT_DIR/Resources/References"
mkdir -p "$VAULT_DIR/Archives/Completed Projects"
mkdir -p "$VAULT_DIR/Archives/Inactive Areas"
mkdir -p "$VAULT_DIR/Daily Notes"
mkdir -p "$VAULT_DIR/Templates"

success "Folders created."

# -------------------------------------------------------------
# Create README / Home note
# -------------------------------------------------------------
cat > "$VAULT_DIR/Home.md" << 'EOF'
# 🧠 Second Brain

Welcome to your Second Brain, built on the PARA method.

## What is PARA?
| Folder | Description | Example |
|---|---|---|
| 📁 Projects | Active goals with a deadline | Build portfolio, Plan trip |
| 📁 Areas | Ongoing responsibilities | Health, Finances, Work |
| 📁 Resources | Reference material & interests | Articles, Ideas, Bookmarks |
| 📁 Archives | Completed or inactive items | Old projects, past notes |

## Quick Links
- [[Daily Notes]] — your daily capture
- [[Projects]] — what you're working on now
- [[Areas]] — what you're responsible for
- [[Resources]] — what you're interested in

## The Golden Rule
> Every note lives in exactly ONE of the four PARA folders.
> When in doubt, put it in Resources. You can always move it later.
EOF
success "Home note created."

# -------------------------------------------------------------
# Create Projects README
# -------------------------------------------------------------
cat > "$VAULT_DIR/Projects/README.md" << 'EOF'
# 📁 Projects

Projects are things you're **actively working on** with a clear end goal.

## Rules
- Every project must have a goal and an (approximate) deadline
- When a project is done → move it to **Archives/Completed Projects**
- Keep this list short — if everything is a project, nothing is

## Active Projects
- [ ] Add your first project below...

## How to create a new project note
1. Create a new file in this folder e.g. `Japan Trip 2026.md`
2. Use the Project Template (Templates/Project Template.md)
EOF
success "Projects README created."

# -------------------------------------------------------------
# Create Areas README
# -------------------------------------------------------------
cat > "$VAULT_DIR/Areas/README.md" << 'EOF'
# 📁 Areas

Areas are **ongoing responsibilities** with no end date.

## Rules
- Areas don't get completed — they get maintained
- Review your areas weekly to make sure nothing is slipping
- If an area becomes inactive → move it to **Archives/Inactive Areas**

## Your Areas
- Health
- Finances
- Work
- Personal

## Tips
- Keep one note per area as a dashboard (e.g. `Health.md`)
- Link related projects to their area
EOF
success "Areas README created."

# -------------------------------------------------------------
# Create Resources README
# -------------------------------------------------------------
cat > "$VAULT_DIR/Resources/README.md" << 'EOF'
# 📁 Resources

Resources are **topics and references** you're interested in or may need later.

## Rules
- No action required — this is pure reference material
- Save bookmarks, articles, ideas, and notes here
- Use subfolders to keep things organized

## Subfolders
- **Bookmarks/** — saved links and websites
- **Articles/** — summaries of articles you've read
- **Ideas/** — random thoughts and ideas to explore later
- **References/** — how-tos, cheat sheets, documentation

## Tips
- Don't over-organize — a messy Resources folder is fine
- Use tags to cross-reference topics across notes
EOF
success "Resources README created."

# -------------------------------------------------------------
# Create Archives README
# -------------------------------------------------------------
cat > "$VAULT_DIR/Archives/README.md" << 'EOF'
# 📁 Archives

Archives are **completed or inactive** items from the other three folders.

## Rules
- Never delete — always archive
- Move completed projects here when done
- Move inactive areas here when no longer relevant

## Subfolders
- **Completed Projects/** — finished projects
- **Inactive Areas/** — areas you're no longer maintaining

## Tips
- Archives are searchable — don't worry about forgetting things
- Review archives occasionally for ideas to revive
EOF
success "Archives README created."

# -------------------------------------------------------------
# Create Project Template
# -------------------------------------------------------------
cat > "$VAULT_DIR/Templates/Project Template.md" << 'EOF'
# 📌 {{Project Name}}

## Goal
What does done look like?

## Deadline
📅 

## Why it matters
Why is this project important?

## Tasks
- [ ] First task
- [ ] Second task
- [ ] Third task

## Notes & Updates
### {{Date}}
- 

## Resources
- Links to related notes or files

## Status
- [ ] Active
- [ ] On Hold
- [ ] Completed → move to Archives
EOF
success "Project template created."

# -------------------------------------------------------------
# Create Daily Note Template
# -------------------------------------------------------------
cat > "$VAULT_DIR/Templates/Daily Note Template.md" << 'EOF'
# 📅 {{date:YYYY-MM-DD}}

## 🌅 Morning — What's the plan?
**Top 3 priorities today:**
- [ ] 
- [ ] 
- [ ] 

## 📥 Capture — Notes & thoughts throughout the day
- 

## 🔖 Bookmarks & links saved today
- 

## ✅ Evening — How did it go?
**What got done:**
- 

**What to carry over to tomorrow:**
- 

## 💡 Ideas & reflections
- 
EOF
success "Daily Note template created."

# -------------------------------------------------------------
# Create Area templates
# -------------------------------------------------------------
for area in Health Finances Work Personal; do
cat > "$VAULT_DIR/Areas/${area}.md" << EOF
# 📁 ${area}

## Overview
What does success look like in this area?

## Current Focus
- 

## Regular Tasks / Habits
- [ ] 

## Notes & Updates
- 

## Related Projects
- 

## Resources
- 
EOF
done
success "Area notes created."

# -------------------------------------------------------------
# Done!
# -------------------------------------------------------------
echo ""
echo "============================================="
success "PARA structure setup complete!"
echo "============================================="
echo ""
echo "  📁 Vault location: $VAULT_DIR"
echo ""
echo "  Folders created:"
echo "    Projects/"
echo "    Areas/          (Health, Finances, Work, Personal)"
echo "    Resources/      (Bookmarks, Articles, Ideas, References)"
echo "    Archives/       (Completed Projects, Inactive Areas)"
echo "    Daily Notes/"
echo "    Templates/"
echo ""
echo "  Next steps:"
echo "  1. Open Obsidian and set vault to: $VAULT_DIR"
echo "  2. Install plugins: Dataview, Tasks, Templater, Calendar"
echo "  3. Set Templates/ as your template folder in Obsidian settings"
echo "  4. Create your first daily note using the Daily Note Template"
echo ""