-- 🧨 DANGER: This script wipes all player inventory items!
-- Run this in your Supabase SQL Editor to reset for the new furniture system.

DELETE FROM public.user_items;

-- Optional: Reset coins if you want a full fresh start (uncomment below)
-- UPDATE public.profiles SET coins = 1000;
