import { getPermalink } from './utils/permalinks';
import { SITE } from 'astrowind:config';

let currentYear = new Date().getFullYear();
let copyrightElement = `\u00A9 ${currentYear} ${SITE.name}. All rights reserved.`;

export const headerData = {
  links: [
    {
      text: 'Our Rivers',
      links: [
        {
          text: 'Gallatin River',
          href: getPermalink('/our-rivers#gallatin-river'),
        },
        {
          text: 'Madison River',
          href: getPermalink('/our-rivers#madison-river'),
        },
        {
          text: 'Missouri River',
          href: getPermalink('/our-rivers#missouri-river'),
        },
      ],
    },
    {
      text: 'Gear',
      links: [
        {
          text: 'Gear We Love',
          href: getPermalink('/gear-we-love'),
        },
        {
          text: 'Boats',
          href: getPermalink('/gear-we-love#boats'),
        },
        {
          text: 'Clothing',
          href: getPermalink('/gear-we-love#clothing'),
        },
        {
          text: 'Line',
          href: getPermalink('/gear-we-love#line'),
        },
        {
          text: 'Reels',
          href: getPermalink('/gear-we-love#reels'),
        },
        {
          text: 'Rods',
          href: getPermalink('/gear-we-love#rods'),
        },
        {
          text: 'Tippet',
          href: getPermalink('/gear-we-love#tippet'),
        },
        {
          text: 'Waders',
          href: getPermalink('/gear-we-love#waders'),
        },
        {
          text: 'Wading Boots',
          href: getPermalink('/gear-we-love#boots'),
        },
      ],
    },
    {
      text: 'About',
      href: getPermalink('/about'),
    },
    {
      text: 'Rates & Policies',
      href: getPermalink('/rates-and-policies'),
    },
    {
      text: 'Trip Insurance',
      href: getPermalink('/trip-insurance'),
    },
  ],
  actions: [{ text: 'Contact Us', href: '/contact' }],
};

export const footerData = {
  links: [
    {
      title: 'Company',
      links: [
        { text: 'About', href: getPermalink('/about') },
        { text: 'Contact', href: getPermalink('/contact') },
        { text: 'Our Rivers', href: getPermalink('/our-rivers') },
        { text: 'Gear We Love', href: getPermalink('/gear-we-love') },
        { text: 'Rates & Policies', href: getPermalink('/rates-and-policies') },
        { text: 'Trip Insurance', href: getPermalink('/trip-insurance') },
      ],
    },
  ],
  secondaryLinks: [
    { text: 'Terms', href: getPermalink('/terms') },
    { text: 'Privacy Policy', href: getPermalink('/privacy') },
  ],
  socialLinks: [
    { ariaLabel: 'Instagram', icon: 'tabler:brand-instagram', href: 'https://www.instagram.com/montanatrouthunters/' },
    { ariaLabel: 'Facebook', icon: 'tabler:brand-facebook', href: 'https://www.facebook.com/Montana.Trout.Hunters/' },
    { ariaLabel: 'Email', icon: 'tabler:mail', href: getPermalink('/contact') },
  ],
  footNote: copyrightElement,
};
