import os
import re

def clean_svg(file_path):
    print(f"Cleaning {file_path}...")
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Remove XML declaration if it exists
    content = re.sub(r'<\?xml.*?\?>', '', content)

    # 2. Remove sodipodi:namedview
    content = re.sub(r'<sodipodi:namedview.*?>.*?</sodipodi:namedview>', '', content, flags=re.DOTALL)
    content = re.sub(r'<sodipodi:namedview.*?/>', '', content)

    # 3. Remove metadata and RDF if they exist
    content = re.sub(r'<metadata.*?>.*?</metadata>', '', content, flags=re.DOTALL)

    # 4. Remove empty defs
    content = re.sub(r'<defs\s*/>', '', content)
    content = re.sub(r'<defs\s*id=".*?"\s*/>', '', content)

    # 5. Remove namespaces and specific attributes from the <svg> tag
    content = re.sub(r'xmlns:inkscape=".*?"', '', content)
    content = re.sub(r'xmlns:sodipodi=".*?"', '', content)
    content = re.sub(r'sodipodi:docname=".*?"', '', content)
    content = re.sub(r'inkscape:version=".*?"', '', content)

    # 6. Remove inkscape/sodipodi attributes from other tags
    content = re.sub(r'inkscape:groupmode=".*?"', '', content)
    content = re.sub(r'inkscape:label=".*?"', '', content)
    content = re.sub(r'inkscape:connector-curvature=".*?"', '', content)
    content = re.sub(r'sodipodi:role=".*?"', '', content)
    
    # 7. Final cleanup of double spaces in tags
    content = re.sub(r'\s{2,}', ' ', content)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content.strip())
    print("Done.")

if __name__ == "__main__":
    assets_dir = r"c:\Users\shuba\Desktop\Med_buddy\mobile\assets"
    for root, dirs, files in os.walk(assets_dir):
        for file in files:
            if file.endswith(".svg"):
                clean_svg(os.path.join(root, file))
