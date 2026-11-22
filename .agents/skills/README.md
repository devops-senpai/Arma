# Arma skills for agents

Skills that teach a coding agent to set up, use and manage the Arma browser. Each folder
holds a `SKILL.md` in the Agent Skills format: a name and a description the agent reads to
decide when to load it, then the instructions.

| Skill | Teaches |
| --- | --- |
| [`arma-setup`](arma-setup/SKILL.md) | Install and start Arma, put `arma` on the PATH, make Spaces, pick engines and search, import from another browser |
| [`arma-basics`](arma-basics/SKILL.md) | How Arma is organized: Spaces, the three kinds of tab, folders, the command palette, Peek, Quick Windows, Split View, shortcuts |
| [`arma-cli`](arma-cli/SKILL.md) | The `arma` command: its rules, common actions and a [full reference](arma-cli/reference.md) |
| [`arma-themes`](arma-themes/SKILL.md) | Make, edit, share and apply themes, and shape a Space's crest |
| [`arma-agent-browsing`](arma-agent-browsing/SKILL.md) | Read and act inside pages: the MCP server, `arma page`, and the automation port for testing frameworks |
| [`arma-power-user`](arma-power-user/SKILL.md) | Recipes: organize a Space, build layouts, route sites to engines, script passwords, back up a setup |

Start with `arma-setup` on a new Mac and `arma-basics` to learn the terms. The others
stand alone.

## Where agents find them

This folder, `.agents/skills/`, is the Agent Skills standard's project location. In a
checkout of Arma, Codex, GitHub Copilot, Cursor, Gemini CLI, Windsurf, OpenCode and Amp
read it as it is. Claude Code reads `.claude/skills/` and Kiro reads `.kiro/skills/`, so
each holds a link to every skill here; add the links for a new skill.

For another project, or for every project, copy or link the folders where your agent
looks:

```sh
git clone https://github.com/devops-senpai/Arma.git
cp -R Arma/.agents/skills/arma-* ~/.agents/skills/      # Codex, Copilot, Gemini CLI, Windsurf, OpenCode, for every project
cp -R Arma/.agents/skills/arma-* ~/.claude/skills/      # Claude Code
cp -R Arma/.agents/skills/arma-* ~/.kiro/skills/        # Kiro
cp -R Arma/.agents/skills/arma-* <project>/.agents/skills/   # or one project
```

Each skill also carries `agents/openai.yaml`, the name and summary Codex shows for it.

## What they need

- Arma for Mac, open. The `arma` command talks to the running app.
- The command itself, at `/Applications/Arma.app/Contents/Helpers/arma`. Type `@cli` in
  Arma's command palette to put it on the PATH.
- For reading and acting inside pages, the person turns agents on in Settings › Agents.
  Themes, tabs, Spaces, settings and the rest need only Arma running.

The skills describe the commands of the Arma version they shipped with.
`arma <section> help` prints what the installed version takes; when the two differ, the
app is right.

These skills are for using Arma. To change Arma's source, load the contribution skill in
`.agents/skills/crest-contribution` instead.
