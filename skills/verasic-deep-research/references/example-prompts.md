# Example prompts — domain pack index

Cross-pack index of shipped example prompts. Agents use these for routing calibration;
they are **not** a closed list — unknown prompts fall back to `generic` with inferred traits.

| Example prompt | Pack |
| --- | --- |
| how does the elevator work? | `technical` |
| how are electricity towers built and kept safe? | `technical` |
| how does LED work? | `technical` |
| how can F1 cars be so fast yet safe and driveable? | `technical` |
| which VPS is better for users in Japan? | `technical` |
| best Next.js pattern for a production app in 2026 | `technical` |
| how does GPS know my location? | `technical` |
| how do I prevent AI slop on a marketing site? | `ai-content-design` |
| AI-generated content on YT/TikTok/IG/Threads/X/FB — legal? tools? agents? monetization? | `ai-content-design` |
| how to make AI-written copy feel human without lying to users? | `ai-content-design` |
| is using AI voices for YouTube narration misleading? | `ai-content-design` |
| gluten vs non-gluten for swimmers — which is better? | `health-fitness` |
| sub-40 on 10km in 9 months; PB sub-50 from 12 months ago | `health-fitness` |
| is cold plunge after workout evidence-based? | `health-fitness` |
| minimum sleep for muscle recovery when training 5 days/week | `health-fitness` |
| is Jamdev our competitor? strengths/weaknesses vs us | `market-competitive` |
| is the current tech market saturated? | `market-competitive` |
| deep study competitors and evolve our projects to stay ahead | `market-competitive` |
| who are the main players in AI agent tooling in 2026? | `market-competitive` |
| is World Cup 2026 rigged like people say? | `claims-investigation` |
| do vaccines cause autism — what does evidence show? | `claims-investigation` |
| is cryptocurrency a Ponzi scheme? | `claims-investigation` |
| is publishing AI content to social platforms legal? | `claims-investigation` |
| design system vs component library — when to use which? | `creative-technical` |
| how should we structure landing page sections for conversion? | `creative-technical` |
| tradeoffs: SSR vs static for a marketing site | `creative-technical` |
| best products to sell on TikTok, Tokopedia, Shopee for side income | `ecommerce-id` |
| how to price handmade goods for Indonesian marketplaces | `ecommerce-id` |
| COD vs prepaid — conversion impact in Indonesia | `ecommerce-id` |
| I want to open a warkop in Jabodetabek; I know little about business | `small-business-id` |
| modal and break-even for a small coffee shop in Bandung | `small-business-id` |
| what permits does a UMKM food business need in Indonesia? | `small-business-id` |
| should I franchise or start independent? | `small-business-generic` |
| how to validate a business idea before quitting my job | `small-business-generic` |
| history of football and the World Cup | `historical` |
| why did the Roman Empire fall — main theories | `historical` |
| how did Indonesia gain independence — timeline and sources | `historical` |
| best way to learn DevSecOps and land a job | `career-education` |
| is doctor still a future-proof profession? | `career-education` |
| bootcamp vs self-taught vs degree for frontend in 2026 | `career-education` |
| how to transition from frontend to platform engineering | `career-education` |
| I want to start a faceless YouTube channel | `creator-monetization` |
| can I sell Cursor plugins/extensions to make money? | `creator-monetization` |
| AdSense vs sponsorship vs digital products for a new creator | `creator-monetization` |
| how long until a new channel can monetize realistically? | `creator-monetization` |
| explain quantum computing like I'm 15 | `generic` |
| what should I know before buying an EV in Indonesia? | `generic` |

## Pack files

Each row's pack id maps to `references/domain-packs/<id>.yaml`.

## Parent packs

| Pack | Parent |
| --- | --- |
| `small-business-id` | `small-business-generic` |
| `small-business-generic` | null (fallback) |
| `generic` | null (ultimate fallback) |

## Routing notes

- Unknown prompt → `generic` + inferred traits; one confirm if safety-sensitive.
- `claims-investigation` enables `## claim ledger` in deliver template.
- `health-fitness` applies confidence floor 60 and medical disclaimers.
