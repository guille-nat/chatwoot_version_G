/**
 * CUIT (Clave Única de Identificación Tributaria) structural + mod-11
 * check-digit validation.
 *
 * This is a client-side port of the backend's source of truth at
 * `custom/app/models/coop_core/producer/cuit.rb` (CoopCore::Producer::Cuit).
 * It only exists to give the producer form instant feedback -- the server
 * remains the authority, and its 422 response is always surfaced too.
 */

// Known AR CUIT type prefixes: 20/23/24/26/27 persona física, 25 extranjero,
// 30/33/34 persona jurídica.
const PREFIXES = ['20', '23', '24', '25', '26', '27', '30', '33', '34'];
const WEIGHTS = [5, 4, 3, 2, 7, 6, 5, 4, 3, 2];

export const normalizeCuit = raw => String(raw ?? '').replace(/\D/g, '');

// weights 5,4,3,2,7,6,5,4,3,2 over the first 10 digits; remainder = sum mod
// 11; check digit = 11 - remainder, wrapping 11 -> 0; remainder 1 has no
// valid check digit (returns -1, which no real digit ever equals).
const checkDigit = firstTenDigits => {
  const sum = firstTenDigits
    .split('')
    .reduce((total, digit, index) => total + Number(digit) * WEIGHTS[index], 0);
  const remainder = sum % 11;

  if (remainder === 0) return 0;
  if (remainder === 1) return -1;
  return 11 - remainder;
};

export const isValidCuit = raw => {
  const digits = normalizeCuit(raw);
  if (digits.length !== 11) return false;
  if (!PREFIXES.includes(digits.slice(0, 2))) return false;

  return Number(digits[10]) === checkDigit(digits.slice(0, 10));
};

export const formatCuit = raw => {
  const digits = normalizeCuit(raw);
  if (digits.length !== 11) return raw;

  return `${digits.slice(0, 2)}-${digits.slice(2, 10)}-${digits.slice(10)}`;
};
