#!/usr/bin/env python3
import tkinter as tk
from tkinter import ttk
from datetime import datetime


class FastBootApp(tk.Tk):
    def __init__(self) -> None:
        super().__init__()
        self.title("FastBoot Demo")
        self.geometry("640x480")
        self.configure(bg="#202020")

        header = ttk.Label(
            self,
            text="Buildroot Tkinter",
            font=("Helvetica", 24, "bold"),
            foreground="#ffffff",
            background="#202020",
        )
        header.pack(pady=(60, 10))

        self.clock = ttk.Label(
            self,
            text="",
            font=("Helvetica", 18),
            foreground="#26c281",
            background="#202020",
        )
        self.clock.pack(pady=10)

        quit_btn = ttk.Button(self, text="Exit", command=self.destroy)
        quit_btn.pack(pady=40)

        self.after(0, self._update_clock)

    def _update_clock(self) -> None:
        now = datetime.now().strftime("%H:%M:%S")
        self.clock.configure(text=f"Current time: {now}")
        self.after(500, self._update_clock)


def main() -> None:
    app = FastBootApp()
    def log_ready() -> None:
        try:
            with open("/proc/uptime", "r", encoding="ascii") as uptime_file:
                uptime = float(uptime_file.read().split()[0])
            print(f"[BOOT] Tk ready at {uptime:6.3f}s", flush=True)
        except (OSError, ValueError) as exc:
            print(f"[BOOT] Tk ready (uptime unavailable): {exc}", flush=True)

    app.after_idle(log_ready)
    app.mainloop()


if __name__ == "__main__":
    main()