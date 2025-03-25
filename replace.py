import os


def update_markdown_links(directory="./source/_posts"):
    for filename in os.listdir(directory):
        if filename.endswith(".md"):
            filepath = os.path.join(directory, filename)
            with open(filepath, "r", encoding="utf-8") as file:
                content = file.read()

            updated_content = content.replace("](", "](./")

            with open(filepath, "w", encoding="utf-8") as file:
                file.write(updated_content)
            print(f"Updated: {filename}")


if __name__ == "__main__":
    update_markdown_links()
