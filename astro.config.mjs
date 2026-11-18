import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://dar-hdiya-demo.netlify.app',
  i18n: {
    locales: ['fr', 'ar', 'en'],
    defaultLocale: 'fr',
    routing: { prefixDefaultLocale: true, redirectToDefaultLocale: true },
  },
});
