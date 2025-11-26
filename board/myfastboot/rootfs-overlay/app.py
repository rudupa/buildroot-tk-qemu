#!/usr/bin/env python3

import tkinter as tk

root = tk.Tk()
root.title("Fastboot Demo")

label = tk.Label(root, text="Hello from Python GUI!", font=("Arial", 16))
label.pack(padx=40, pady=40)

button = tk.Button(root, text="Exit", command=root.destroy)
button.pack(pady=20)

root.mainloop()
