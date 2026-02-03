# PLAN: Quiz Cozy-Premium Redesign

This plan outlines the visual overhaul of the quiz system to a "Refined Organic Journal" aesthetic, combining a warm, cozy feel with premium, professional execution.

## 🛠️ Design Specification
- **Color Palette**: 
    - Card Background: Warm Ivory/Cream (#FDFCF8)
    - Background Texture: Subtle Paper Grain (SVG or low-opacity noise)
    - Accents: Sage Green, Dusty Terracotta, Muted Blue
- **Typography**: 
    - Heading: Rounded Sans-Serif (e.g., 'Outfit' or 'Varela Round')
    - Body: High-readability Sans-Serif with gentle kerning
- **Interactions**:
    - "Liquid" active states for buttons (soft scaling + color bleed)
    - Card-spring animations (cards "settle" with a slight bounce)
- **Mascot**: Removed (as per user request).

## 📅 Task Breakdown

### Phase 1: Foundation & Asset Prep
- [ ] Prepare `paper_grain.png` or SVG noise asset
- [ ] Update `CozyTheme` with refined color tokens
- [ ] Register new rounded typography in `pubspec.yaml`
- [ ] Create `LiquidButton` component for the new tactile feel

### Phase 2: Core Quiz UI
- [ ] Redesign `QuizSessionScreen` layout with "Modern Journal" cards
- [ ] Implement backdrop-blur and soft-shadow layering
- [ ] Update `QuizProgressBar` to match the liquid/organic aesthetic
- [ ] Refactor `FeedbackBottomSheet` into an inline "Settling Card"

### Phase 3: Question Renderers
- [ ] Update `SingleChoiceRenderer` & `MultipleChoiceRenderer` for the new button style
- [ ] Add smooth opacity/height transitions for explanations
- [ ] Refine `RelationAnalysisRenderer` with more natural, organic toggles

### Phase 4: Micro-Interactions
- [ ] Add PageTransition for "settling" card effect
- [ ] Implement liquid-bleed effect on answer selection
- [ ] Fine-tune Haptic Feedback (mobile)

## 🏗️ Agent Assignments
- **Frontend Specialist**: Responsible for the UI implementation and animations.
- **Graphic Wizard**: Responsible for texture and typography integration.

## ✅ Verification Checklist
- [ ] Question text is legible across all screen sizes
- [ ] Paper texture is subtle and doesn't affect readability
- [ ] Animations are smooth (60 FPS) and don't feel sluggish
- [ ] Correct/Incorrect feedback remains instant and clear
