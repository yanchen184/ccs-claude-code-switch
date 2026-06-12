# ccs — AI agent 多帳號無縫切換

> 把一個會 hit limit 的帳號，變成兩個輪流用、且**同一場對話接得起來**的帳號。
> 支援 Claude Code 與 Codex，模組可分開裝（只有其中一個也行）。

額度爆了不用乾等刷新，也不用重開一場對話從頭講。`ccs` 一鍵切到第二個帳號，
**把同一串對話搬過去用它的額度繼續跑**，脈絡完全不斷。

---

## 一鍵安裝（餵給 Claude Code）

把這段貼給 Claude Code，它會自己裝好：

```
請幫我安裝 ccs 多帳號切換系統：
1. git clone https://github.com/yanchen184/ccs-claude-code-switch.git ~/.claude/skills/ccs-switch
2. 確認 fzf 已安裝（沒有就 brew install fzf 或 apt install fzf）
3. 跑 bash ~/.claude/skills/ccs-switch/scripts/install.sh
4. 確認 ~/bin 在我的 PATH
5. 裝完跟我說「接下來要自己做哪幾步登入」，登入指令準備好給我貼，但 login 我自己按
```

或自己手動裝：

```bash
git clone https://github.com/yanchen184/ccs-claude-code-switch.git ~/.claude/skills/ccs-switch
brew install fzf        # macOS；Linux 用 apt/dnf install fzf
bash ~/.claude/skills/ccs-switch/scripts/install.sh
```

install.sh 會偵測你裝了 claude / codex 哪個，只裝對應模組，並印出「接下來只做你需要的設定」。
然後在終端輸入 `ccs` 就有選單。

> ⚠️ 安裝後仍需你**自己跑一次 login**（開瀏覽器、輸第二個帳號的帳密／2FA）——
> 那一步沒人能代勞，但其餘設定都自動。

---

## 核心精神：對話繼承（provider-agnostic）

不管是 Claude 還是 Codex，原理只有一句話：

> **用環境變數隔離身份，用「複製一場對話檔 + 在另一身份 resume」接續歷史。**

每一場對話其實是一個 `.jsonl` 檔躺在硬碟上。所以「換帳號繼續同一場對話」不需要任何雲端魔法——
把那個檔複製到另一個帳號的目錄，再用那個帳號 `resume` 它就好。額度算第二個帳號的，脈絡卻完全不斷。

| | Claude Code | Codex |
|---|---|---|
| 身份隔離 | `CLAUDE_CONFIG_DIR` 環境變數 | `CODEX_HOME` 環境變數 |
| 對話檔位置 | `<config>/projects/<cwd>/<id>.jsonl` | `<home>/sessions/YYYY/MM/DD/rollout-*.jsonl` |
| 接續指令 | `claude --resume <id>` | `codex resume <uuid>` |
| 接力腳本 | `ccs-resume2` | `ccs-codex-resume` |

---

## 用法

| 你要做的事 | 怎麼做 |
|---|---|
| 一般工作 | `ccs` → 選主帳號（自動走 `ccs-watch`，rate limit 時會提示切換） |
| 撞 limit、自動提示 | Claude Code 因 rate limit 結束 → 自動問「切帳號？(Y/n)」→ 按 Y 直接接力 |
| 撞 limit、手動接力 | `ccs` → `接力` → 選方向 → 挑對話 |
| Codex 斷了用 Claude 接 | `ccs` → `跨工具接力` → 選方向 → 挑 Codex 對話 → Claude 自動讀取接續 |

---

## ⚠️ 安全邊界

兩帳號**同時跑**時，這些檔會被並發寫入弄壞，必須各自獨立：
Claude 的 `.claude.json` / `projects/` / `sessions/`；Codex 各自的 `sessions/`。

這也是為什麼接續用「**按需複製單一對話檔**」，而不是把整個資料夾 symlink 接通——
後者雙開會 corrupt（Anthropic issue #18998 / #5024）。

完整設計、踩坑與 Keychain 雜湊雷詳見 [`SKILL.md`](./SKILL.md)。

---

## 授權

MIT。本 repo 不含任何個資或密鑰，全部用 `$HOME` 相對路徑；
token 永遠留在你自己的 Keychain / `auth.json`，不會被腳本讀出或搬移（只搬「對話檔」）。
