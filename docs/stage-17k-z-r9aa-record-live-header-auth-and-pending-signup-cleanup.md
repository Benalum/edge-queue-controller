# Stage 17K-Z-R9AA — Record Live Header/Auth Fixes and Pending Signup Cleanup

This checkpoint captures the current good VM200 state into source before starting the local-save work.

## Recorded live fixes

- R9W: removed the public-served `/?logout=1&v=` hard logout URL generator.
- R9W: cache-busted `/auth/auth.js`.
- R9X: removed the R9V header interception block that broke Login/Register.
- R9X: restored the left logo/brand home link.
- R9X: cache-busted `/header/header.js`.

## Recorded DB cleanup verification

R9Z-R2 deleted only the four exact unconsumed pending signup rows requested by the user.

Remaining expected pending signup state:

- one consumed pending signup row for `mirellagdlc@gmail.com`

Expected active accounts:

- `alexhartel179@gmail.com`
- `mirellagdlc@gmail.com`

## Safety

Registration remains closed with `closed_beta_signup_disabled`.

No deploy, DB write, schema change, service restart, email send, signup opening, Google OAuth, or Google Drive API work was performed by this checkpoint.
