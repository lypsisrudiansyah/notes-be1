#!/bin/bash

echo "skillbadge Build a Multi-Modal GenAI Application Challenge Lab"


# solution.py below
import io
from google import genai
from google.genai import types
from PIL import Image

# Initialize GenAI Client
client = genai.Client()

# -------------------------------------------------------------
# TASK 1: Generate Bouquet Image using gemini-2.5-flash-image
# -------------------------------------------------------------
image_prompt = "Create an image containing a bouquet of 2 sunflowers and 3 roses."
image_filename = "bouquet.png"

print("Generating bouquet image using gemini-2.5-flash-image...")

# Call generate_content requesting image output modality
response = client.models.generate_content(
    model="gemini-2.5-flash-image",
    contents=image_prompt,
    config=types.GenerateContentConfig(
        response_modalities=["IMAGE"]
    )
)

# Extract and save the generated image bytes
image_saved = False
for part in response.candidates[0].content.parts:
    if part.inline_data:
        image = Image.open(io.BytesIO(part.inline_data.data))
        image.save(image_filename)
        image_saved = True
        break

if not image_saved:
    # Fallback to direct bytes if structure differs
    for part in response.candidates[0].content.parts:
        if hasattr(part, "as_image"):
            part.as_image().save(image_filename)
            image_saved = True
            break

print(f"Task 1 complete: Image saved as '{image_filename}'.")

# -------------------------------------------------------------
# TASK 2: analyze_bouquet_image(image_path) using gemini-2.5-flash
# -------------------------------------------------------------
def analyze_bouquet_image(image_path: str, output_txt: str = "birthday_wishes.txt"):
    print("Analyzing image and streaming birthday wishes using gemini-2.5-flash...")
    img = Image.open(image_path)
    prompt = "Generate birthday wishes inspired by the bouquet image."

    response_stream = client.models.generate_content_stream(
        model="gemini-2.5-flash",
        contents=[img, prompt]
    )

    streamed_output = ""
    for chunk in response_stream:
        if chunk.text:
            print(chunk.text, end="")
            streamed_output += chunk.text

    print("\n")
    with open(output_txt, "w", encoding="utf-8") as f:
        f.write(streamed_output)

    print(f"Task 2 complete: Birthday wishes written to '{output_txt}'.")

# Run Task 2
analyze_bouquet_image(image_filename)