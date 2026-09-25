# aichat on OpenRouter

- **`aichat` is configured for OpenRouter's free tier, and its key is an env var.**
  `dotfiles/aichat/config.yaml` is public because the client it declares carries no
  `api_key`: aichat falls back to `<client name>_API_KEY`, so the credential is
  `OPENROUTER_API_KEY` in `bash_secrets` — the split that the routing rule in the top-level `README.md` asks for.
  An openai-compatible client treats `api_key` as *optional*, so a host that never filled
  that slot gets no missing-key diagnostic: aichat simply sends no `Authorization` header
  and OpenRouter answers 401 `No cookie auth credentials found`. That is the message.
  A client's own `models:` list **replaces** the one aichat ships for that provider, and
  aichat's built-in openrouter list is entirely paid models, so enumerating only `:free`
  ids is what keeps `.model` — and anything picked from it — free. Unlisted models still
  work when named in full (`aichat -m openrouter:vendor/model:free`), just without context
  or pricing metadata. The roster churns every few weeks; regenerate it from
  `https://openrouter.ai/api/v1/models`, keeping ids that end in `:free`.
- **On the tablet, aichat comes from `pkg install aichat`**, not from `65-aichat.sh`.
  Termux packages it (0.30.0, level with upstream), which makes it the `/usr` bucket there
  by the same rule the table uses — and `install-software` does not run on Termux anyway.
  The config is the same file: `install-dotfiles` links it on every host.
- **Being listed as free is not the same as being usable**, which is why the 16 listed are
  not the 21 the API returns. `thinkingmachines/inkling{,-small}:free` answer 403 `only
  available on agentic harnesses`; `nvidia/nemotron-3.5-content-safety:free` is a
  classifier that replies `User Safety: safe` to anything; the `ling-3.0-flash-{sante,fin}`
  pair is domain-tuned. Free endpoints also share an upstream pool, so a 429 `temporarily
  rate-limited upstream` is routine and means pick another model — Google, Qwen, Z-AI and
  Poolside refused every attempt across an afternoon, while the two NEX and the NVIDIA
  models never did. Of the free ones `nex-agi/nex-n2.5-mini:free` is the pick — three
  command-recall prompts answered correctly in 0.6–4.5s, with no fencing to strip — and
  `nvidia/nemotron-3-super-120b-a12b:free` is behind it. Avoid `openrouter/free`, the
  auto-router: it is reliable but routes at random, and one of three test prompts came back
  `User Safety: safe` from the classifier above.
- **A `:free` id is one endpoint, so a 429 on it has no workaround but waiting.** Dropping
  the suffix is the escape: `qwen/qwen3.8-27b:free` resolves to ModelRun alone, while
  `qwen/qwen3.8-27b` fans out over seventeen providers with failover, at $0.10/M in and
  $1.80/M out. Check with `https://openrouter.ai/api/v1/models/<id>/endpoints`. Do not read
  the 429's own advice too literally: "route to another provider" cannot apply where there
  is only one, and "add your own key" means BYOK — a paid account with a provider
  OpenRouter integrates, billed there, plus 5% to OpenRouter (waived under $25k/month). It
  does not raise a free variant's ceiling, because that ceiling is the free provider's
  shared pool.
- **The `patch` block exists to silence `<think>`.** Nearly every free model is a reasoning
  model, and aichat wraps returned reasoning in `<think>` tags, which on some models ran to
  forty lines before the one-line answer. `reasoning: {exclude: true}` in the request body
  drops it at the source. `aichat --code` is the other half of that: it strips think tags
  and extracts just the code block.
- **The default is paid on purpose.** `deepseek/deepseek-v4-flash` is $0.0886/M in and
  $0.1772/M out, so a syntax question costs a fraction of a cent, and paid ids carry no
  platform request cap at all — `:free` ids are capped at 20 requests/minute and 50/day,
  rising to 1000/day once the account has ever purchased 10 credits, which this one now
  has. `curl -H "Authorization: Bearer $OPENROUTER_API_KEY`
  `https://openrouter.ai/api/v1/key` reports both the counter and `is_free_tier`. No
  DeepSeek model has a free variant; every one of them is paid. It does fence its answers
  in ```bash, which the free NEX models do not — `aichat --code` strips that.
- **It is not the cheapest that would do**, which was a deliberate choice rather than an
  oversight: 27 paid text models undercut it, and on the same three recall prompts the paid
  `nex-agi/nex-n2.5-mini` ($0.063/M blended against $0.133) answered all three correctly,
  two to five times faster, without fencing. The gap is under a cent a month at any
  plausible usage, so it was settled on headroom for harder questions, not on price. Two
  results worth keeping if this is ever revisited: `mistralai/mistral-nemo`, the cheapest
  of all, invented a `jq` merge that does not work, and `qwen/qwen3.7-flash` is correct but
  takes 20–30 seconds a question.
