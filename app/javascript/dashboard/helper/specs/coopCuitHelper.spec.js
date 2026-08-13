import { describe, it, expect } from 'vitest';
import { normalizeCuit, isValidCuit } from '../coopCuitHelper';

// Mirrors spec/custom/models/coop_core/producer/cuit_spec.rb (the backend
// source of truth at custom/app/models/coop_core/producer/cuit.rb) so the
// client-side mod-11 check stays in lockstep with the server.
describe('coopCuitHelper', () => {
  describe('isValidCuit', () => {
    it.each([
      [
        'a valid mod-11 CUIT (spec Domain 3 example: 20-12345678-6, sum=148, remainder=5, check digit=6)',
        '20-12345678-6',
        true,
      ],
      [
        'an 11-digit CUIT whose check digit does not match the mod-11 result',
        '20-12345678-0',
        false,
      ],
      [
        'a correct check digit but an unknown type prefix (base digits 9912345678 -> remainder 10 -> check digit 1)',
        '99-12345678-1',
        false,
      ],
      ['fewer than 11 digits', '20-1234567-6', false],
      ['more than 11 digits', '20-123456789-6', false],
      ['a blank value', '', false],
      ['a null value', null, false],
      ['an undefined value', undefined, false],
      [
        'a value with dashes and spaces normalized before validation',
        '20 12345678 6',
        true,
      ],
    ])('%s', (_description, input, expected) => {
      expect(isValidCuit(input)).toBe(expected);
    });

    // base digits 2001000000 -> weighted sum 12, remainder 12 % 11 = 1,
    // which maps to no valid check digit (Domain 3: remainder 1 has no
    // solution). Every trailing digit must therefore be rejected.
    it('rejects every possible trailing digit when the weighted sum has remainder 1', () => {
      for (let trailingDigit = 0; trailingDigit <= 9; trailingDigit += 1) {
        expect(isValidCuit(`20-01000000-${trailingDigit}`)).toBe(false);
      }
    });
  });

  describe('normalizeCuit', () => {
    it.each([
      ['strips dashes', '20-12345678-6', '20123456786'],
      ['strips spaces', '20 12345678 6', '20123456786'],
      ['strips mixed dash/space separators', '20-12345678 6', '20123456786'],
      ['returns an empty string for null', null, ''],
      ['returns an empty string for undefined', undefined, ''],
      ['returns an empty string for a blank value', '', ''],
    ])('%s', (_description, input, expected) => {
      expect(normalizeCuit(input)).toBe(expected);
    });
  });
});
