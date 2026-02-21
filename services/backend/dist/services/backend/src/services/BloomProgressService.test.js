"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const BloomProgressService_1 = require("./BloomProgressService");
describe('BloomProgressService calculateNewState', () => {
    const defaultState = {
        currentBloomLevel: 1,
        streakCorrect: 0,
        streakWrong: 0
    };
    test('correct answer increments streakCorrect and zeroes streakWrong', () => {
        const state = { ...defaultState, streakCorrect: 3, streakWrong: 2 };
        const newState = BloomProgressService_1.BloomProgressService.calculateNewState(state, true);
        expect(newState.currentBloomLevel).toBe(1);
        expect(newState.streakCorrect).toBe(4);
        expect(newState.streakWrong).toBe(0);
    });
    test('incorrect answer increments streakWrong and zeroes streakCorrect', () => {
        const state = { ...defaultState, streakCorrect: 5, streakWrong: 1 };
        const newState = BloomProgressService_1.BloomProgressService.calculateNewState(state, false);
        expect(newState.currentBloomLevel).toBe(1);
        expect(newState.streakCorrect).toBe(0);
        expect(newState.streakWrong).toBe(2);
    });
    // Level Up Scenarios
    test('striking 8 correct answers levels up bloom and zeroes streak', () => {
        const state = { ...defaultState, currentBloomLevel: 2, streakCorrect: 7 };
        const newState = BloomProgressService_1.BloomProgressService.calculateNewState(state, true);
        expect(newState.currentBloomLevel).toBe(3); // Level up from 2 to 3!
        expect(newState.streakCorrect).toBe(0);
        expect(newState.streakWrong).toBe(0);
    });
    test('bloom level maxes out at 6', () => {
        const state = { ...defaultState, currentBloomLevel: 6, streakCorrect: 7 };
        const newState = BloomProgressService_1.BloomProgressService.calculateNewState(state, true);
        expect(newState.currentBloomLevel).toBe(6); // Stays at 6
        expect(newState.streakCorrect).toBe(0);
        expect(newState.streakWrong).toBe(0);
    });
    // Level Down Scenarios
    test('striking 5 wrong answers levels down bloom and zeroes streak', () => {
        const state = { ...defaultState, currentBloomLevel: 3, streakWrong: 4 };
        const newState = BloomProgressService_1.BloomProgressService.calculateNewState(state, false);
        expect(newState.currentBloomLevel).toBe(2); // Level down from 3 to 2!
        expect(newState.streakCorrect).toBe(0);
        expect(newState.streakWrong).toBe(0);
    });
    test('bloom level floors at 1', () => {
        const state = { ...defaultState, currentBloomLevel: 1, streakWrong: 4 };
        const newState = BloomProgressService_1.BloomProgressService.calculateNewState(state, false);
        expect(newState.currentBloomLevel).toBe(1); // Stays at 1
        expect(newState.streakCorrect).toBe(0);
        expect(newState.streakWrong).toBe(0);
    });
});
