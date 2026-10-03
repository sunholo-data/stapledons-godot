// @ts-check
// Stapledon's Voyage showcase site. The theme, fonts and navbar/footer shape
// follow the AILANG docs site and AILANG World (sunholo-data/ailang-world,
// website/) so the family reads as one.

import {themes as prismThemes} from 'prism-react-renderer';

// Where the site is served. Both are configurable at build time:
//   SITE_URL=https://www.sunholo.com BASE_URL=/stapledons-godot/ npm run build
const SITE_URL = process.env.SITE_URL || 'https://sunholo-data.github.io';
const BASE_URL_RAW = process.env.BASE_URL || '/';
const BASE_URL = BASE_URL_RAW.endsWith('/') ? BASE_URL_RAW : `${BASE_URL_RAW}/`;

const GITHUB_URL = 'https://github.com/sunholo-data/stapledons-godot';
const DESIGN_URL = 'https://github.com/sunholo-data/stapledons-design';
const AILANG_URL = 'https://ailang.sunholo.com';

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: "Stapledon's Voyage",
  tagline:
    'A hard-SF voyage at near light speed. One hand-wave, the Higgs bubble; everything else is real relativity, rendered from the real nearby stars.',
  favicon: 'https://ailang.sunholo.com/img/favicon.ico',

  url: SITE_URL,
  baseUrl: BASE_URL,

  // Publishing is the owner's call: `make site-deploy` (see website/README.md).
  organizationName: 'sunholo-data',
  projectName: 'stapledons-godot',
  deploymentBranch: 'gh-pages',
  trailingSlash: false,

  onBrokenLinks: 'throw',
  onBrokenAnchors: 'warn',

  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'throw',
    },
  },

  headTags: [
    {tagName: 'link', attributes: {rel: 'preconnect', href: 'https://fonts.googleapis.com'}},
    {
      tagName: 'link',
      attributes: {rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: 'anonymous'},
    },
    {
      tagName: 'link',
      attributes: {
        rel: 'stylesheet',
        href: 'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;600&family=Montserrat:wght@600;700;800&display=swap',
      },
    },
    {
      tagName: 'link',
      attributes: {rel: 'icon', type: 'image/svg+xml', href: `${BASE_URL}img/ailang-logo.svg`},
    },
    // The videos are served from the public asset bucket.
    {tagName: 'link', attributes: {rel: 'preconnect', href: 'https://storage.googleapis.com'}},
  ],

  i18n: {defaultLocale: 'en', locales: ['en']},

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: './sidebars.js',
          routeBasePath: '/docs',
          editUrl: `${GITHUB_URL}/tree/main/website/`,
        },
        blog: false,
        theme: {customCss: './src/css/custom.css'},
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      image: 'img/social-card.jpg',
      metadata: [
        {name: 'keywords', content: 'special relativity, general relativity, hard science fiction, Godot, AILANG, aberration, Doppler, time dilation, Gaia'},
      ],
      navbar: {
        title: "Stapledon's Voyage",
        logo: {alt: 'AILANG logo', src: 'img/ailang-logo.svg'},
        items: [
          {to: '/docs/intro', label: 'The game', position: 'left'},
          {to: '/docs/physics', label: 'The physics', position: 'left'},
          {to: '/gallery', label: 'Gallery', position: 'left'},
          {to: '/docs/built-with-ailang', label: 'Built with AILANG', position: 'left'},
          {to: '/docs/roadmap', label: 'Roadmap', position: 'left'},
          {href: AILANG_URL, label: 'AILANG', position: 'right'},
          {href: GITHUB_URL, label: 'GitHub', position: 'right'},
        ],
      },
      footer: {
        style: 'dark',
        logo: {alt: 'AILANG logo', src: 'img/ailang-logo.svg', href: AILANG_URL, width: 48, height: 48},
        links: [
          {
            title: 'The game',
            items: [
              {label: 'What it is', to: '/docs/intro'},
              {label: 'The physics', to: '/docs/physics'},
              {label: 'The Higgs bubble', to: '/docs/higgs-bubble'},
              {label: 'Gallery', to: '/gallery'},
              {label: 'Try it', to: '/docs/try-it'},
            ],
          },
          {
            title: 'Project',
            items: [
              {label: 'Game repo (Godot + AILANG)', href: GITHUB_URL},
              {label: 'Design repo', href: DESIGN_URL},
              {label: 'Relativity spec', href: `${DESIGN_URL}/blob/main/physics/relativity-spec.md`},
              {label: 'Roadmap', to: '/docs/roadmap'},
              {label: 'Credits and licences', to: '/docs/credits'},
              {label: 'License (Apache-2.0)', href: `${GITHUB_URL}/blob/main/LICENSE`},
            ],
          },
          {
            title: 'AILANG family',
            items: [
              {label: 'AILANG language', href: AILANG_URL},
              {label: 'AILANG on GitHub', href: 'https://github.com/sunholo-data/ailang'},
              {label: 'AILANG World', href: 'https://www.sunholo.com/ailang-world/'},
              {
                label: 'sunholo/relativity package',
                href: 'https://github.com/sunholo-data/ailang-packages/tree/main/packages/relativity',
              },
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} Sunholo / Mark Edmondson. Code: Apache-2.0. Milky Way panorama: E. Slawik / NOIRLab / NSF / AURA, CC BY 4.0. Built with Docusaurus.`,
      },
      prism: {
        theme: prismThemes.github,
        darkTheme: prismThemes.dracula,
        additionalLanguages: ['bash', 'json'],
      },
      colorMode: {
        defaultMode: 'dark',
        disableSwitch: false,
        respectPrefersColorScheme: false,
      },
    }),
};

export default config;
