# NotebookLM Verification Workflow

This workflow utilizes the NotebookLM MCP integration to rigorously audit one or multiple documents for logical imprecisions, contradictions, or technically infeasible concepts.

## 1. Initialization

1. Create a dedicated Notebook in NotebookLM (e.g., `AMPS_Verification`).
2. Upload the target document(s) (e.g., PDF, Markdown) to the notebook as a source using `source_add`.

## 2. The Verification Loop

1. **Interrogate:** Issue a prompt via `chat_ask` asking NotebookLM to act as an adversarial academic reviewer.
   *Prompt:* "Analyze the provided document(s) thoroughly. Identify any imprecisions, contradictions, missing contextual links, or technically infeasible concepts. Be highly critical. If the document is flawless, reply with exactly 'No issues found'."
2. **Evaluate & Adapt:** Review NotebookLM's critique. If valid issues are identified, trace them back to the source files (e.g., `.tex` or `.md`), implement the necessary corrections, and recompile the document if needed.
3. **Source Refresh:** Remove the outdated source document from the notebook using `source_delete` and upload the newly compiled/fixed version using `source_add`.
4. **Iterate:** Repeat Step 1 until NotebookLM replies with "No issues found".

## 3. The Final Confirmation

Once NotebookLM declares the document free of issues, run one final, differently phrased interrogation (e.g., "Are you absolutely certain there are no remaining contradictions or structural flaws? Give it one last aggressive pass.") to guarantee stability.
