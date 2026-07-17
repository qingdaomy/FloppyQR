💾 FloppyQR
One QR to boot, one PNG to load. No servers, no stores, just two pictures.

https://img.shields.io/badge/License-MIT-yellow.svg

https://img.shields.io/badge/PRs-welcome-brightgreen.svg




📦 项目地址：

https://github.com/qingdaomy/FloppyQR





🎯 What is FloppyQR?

FloppyQR turns your entire web application (HTML/CSS/JS) into a PNG image (called a Floppy) and unlocks it with a QR code (called QRboot).


Scan the QR, pick the picture, and your app runs instantly — completely offline, forever.


Perfect for AI-generated demos, mini‑games, interactive tools, and educational content.




✨ Features

📦 Single or multiple files – Pack your whole project (HTML + CSS + JS + assets) into one PNG.

🗜️ Automatic compression – Uses zlib + browser DecompressionStream for efficient size reduction.

🖼️ Custom logo – Embed a visible logo in the Floppy image for easy identification.

🔗 Pairing mode – Optional App ID matching (strong/weak binding) between QRboot and Floppy.

🌍 Multi-language ready – Built‑in support for multiple UI languages (English, Chinese, etc.).

📱 Mobile‑first UI – Touch‑friendly, responsive, works great on phones.

⚡ Instant launch – No installation, no server, no app store – just scan and use.

🔄 Cross‑platform – Works in any modern browser (Chrome, Edge, Safari, Firefox).

🖥️ CLI tool – One‑command generation with rich parameter support.

🤖 AI Skill ready – Native integration with OpenCode, OpenClaw, and other AI coding agents.



🚀 Quick Start
1. Clone the repository
bash
git clone https://github.com/qingdaomy/FloppyQR.git
cd FloppyQR
2. Install dependencies
bash
pip install Pillow qrcode
3. Prepare your web app
Place your index.html (and any other files like style.css, script.js) inside a folder, e.g., myapp/.

4. Generate the Floppy and QRboot
bash
python generator/generate.py --input myapp/ --name "My App" --logo mylogo.png
This will produce:

Floppy_MyApp.png – the data disk containing your app

QRboot_MyApp.png – the QR code that launches the loader

5. Share & Run
Print or display the QR code (QRboot_MyApp.png).

Users scan it with their phone camera (or any QR scanner).

The QRboot loader opens in their browser.

They pick the Floppy_MyApp.png from their device.

Your web app runs instantly!

💡 Tip: Bookmark the loader page after first use for even faster access.



🖥️ CLI Tool

FloppyQR provides a powerful command-line interface for easy integration into your build workflow.

Basic Usage

<img width="577" height="233" alt="image" src="https://github.com/user-attachments/assets/072e6c5f-df68-46f1-82cf-22e4d576f1dc" />


<img width="738" height="461" alt="image" src="https://github.com/user-attachments/assets/218dbbc7-d151-443f-9e7a-21fa29e82112" />

Output Example

✅ Floppy generated: Floppy_MyApp.png (2.3 MB, compression: 42%)

✅ QRboot generated: QRboot_MyApp.png
Internal Workflow
The CLI executes the following steps:

Read HTML (file or directory via InlineBundler)

Read icon (ImageProcessor)

Build payload (DataPayloadBuilder + CompressionService)

Generate PNG (PNGEncoder.createDataDisk)

Generate QR code (QRCodeGenerator.pngData)

Write files: QRboot_<name>.png + Floppy_<name>.png

Print compression statistics



🤖 AI Skill Integration

FloppyQR provides an AI Skill that allows OpenCode, OpenClaw, and other AI coding agents to generate Floppy/QRboot directly from natural language — no manual CLI commands needed.

What is OpenCode?
OpenCode is an open-source AI coding agent available as a terminal interface, desktop app, and IDE extension. It reads your repository, runs commands, edits files, and works with any LLM you choose. With support for 75+ LLM providers including Anthropic, OpenAI, Google Gemini, and DeepSeek, OpenCode provides a flexible, model-neutral platform for AI-assisted development.

How It Works


<img width="748" height="317" alt="image" src="https://github.com/user-attachments/assets/b30b1bea-41ea-4d40-bd2f-0115a8f6b8fb" />

Usage Example (Natural Language)
In your AI conversation, simply say:

"Use FloppyQR to package my todo app from ~/projects/todo, name it 'TodoApp', and enable strict pairing."

The AI will automatically execute:

bash
FloppyQR generate -i ~/projects/todo -n TodoApp -s
And return the generated files to you.


Skill Features

✅ Single-file / multi-project packaging

✅ Custom app name and icon

✅ Strict pairing mode

✅ Compression rate feedback



🧩 How It Works

QRboot is a tiny HTML page (≈1.4KB) that contains the loader logic. It is encoded as a data:text/html URI inside the QR code.

Floppy is a standard PNG image (1024×1024) with a hidden custom chunk (zDAT) that stores your compressed app bundle.

The loader reads the PNG, extracts the zDAT chunk, decompresses it, and replaces the page with your app – all client‑side, no network required.

For detailed technical specification, see specs/floppyqr-spec-v1.md.



🌍 Multi‑language Support

FloppyQR is designed with internationalization in mind. Currently supported languages:

English (default)

简体中文 (Chinese)

You can easily add your own language by modifying the text strings inside loader/qrboot.dev.html or the generator script.



📦 Roadmap

Local cache (Skill) – Save loaded apps in localStorage so you can reopen them from bookmarks without re‑selecting the Floppy.

GUI generator – A simple web‑based drag‑and‑drop interface for non‑Python users.

Encryption – AES‑GCM encryption for sensitive code.

Incremental updates – Patch‑style updates to reduce data size.

Floppy URL protocol – floppy:// custom scheme for seamless integration.



🙏 Acknowledgments

FloppyQR was built with the support of an incredible open-source ecosystem.

Special thanks to:

OpenCode – For providing a powerful, model-neutral AI coding agent that makes AI-assisted development accessible to everyone. OpenCode's support for 75+ LLM providers and its flexible Skill system enabled FloppyQR to become truly AI-native.

DeepSeek V4 – For pushing the boundaries of open-source AI with world-class reasoning capabilities. DeepSeek-V4's Mixture-of-Experts architecture, with models like V4-Pro (1.6T parameters, 49B activated) and V4-Flash (284B parameters, 13B activated), delivers state-of-the-art performance in Math/STEM/Coding that rivals top closed-source models. With a 1M token context length, it empowers developers to build sophisticated applications with unprecedented efficiency.

The entire open-source AI community – for making tools like this possible.



📄 License

This project is licensed under the MIT License – see the LICENSE file for details.



📞 Community

Issues: GitHub Issues

Discussions: GitHub Discussions

Made with 💾 by Qingdaomy – because sharing web apps should be as easy as sharing a photo.
