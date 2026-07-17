from setuptools import setup, find_packages

setup(
    name="floppyqr",
    version="1.0.0",
    description="Offline Web App Distribution Generator",
    author="Qingdaomy",
    url="https://github.com/qingdaomy/FloppyQR",
    py_modules=["generate"],
    entry_points={
        'console_scripts': [
            'floppyqr=floppyqr:main',
        ],
    },
    install_requires=[
        'Pillow>=10.0.0',
        'qrcode>=7.4.0',
    ],
    python_requires='>=3.8',
)
