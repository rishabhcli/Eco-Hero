Eco Hero – iOS App (Build Guide for Beginners)

This folder contains the Eco Hero iOS app.
This guide walks you through, step by step, how to get the app running even if you are new to Xcode or iOS development.

---

1. What You Need First

A Mac that can run a recent version of macOS.
Xcode (Apple’s iOS development tool)
Install it from the Mac App Store (search for “Xcode”).
After installing, open Xcode once so it can finish setting up components.
An iPhone or iPad (optional) if you want to run the app on a real device.
You can always start with the built‑in iOS Simulator.

> You do not need to install anything like CocoaPods, Carthage, or Homebrew. Everything needed is inside the Xcode project.

---

2. Get the Project onto Your Mac

If you already have this Eco-Hero folder on your Mac (for example, you downloaded a ZIP or someone sent it to you), you can skip to Step 3.

Option A – Download as ZIP (no Git required)

Go to the project page in your browser (GitHub or wherever it is hosted).
Click “Code” → “Download ZIP”.
When the download finishes, double‑click the ZIP file to unzip it.
Move the resulting Eco-Hero folder to a convenient place (e.g. Documents or Desktop).

Option B – Clone with Git (optional, for slightly more advanced users)

If you have Git installed and prefer using the Terminal:

git clone https://github.com/rishabhbansal/Eco-Hero.git
cd Eco-Hero

---

3. Open the Project in Xcode

Inside the Eco-Hero folder you should see:

Eco Hero.xcodeproj – the Xcode project file
Eco Hero/ – the app source code folder

To open the project:

In Finder, open the Eco-Hero folder.
Double‑click Eco Hero.xcodeproj.
Xcode will launch and load the project.
If Xcode asks to “Activate developer tools” or similar, allow it.

You can also open from Terminal:

cd /path/to/Eco-Hero
open "Eco Hero.xcodeproj"

---

4. Choose Where to Run the App

In Xcode, at the top of the window, you’ll see:

For a deeper explanation of app features, architecture, and roadmap, refer to the main project README (if present) at the repository root.
