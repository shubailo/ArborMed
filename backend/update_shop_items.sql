-- 🧹 RESET & REPOPULATE SHOP ITEMS
-- Run this in Supabase SQL Editor to fix the "Empty Shop" and "404 Asset" issues.

-- 1. Clear existing items
DELETE FROM public.user_items;
DELETE FROM public.items;

-- 2. Insert NEW Items (Matching ShopCatalog.dart)
INSERT INTO public.items (id, name, type, slot_type, price, asset_path, description, theme) VALUES
-- 🪑 FURNITURE (Desks)
(200, 'Oak Starter Desk', 'furniture', 'desk', 100, 'assets/images/furniture/desk_0.webp', 'Sturdy and reliable.', 'classic'),
(201, 'Minimalist White', 'furniture', 'desk', 100, 'assets/images/furniture/desk_1.webp', 'Clean lines for a clear mind.', 'modern'),
(202, 'Mahogany Executive', 'furniture', 'desk', 100, 'assets/images/furniture/desk_2.webp', 'Serious business.', 'classic'),
(203, 'Gamer Station', 'furniture', 'desk', 100, 'assets/images/furniture/desk_3.webp', 'RGB increases performance by 10%.', 'gaming'),
(204, 'Modern Glass Desk', 'furniture', 'desk', 150, 'assets/images/furniture/desk_4.webp', 'Sleek and transparent.', 'modern'),

-- 🖥️ DESK DECOR (Computers)
(300, 'Modern Workstation', 'furniture', 'desk_decor', 75, 'assets/images/furniture/computer_0.webp', 'A high-performance system.', 'modern'),
(301, 'Advanced Terminal', 'furniture', 'desk_decor', 75, 'assets/images/furniture/computer_1.webp', 'Professional-grade processing.', 'tech'),
(302, 'Dual Monitor Setup', 'furniture', 'desk_decor', 125, 'assets/images/furniture/computer_2.webp', 'Multitasking enabled.', 'tech'),
(303, 'Compact Laptop', 'furniture', 'desk_decor', 50, 'assets/images/furniture/computer_3.webp', 'Portable and efficient.', 'modern'),

-- 🏥 CLINICAL (Gurneys)
(400, 'Basic Exam Bed', 'furniture', 'exam_table', 150, 'assets/images/furniture/gurney_0.webp', 'Standard issue.', 'clinical'),
(401, 'Advanced Gurney', 'furniture', 'exam_table', 150, 'assets/images/furniture/gurney_1.webp', 'With hydraulic lift support.', 'clinical'),
(402, 'Surgical Table', 'furniture', 'exam_table', 250, 'assets/images/furniture/gurney_2.webp', 'Precision adjustment capability.', 'clinical'),
(403, 'Recovery Bed', 'furniture', 'exam_table', 200, 'assets/images/furniture/gurney_3.webp', 'Comfortable for post-op.', 'clinical'),

-- 📦 CORNER CABINETS
(700, 'Basic File Cabinet', 'furniture', 'corner_cabinet', 80, 'assets/images/furniture/cornercabinet_0.webp', 'Essential storage.', 'office'),
(701, 'Tall Shelf', 'furniture', 'corner_cabinet', 90, 'assets/images/furniture/cornercabinet_1.webp', 'Maximize vertical space.', 'modern'),
(702, 'Glass Display', 'furniture', 'corner_cabinet', 110, 'assets/images/furniture/cornercabinet_2.webp', 'Showcase your achievements.', 'modern'),
(703, 'Medical Supply Cabinet', 'furniture', 'corner_cabinet', 100, 'assets/images/furniture/cornercabinet_3.webp', 'Keep supplies organized.', 'clinical');

-- 🧶 RUGS
INSERT INTO public.items (id, name, type, slot_type, price, asset_path, description, theme) VALUES
(800, 'Welcome Mat', 'furniture', 'rug', 30, 'assets/images/furniture/rug_0.webp', 'A warm welcome.', 'cozy'),
(801, 'Persian Rug', 'furniture', 'rug', 150, 'assets/images/furniture/rug_1.webp', 'Adds elegance.', 'classic'),
(802, 'Modern Geometric Rug', 'furniture', 'rug', 80, 'assets/images/furniture/rug_2.webp', 'Contemporary style.', 'modern');
