# Assistant implementation and model research

Reviewed 3 November 2026. No API key is bundled, committed, or obtained from a
third party. A provider requires the owner's/user's connection and applicable
hosting, billing and data-processing terms.

| Candidate | Evidence | Decision for this test build |
| --- | --- | --- |
| [MenstLLaMA / Menstrual-LLaMA-8B](https://huggingface.co/proadhikary/Menstrual-LLaMA-8B) | [Published development/evaluation study](https://pmc.ncbi.nlm.nih.gov/articles/PMC12286563/) describes fine-tuning Meta-LLaMA-3-8B-Instruct for menstrual-health education. The authors discuss hallucinations, representation limits and the need for oversight. | Relevant research candidate for a separately hosted OpenAI-compatible server. No claim of clinical validation or broad pregnancy/wellness reliability; not bundled or silently downloaded to a phone. |
| [MedGemma](https://huggingface.co/google/medgemma-4b-it) | Google's medical-text/image model card requires validation and adaptation and excludes direct clinical decision use. It is not specifically a menstrual-health model. | Not automatically substituted for a validated consumer health assistant. A compatible host can be configured after evaluation. |
| [Gemini](https://ai.google.dev/gemini-api/docs/models) | General-purpose hosted models, not a women's-health-specific training claim. | User-supplied key and configurable model. Default model ID follows the current official catalogue. |

The app also offers **offline article retrieval**, clearly labelled as excerpts
from the bundled sourced library, not generative AI. It requires no credential,
network, or health-data upload. A failed remote request is an error, not a fake
offline-generated answer.

## Connections and privacy

The Assistant connection page stores keys/configuration in platform secure
storage. Tracking backup JSON excludes them. Removing the connection deletes
the stored key. Changing provider clears the key field to prevent accidentally
sending one provider's key to another server.

Gemini uses the documented [Interactions API](https://ai.google.dev/gemini-api/docs/text-generation),
`Api-Revision: 2026-05-20`, and `store: false`. Response parsing follows the
[current steps schema](https://ai.google.dev/gemini-api/docs/interactions-breaking-changes-may-2026).
This API flag does not override Google's separate processing/retention terms.
The hosted-model option uses HTTPS OpenAI-compatible chat completions. Neither
connection follows redirects with credentials or shows provider response bodies
in errors. Both use bounded requests and explicit failure states.

The connection test sends only a generic greeting after a tap. Personal-record
sharing starts off for every chat visit; existing sensitive-field exclusions
remain. Relevant sourced article excerpts are provided as reference context;
this is retrieval grounding, not new model training or a reliability guarantee.

## Verification boundary

HTTP contract tests cover current Gemini response shape, generic hosted-model
requests, credentials, source retrieval, secure persistence/removal and redacted
errors. An actual remote generation requires a valid user key/server and is not
established by mocked HTTP tests. No diagnosis, treatment, contraceptive safe-day
or clinically validated probability is provided by the integration.
