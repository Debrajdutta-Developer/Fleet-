# FleetOS ERP - Material 3 Design System Specification

This document defines the complete enterprise-grade **Material 3 Design System** for **FleetOS ERP**. It outlines visual guidelines, component specifications, token systems, and accessibility guidelines optimized for a high-performance, responsive logistics SaaS platform.

---

## 🎨 1. Color Token System (Light & Dark Schemes)

FleetOS ERP uses a semantic color system based on HSL (Hue, Saturation, Lightness) color spaces to ensure consistency, high visual contrast, and easy programmatic adjustment.

### 1.1 Brand & Semantic Colors

| Token | Light Mode Value (HEX) | Dark Mode Value (HEX) | Semantic Application |
| :--- | :--- | :--- | :--- |
| **Primary (Fleet Navy)** | `#1E3A8A` (HSL 224, 64%, 33%) | `#3B82F6` (HSL 217, 91%, 60%) | Brand presence, primary actions, highlights. |
| **Secondary (Telemetry Teal)** | `#0D9488` (HSL 174, 84%, 31%) | `#2DD4BF` (HSL 170, 78%, 50%) | Active states, telemetry maps, speed metrics. |
| **Warning (Alert Yellow)** | `#D97706` (HSL 32, 95%, 44%) | `#F59E0B` (HSL 38, 92%, 50%) | Non-blocking issues, low fuel thresholds. |
| **Error (Critical Red)** | `#DC2626` (HSL 0, 72%, 50%) | `#EF4444` (HSL 0, 84%, 60%) | Engine faults, severe delays, payment errors. |
| **Success (Operational Green)** | `#16A34A` (HSL 142, 76%, 36%) | `#4ADE80` (HSL 142, 70%, 58%) | Completed trips, green diagnostics, online. |

### 1.2 Surface & Neutral Tokens

| Token | Light Mode Value (HEX) | Dark Mode Value (HEX) | Design Application |
| :--- | :--- | :--- | :--- |
| **Background** | `#F8FAFC` (Slate 50) | `#0F172A` (Slate 900) | Main scaffold backgrounds. |
| **Surface (Container)** | `#FFFFFF` | `#1E293B` (Slate 800) | Card grids, sidebars, dashboard blocks. |
| **Surface Variant** | `#F1F5F9` (Slate 100) | `#334155` (Slate 700) | Table headers, inactive input backgrounds. |
| **Border / Divider** | `#E2E8F0` (Slate 200) | `#334155` (Slate 700) | Component borders, grid outlines. |
| **Text Primary** | `#0F172A` (Slate 900) | `#F8FAFC` (Slate 50) | High-contrast headers and body titles. |
| **Text Secondary** | `#475569` (Slate 600) | `#94A3B8` (Slate 400) | Subtitles, supporting text. |

---

## ✍️ 2. Typography & Hierarchy

FleetOS ERP uses two core Google Fonts:
1.  **Outfit** (Geometric Sans-Serif): Display, Headers, Page Titles.
2.  **Inter** (Highly readable Sans-Serif): Body text, inputs, data grids, telemetry readouts.

### Typography Scale Table

| Role | Font Family | Size (px) | Weight | Line Height | Letter Spacing |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Display Large** | Outfit | `36px` | Bold (700) | `44px` | `-0.5px` |
| **Headline Medium** | Outfit | `24px` | SemiBold (600) | `32px` | `0px` |
| **Title Large** | Outfit | `20px` | SemiBold (600) | `28px` | `0px` |
| **Body Large** | Inter | `16px` | Regular (400) | `24px` | `0.15px` |
| **Body Medium** | Inter | `14px` | Regular (400) | `20px` | `0.1px` |
| **Label Large** | Inter | `14px` | Medium (500) | `20px` | `0.1px` |
| **Caption** | Inter | `12px` | Regular (400) | `16px` | `0.4px` |

---

## 📐 3. Spacing, Corner Radius & Elevation

### 3.1 Spacing Scale (8px Grid System)
All padding, margin, and alignment rules utilize an **8px base grid** (with 4px increments for micro-alignments).

*   **xxs:** `4px` (Inner text elements, checkbox offsets)
*   **xs:** `8px` (Inner component items, labels to inputs)
*   **sm:** `12px` (Card padding for mobile, list item gap)
*   **md:** `16px` (Standard card margins, form layout gaps)
*   **lg:** `24px` (Standard page margins, major content blocks)
*   **xl:** `32px` (Hero padding, section gaps)
*   **xxl:** `48px` (Landing margins)

### 3.2 Corner Radius (Rounded Borders)
FleetOS ERP adopts softer corners from Material 3 to look modern and approachable:
*   **Small (4px):** Checkboxes, badges, tiny tags.
*   **Medium (8px):** Buttons, text fields, small containers.
*   **Large (12px):** Cards, system tables, dialog panels.
*   **Extra Large (16px):** Bottom sheets, main sidebar menus.
*   **Full (999px):** Circular avatars, status pills.

