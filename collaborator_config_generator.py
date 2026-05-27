#!/usr/bin/env python3

import argparse
import json
import os
import base64
import mimetypes

def get_files(input_path):
    if os.path.isfile(input_path):
        return [input_path]
    elif os.path.isdir(input_path):
        return sorted([os.path.join(input_path, f) for f in os.listdir(input_path) if os.path.isfile(os.path.join(input_path, f))])
    else:
        raise Exception("Niepoprawna ścieżka")

def detect_mime(filepath):
    mime, _ = mimetypes.guess_type(filepath)
    return mime or "application/octet-stream"

def encode_file(filepath):
    with open(filepath, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input-config", required=True)
    parser.add_argument("--input-files", required=True)
    parser.add_argument("--server-path", required=True)
    parser.add_argument("--server-filenames", required=False)
    parser.add_argument("--output-config", default="output-config.json")

    args = parser.parse_args()

    with open(args.input_config) as f:
        config = json.load(f)

    files = get_files(args.input_files)

    custom_http = []

    for idx, file_path in enumerate(files, start=1):
        filename = os.path.basename(file_path)

        if args.server_filenames:
            ext = os.path.splitext(filename)[1]
            server_name = f"{args.server_filenames}{idx}{ext}"
        else:
            server_name = filename

        path = os.path.join(args.server_path.strip("/"), server_name)
        path = "/" + path  # ensure leading slash

        mime = detect_mime(file_path)
        encoded = encode_file(file_path)

        custom_http.append({
            "path": path,
            "contentType": mime,
            "base64Content": encoded
        })

    config["customHttpContent"] = config.get("customHttpContent", []) + custom_http

    with open(args.output_config, "w") as f:
        json.dump(config, f, indent=4)

    print(f"[+] Gotowe: zapisano do {args.output_config}")


if __name__ == "__main__":
    main()
