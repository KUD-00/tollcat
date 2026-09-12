import type { ImageMetadata } from 'astro';
import type { Locale } from './config';
import dashboardEnDark from './assets/screenshots/iphone-dashboard-en-dark.png';
import dashboardEnLight from './assets/screenshots/iphone-dashboard-en-light.png';
import dashboardJaDark from './assets/screenshots/iphone-dashboard-ja-dark.png';
import dashboardJaLight from './assets/screenshots/iphone-dashboard-ja-light.png';
import dashboardZhDark from './assets/screenshots/iphone-dashboard-zh-dark.png';
import dashboardZhLight from './assets/screenshots/iphone-dashboard-zh-light.png';
import servicesEnDark from './assets/screenshots/iphone-services-en-dark.png';
import servicesEnLight from './assets/screenshots/iphone-services-en-light.png';
import servicesJaDark from './assets/screenshots/iphone-services-ja-dark.png';
import servicesJaLight from './assets/screenshots/iphone-services-ja-light.png';
import servicesZhDark from './assets/screenshots/iphone-services-zh-dark.png';
import servicesZhLight from './assets/screenshots/iphone-services-zh-light.png';
import wizardEnDark from './assets/screenshots/iphone-wizard-en-dark.png';
import wizardEnLight from './assets/screenshots/iphone-wizard-en-light.png';
import wizardJaDark from './assets/screenshots/iphone-wizard-ja-dark.png';
import wizardJaLight from './assets/screenshots/iphone-wizard-ja-light.png';
import wizardZhDark from './assets/screenshots/iphone-wizard-zh-dark.png';
import wizardZhLight from './assets/screenshots/iphone-wizard-zh-light.png';
import ipadDashboardEnDark from './assets/screenshots/ipad-bezel-dashboard-en-dark.png';
import ipadDashboardEnLight from './assets/screenshots/ipad-bezel-dashboard-en-light.png';
import ipadDashboardJaDark from './assets/screenshots/ipad-bezel-dashboard-ja-dark.png';
import ipadDashboardJaLight from './assets/screenshots/ipad-bezel-dashboard-ja-light.png';
import ipadDashboardZhDark from './assets/screenshots/ipad-bezel-dashboard-zh-dark.png';
import ipadDashboardZhLight from './assets/screenshots/ipad-bezel-dashboard-zh-light.png';
import ipadPortraitEnDark from './assets/screenshots/ipad-bezel-portrait-en-dark.png';
import ipadPortraitEnLight from './assets/screenshots/ipad-bezel-portrait-en-light.png';
import ipadPortraitJaDark from './assets/screenshots/ipad-bezel-portrait-ja-dark.png';
import ipadPortraitJaLight from './assets/screenshots/ipad-bezel-portrait-ja-light.png';
import ipadPortraitZhDark from './assets/screenshots/ipad-bezel-portrait-zh-dark.png';
import ipadPortraitZhLight from './assets/screenshots/ipad-bezel-portrait-zh-light.png';
import macWindowEnDark from './assets/screenshots/macbook-window-en-dark.png';
import macWindowEnLight from './assets/screenshots/macbook-window-en-light.png';
import macWindowJaDark from './assets/screenshots/macbook-window-ja-dark.png';
import macWindowJaLight from './assets/screenshots/macbook-window-ja-light.png';
import macWindowZhDark from './assets/screenshots/macbook-window-zh-dark.png';
import macWindowZhLight from './assets/screenshots/macbook-window-zh-light.png';
import macMenubarEnDark from './assets/screenshots/mac-menubar-en-dark.png';
import macMenubarEnLight from './assets/screenshots/mac-menubar-en-light.png';
import macMenubarJaDark from './assets/screenshots/mac-menubar-ja-dark.png';
import macMenubarJaLight from './assets/screenshots/mac-menubar-ja-light.png';
import macMenubarZhDark from './assets/screenshots/mac-menubar-zh-dark.png';
import macMenubarZhLight from './assets/screenshots/mac-menubar-zh-light.png';

export type PhoneShotPair = {
  light: ImageMetadata;
  dark: ImageMetadata;
};

const shots: Record<Locale, { dashboard: PhoneShotPair; wizard: PhoneShotPair; services: PhoneShotPair }> = {
  zh: {
    dashboard: { light: dashboardZhLight, dark: dashboardZhDark },
    wizard: { light: wizardZhLight, dark: wizardZhDark },
    services: { light: servicesZhLight, dark: servicesZhDark },
  },
  en: {
    dashboard: { light: dashboardEnLight, dark: dashboardEnDark },
    wizard: { light: wizardEnLight, dark: wizardEnDark },
    services: { light: servicesEnLight, dark: servicesEnDark },
  },
  ja: {
    dashboard: { light: dashboardJaLight, dark: dashboardJaDark },
    wizard: { light: wizardJaLight, dark: wizardJaDark },
    services: { light: servicesJaLight, dark: servicesJaDark },
  },
};

export function phoneShots(locale: Locale) {
  return shots[locale];
}

const ipad: Record<Locale, { dashboard: PhoneShotPair; portrait: PhoneShotPair }> = {
  zh: {
    dashboard: { light: ipadDashboardZhLight, dark: ipadDashboardZhDark },
    portrait: { light: ipadPortraitZhLight, dark: ipadPortraitZhDark },
  },
  en: {
    dashboard: { light: ipadDashboardEnLight, dark: ipadDashboardEnDark },
    portrait: { light: ipadPortraitEnLight, dark: ipadPortraitEnDark },
  },
  ja: {
    dashboard: { light: ipadDashboardJaLight, dark: ipadDashboardJaDark },
    portrait: { light: ipadPortraitJaLight, dark: ipadPortraitJaDark },
  },
};

const mac: Record<Locale, { window: PhoneShotPair; menubar: PhoneShotPair }> = {
  zh: {
    window: { light: macWindowZhLight, dark: macWindowZhDark },
    menubar: { light: macMenubarZhLight, dark: macMenubarZhDark },
  },
  en: {
    window: { light: macWindowEnLight, dark: macWindowEnDark },
    menubar: { light: macMenubarEnLight, dark: macMenubarEnDark },
  },
  ja: {
    window: { light: macWindowJaLight, dark: macWindowJaDark },
    menubar: { light: macMenubarJaLight, dark: macMenubarJaDark },
  },
};

export function ipadShots(locale: Locale) {
  return ipad[locale];
}

export function macShots(locale: Locale) {
  return mac[locale];
}
