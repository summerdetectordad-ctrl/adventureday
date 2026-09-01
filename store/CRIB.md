# Play Console form answers — Adventure Day

Everything below is the literal answer to give. Your app is unusually simple to
declare because it genuinely collects nothing and cannot go online.

---

## Data safety form

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | N/A (nothing collected) |
| Do you provide a way for users to request that their data is deleted? | N/A (nothing collected) |

That is the whole form. Save and submit.

**If asked to justify:** the app declares no Android permissions at all and has
no INTERNET permission, so it is technically incapable of transmitting anything.
Verifiable in the uploaded bundle.

---

## Content rating questionnaire (IARC)

| Question | Answer |
|---|---|
| Category | **Game** |
| Violence — cartoon/fantasy | **No** |
| Violence — realistic | **No** |
| Blood/gore | **No** |
| Sexuality/nudity | **No** |
| Bad language | **No** |
| Controlled substances (drugs/alcohol/tobacco) | **No** |
| Gambling / simulated gambling | **No** |
| Horror / fear elements | **No** |
| User-generated content shared with others | **No** |
| Users can interact / communicate | **No** |
| Shares user location | **No** |
| Allows purchase of digital goods | **No** |
| Displays adverts | **No** |

Expected outcome: PEGI 3 / ESRB Everyone / USK 0.

**Note on the T-rex:** he growls and is grumpy, and is friendly within seconds.
There is no threat, no chase and no peril anywhere in the game. Answer "No" to
horror and violence with confidence.

---

## Target audience and content

| Question | Answer |
|---|---|
| Target age groups | **Ages 5 and under, and 6–8** |
| Is your app designed for children? | **Yes** |
| Does it appeal to children? | Yes |

This puts you in the **Families Policy** programme. Requirements it triggers,
and where you stand:

| Requirement | Status |
|---|---|
| Privacy policy URL | **https://adventureday.co.uk/privacy** — live ✅ |
| No ads, or certified Families ad SDK only | ✅ no ads at all |
| No collection of personal info from children | ✅ collects nothing |
| Content appropriate for the age declared | ✅ |
| No third-party analytics without disclosure | ✅ none present |
| Neutral age screen | Not required — no ads, no data, no purchases |

---

## Other declarations

| Question | Answer |
|---|---|
| App access (login required?) | **No, all functionality available without restrictions** |
| Ads | **No, my app does not contain ads** |
| Government app | No |
| Financial features | None |
| Health apps | No |
| News app | No |
| COVID-19 contact tracing | No |
| Data deletion request URL | N/A |

---

## Store listing fields

| Field | Where it is |
|---|---|
| App name | `LISTING.md` |
| Short description (80) | `LISTING.md` |
| Full description (4000) | `LISTING.md` |
| App icon 512×512 | `store/play_icon_512.png` |
| Feature graphic 1024×500 | `store/play_feature_1024x500.png` |
| Phone screenshots (min 2, max 8) | `store/screenshots/` |
| Category | Games → Educational |
| Contact email | summerdetectordad@gmail.com |
| Privacy policy URL | **https://adventureday.co.uk/privacy** — live |

---

## The privacy policy is live

**https://adventureday.co.uk/privacy**

Hosted on Firebase Hosting, project `adventureday-uk`, from the
`adventureday-site` repo. It must keep loading for as long as the app is
listed on Play.

The Markdown source of record is `store/PRIVACY.md` in this repo; the page
itself is `public/privacy.html` in the site repo. Change one, change the other.

To redeploy after an edit:

```bash
cd C:/adventureday-site && firebase deploy --only hosting
```
