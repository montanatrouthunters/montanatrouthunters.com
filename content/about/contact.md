---
# An instance of the Contact widget.
# Documentation: https://wowchemy.com/docs/getting-started/page-builder/
widget: contact

# This file represents a page section.
headless: true

# Order that this section appears on the page.
weight: 20

title: Contact-Us
subtitle:

content:
  # Automatically link email and phone or display as text?
  autolink: true

  phone: +1 (406) 451-3695

  # Social Links
  contact_links:
    - icon: facebook
      icon_pack: fab
      name: Send me a Facebook message
      link: https://m.me/Montana.Trout.Hunters/
    - icon: money-bill-alt
      name: Rates and Policies
      link: /rates-and-policies/
  # Email form provider
  form:
    provider: netlify
    netlify:
      captcha: true
    formspree:
      id: mjvlzkqj
design:
  columns: '1'
---
