"LapLogic"
A retro-themed, fully interactive Formula 1 race simulation and telemetry analysis system built entirely in MATLAB — no toolboxes, no external dependencies."


Overview
LapLogic blends racing strategy with data analysis. Race against an AI opponent on a live oval circuit. As you complete laps, the system captures telemetry — lap times, tire wear, ERS usage, and braking zones — and feeds it into performance dashboards and upgrade mechanics.
Features
Live Simulation: Real-time race animation with lap tracking for both player and AI.
Dynamic Upgrades: Earn upgrade points every 5 laps and apply them instantly during simulation.
Real-Time Analysis: Embedded analysis panel gives insights and AI-driven suggestions.
Live Performance Graphs: Track lap-wise trends for tire degradation, ERS, braking, and speed.
Retro UI Theme: Color-coded panels, dark mode, and vintage-inspired styling.
Embedded UX: All modules — simulation, analysis, upgrades, and performance — run in one integrated screen.

How to Run
Clone the repo:
bashCopyEditgit clone https://github.com/yourusername/f1-telemetry-tycoon.git
Open MATLAB and navigate to the cloned folder.
Run:
matlabCopyEditmaster_screen

✅ No toolboxes required — 100% compatible with base MATLAB.

Tech Highlights
Built from scratch in MATLAB
UI built using uipanel, uicontrol, axes, subplot
Timer-based animation for race loop
AI-style upgrade suggestions based on live telemetry
No external dependencies, GUI runs in a single figure window

Future Improvements
Add DRS/ERS boost controls
Introduce weather or tire compounds
Multiplayer or ghost car mode
Track selection or custom track drawing
