
# TODO: Import your chosen LLM SDK
import json
import os

from dotenv import load_dotenv
from openai import AzureOpenAI

# import anthropic
# import boto3
# from google.cloud import aiplatform


async def analyze_journal_entry(entry_id: str, entry_text: str) -> dict:
    """
    Analyze a journal entry using Azure OpenAI.

    Args:
        entry_id: The ID of the journal entry being analyzed
        entry_text: The combined text of the journal entry (work + struggle + intention)

    Returns:
        dict with keys:
            - entry_id: ID of the analyzed entry
            - sentiment: "positive" | "negative" | "neutral"
            - summary: 2 sentence summary of the entry
            - topics: list of 2-4 key topics mentioned
            - created_at: timestamp when the analysis was created
    """
    load_dotenv()

    api_key = os.getenv("AZURE_OPENAI_API_KEY")
    endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
    deployment = os.getenv("AZURE_OPENAI_DEPLOYMENT")

    if not endpoint:
        raise ValueError("AZURE_OPENAI_ENDPOINT environment variable is not set")
    if not deployment:
        raise ValueError("AZURE_OPENAI_DEPLOYMENT environment variable is not set")

    client = AzureOpenAI(
        api_version="2024-12-01-preview",
        azure_endpoint=endpoint,
        api_key=api_key,
    )

    system_prompt = """You are a journal entry analyzer. Analyze the given journal entry and return a JSON object with:
- "sentiment": one of "positive", "negative", or "neutral"
- "summary": a 2-sentence summary of the entry
- "topics": an array of 2-4 key topics mentioned

Return ONLY valid JSON, no additional text."""

    response = client.chat.completions.create(
        messages=[
            {
                "role": "system",
                "content": system_prompt,
            },
            {
                "role": "user",
                "content": entry_text,
            }
        ],
        max_completion_tokens=1024,
        model=deployment,
        response_format={"type": "json_object"}
    )

    content = response.choices[0].message.content
    if not content:
        raise ValueError("No content in response from Azure OpenAI")

    analysis = json.loads(content)

    return {
        "entry_id": entry_id,
        "sentiment": analysis.get("sentiment", "neutral"),
        "summary": analysis.get("summary", ""),
        "topics": analysis.get("topics", []),
    }

    """
    Analyze a journal entry using your chosen LLM API.

    Args:
        entry_id: The ID of the journal entry being analyzed
        entry_text: The combined text of the journal entry (work + struggle + intention)

    Returns:
        dict with keys:
            - entry_id: ID of the analyzed entry
            - sentiment: "positive" | "negative" | "neutral"
            - summary: 2 sentence summary of the entry
            - topics: list of 2-4 key topics mentioned
            - created_at: timestamp when the analysis was created

    TODO: Implement this function using your chosen LLM provider.
    See the Learn to Cloud curriculum for guidance on:
    - Setting up your LLM API client
    - Crafting effective prompts
    - Handling structured JSON output
    """
    raise NotImplementedError(
        "Implement this function using your chosen LLM API. "
        "See the Learn to Cloud curriculum for guidance."
    )
