import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        glass: 'rgba(255,255,255,0.08)',
        border: 'rgba(255,255,255,0.18)',
        accent: '#22d3ee'
      },
      backdropBlur: {
        xs: '2px'
      }
    }
  },
  plugins: []
};

export default config;