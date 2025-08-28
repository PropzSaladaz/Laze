/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./index.html', './src/**/*.{ts,tsx,js,jsx}'],
  presets: [require('./app/theme/tailwind.preset.cjs')],
};