### 3.3 Elevation Levels (Shadows)
*   **Level 0 (Flat):** Used for inputs, tables, and borders in dark mode.
*   **Level 1 (Default Card):** `box-shadow: 0px 2px 4px rgba(15, 23, 42, 0.05);` (Used for page sections).
*   **Level 2 (Hover State):** `box-shadow: 0px 8px 16px rgba(15, 23, 42, 0.08);` (Used for interactive grids).
*   **Level 3 (Modals/Dialogs):** `box-shadow: 0px 16px 32px rgba(15, 23, 42, 0.12);` (Used for overlays).

---

## 💻 4. Responsive Breakpoints & Shell Layouts

FleetOS ERP supports a fluid grid that dynamically transforms navigation paradigms based on screen width.

```
+-----------------------------------------------------------------------+
| Mobile (<600px)      | Tablet (600px-1024px)   | Desktop (>1024px)    |
|                      |                         |                      |
| [Header Title]       | [Sidebar Collapsed]     | [Sidebar Permanent]  |
|                      |   [Icon Only Menu]      |   [Full Text Menu]   |
| [Body Content]       |                         |                      |
|                      | [Body Content Grid]     | [Full Details Grid]  |
| [Bottom Nav Bar]     |                         |                      |
+-----------------------------------------------------------------------+
```

### Breakpoint Matrix

*   **Mobile (<600px):** Single-column layouts. Sidebar is hidden and accessible only via a hamburger menu. Bottom Navigation Bar contains core actions (Home, Vehicles, Trips).
*   **Tablet (600px - 1024px):** Dual-column grids. Sidebar is collapsed to icons-only. Header actions are truncated into an overflow menu.
*   **Desktop (1024px - 1440px):** Multi-column dashboard grids. Sidebar is permanently open with text labels. Main data grids render full tables.
*   **Large Desktop (>1440px):** Expanded layout. Max-width constraints on central content (`max-width: 1440px`) to prevent visual stretching.

---

## 🧩 5. Reusable Component Specifications

### 5.1 Buttons

```
[ Primary (Solid) ]   [ Secondary (Outlined) ]   [ Text Action ]
   Height: 50px            Height: 50px           Height: 40px
   Radius: 8px             Radius: 8px            Radius: 8px
```

*   **Primary Button:** Used for core actions (e.g. `Save`, `Create Trip`). Must use the primary brand background with high-contrast text. Minimum click target size: `48px x 48px`.
*   **Secondary Button:** Outlined border (`1.5px` border width, secondary/primary text). Used for secondary flows (e.g. `Cancel`, `Back`).
*   **Text Button:** Zero background or border. Used for minor actions (e.g. `Forgot Password`, `Read More`).

### 5.2 Forms & Inputs
*   **Validation States:** Fields must visually validate on-blur. Correct inputs show `operational-green` outline indicators; incorrect inputs show `critical-red` highlights with helper text below the field.
*   **Focused State:** Double-width border (`2px`) using the `primary-brand` color. Text must shift into a small floating label.

### 5.3 Data Tables
*   **Header Padding:** `16px` vertical, `24px` horizontal. Color: `Surface Variant` background.
*   **Row Padding:** `12px` vertical, `24px` horizontal.
*   **Responsive Scrolling:** Tables must wrap inside horizontal scroll boxes on mobile, freeze-pinning the primary key (e.g. `licensePlate` or `tripNumber`) to the left of the screen.

### 5.4 Charts & Data Visuals
*   **Telemetry Line Charts:** Grid lines must use `Border` color with `1px` dashed styling. Legend values use `Text Secondary` at `12px`.
*   **Colors:** Use semantic indicators (`operational-green` for healthy performance, `warning-yellow` for minor diagnostic updates, `critical-red` for faults).

---

## ♿ 6. Accessibility & Compliance (WCAG 2.1 AA)

To satisfy international compliance standards, FleetOS ERP targets **WCAG 2.1 Level AA** standards.

1.  **Contrast Ratios:**
    *   Primary text on background must exceed **4.5:1** contrast.
    *   Large text (over `18px` bold) and UI elements (borders, icons) must exceed **3:1** contrast.
2.  **Focus Rings:** Keyboard focus indicators (`outline: 3px solid accent-light;`) must be visible on all interactive buttons, inputs, and links when navigating via keyboard (tab indexing).
3.  **Touch Target Sizes:** Interactive buttons and links must provide at least `48dp x 48dp` touch targets to prevent click errors.
4.  **Color Independence:** Do not rely on colors alone to indicate errors or status. Always supplement status badges with explicit icons or labels (e.g., instead of just a red dot, show a red caution icon alongside the text "Fault").
5.  **Screen Reader Labels:** All icons must include descriptive alternative labels (e.g., `aria-label="Filter active fleet"` on icon buttons).
