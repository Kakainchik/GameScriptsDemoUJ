from llama_cpp import Llama
import os
import glob
import yaml
import json

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(SCRIPT_DIR, "config.yaml")
SCHEMA_PATH = os.path.join(SCRIPT_DIR, "chat_completion_schema.json")
PROMPT_PATH = os.path.join(SCRIPT_DIR, "system_prompt.txt")
MODELS_DIR = os.path.join(SCRIPT_DIR, "models")

# Configuration helpers
def load_config(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)

def load_schema(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def format_menu(menu: dict) -> str:
    lines = []
    for category, items in menu.items():
        nice_category = category.replace("_", " ").title()
        lines.append(f"\n### {nice_category}")
        for item in items:
            lines.append(
                f"  - {item['name']} - {item['description']} "
                f"(${item['price']:.2f})"
            )
    return "\n".join(lines)

def format_hours(hours: dict) -> str:
    # Convert the hours into a readable string
    lines = []
    for day, time_range in hours.items():
        lines.append(f"  - {day.capitalize()}: {time_range}")
    return "\n".join(lines)

def build_system_prompt(config: dict) -> str:
    restaurant = config["restaurant"]
    hours_text = format_hours(restaurant["opening_hours"])
    menu_text = format_menu(restaurant["menu"])

    with open(PROMPT_PATH, "r", encoding="utf-8") as f:
        template = f.read()

    return template.format(
        restaurant_name=restaurant["name"],
        restaurant_description=restaurant["description"],
        opening_hours=hours_text,
        menu=menu_text,
    )

# List available .gguf models
def select_model() -> str:
    gguf_files: list[str] = []
    if os.path.isdir(MODELS_DIR):
        gguf_files = sorted(
            glob.glob(os.path.join(MODELS_DIR, "**", "*.gguf"), recursive=True)
        )

    print("=" * 10)
    print("MODEL SELECTION")
    print("=" * 10)

    if gguf_files:
        print(f"\nFound {len(gguf_files)} GGUF model(s) in '{MODELS_DIR}':\n")
        for idx, path in enumerate(gguf_files, start=1):
            rel = os.path.relpath(path, MODELS_DIR)
            size_mb = os.path.getsize(path) / (1024 * 1024)
            print(f"  [{idx}] {rel}  ({size_mb:,.1f} MB)")
    else:
        print(f"\nNo .gguf models found in '{MODELS_DIR}'.")

    print(f"\n[0] Enter a custom path manually\n")

    while True:
        choice = input("Select a model: ").strip()
        if not choice.isdigit():
            print("Please enter a valid number.")
            continue
        choice_int = int(choice)
        if choice_int == 0:
            custom_path = input("Enter the full path to the .gguf model: ").strip()
            if os.path.isfile(custom_path):
                return custom_path
            else:
                print(f"File not found: {custom_path}")
                continue
        if 1 <= choice_int <= len(gguf_files):
            return gguf_files[choice_int - 1]
        print(f"Please enter a number between 0 and {len(gguf_files)}.")

# Trim if messages exceed context window
def trim_messages(messages: list[dict], n_ctx: int, llm: Llama) -> list[dict]:
    threshold = int(n_ctx * 0.75)

    def count_tokens(msgs: list[dict]) -> int:
        text = "".join(m["content"] for m in msgs)
        return len(llm.tokenize(text.encode("utf-8"), add_bos=False))

    while len(messages) > 1 and count_tokens(messages) > threshold:
        messages.pop(1)

    return messages

# Main chat loop
def main() -> None:
    config = load_config(CONFIG_PATH)
    schema = load_schema(SCHEMA_PATH)
    print(f"\nLoaded config : {CONFIG_PATH}")
    print(f"Loaded prompt   : {PROMPT_PATH}")
    print(f"Loaded schema   : {SCHEMA_PATH}")
    print(f"Schema title    : {schema.get('title', 'N/A')}\n")

    model_path = select_model()
    print(f"\nLoading model: {model_path} ...")

    N_CTX = 2048  # Context window size
    llm = Llama(
        model_path=model_path,
        n_gpu_layers=-1,
        n_ctx=N_CTX,
        verbose=False,
    )
    print("Model loaded successfully!\n")

    system_prompt = build_system_prompt(config)
    messages: list[dict] = [
        {"role": "system", "content": system_prompt}
    ]

    restaurant_name = config["restaurant"]["name"]
    print("=" * 10)
    print(f"  Welcome to {restaurant_name}!")
    print("  Type your message and press Enter.")
    print('  Type "Exit" to quit.')
    print("=" * 10)

    while True:
        try:
            user_input = input("\nYou: ").strip()
        except (EOFError, KeyboardInterrupt) as ex:
            print(ex)
            break

        if user_input == "Exit":
            print("Goodbye! Thank you for visiting.")
            break

        if not user_input:
            continue

        messages.append({"role": "user", "content": user_input})

        messages = trim_messages(messages, N_CTX, llm)

        response = llm.create_chat_completion(
            messages=messages,
            max_tokens=schema["properties"]["max_tokens"].get("default", 256),
            temperature=schema["properties"]["temperature"].get("default", 0.7),
            top_p=schema["properties"]["top_p"].get("default", 0.95),
            top_k=schema["properties"]["top_k"].get("default", 40),
            repeat_penalty=schema["properties"]["repeat_penalty"].get("default", 1.1),
        )

        assistant_message = response["choices"][0]["message"]["content"]
        print(f"\nAssistant: {assistant_message}")

        messages.append({"role": "assistant", "content": assistant_message})

if __name__ == "__main__":
    main()