# stage-17k-r16ap-load-disabled-visible-panel-dom-template-source-index-source-only

R16AP loads the disabled visible Study card image DOM template asset in the source  only.

## Scope

- PPB-runnable: yes.
- Interactive required: no.
- Remote SSH/sudo: no.
- Deploy: no.
- Live site changed: no.
- Source index changed: yes.

## Result

The source index now loads the disabled visible panel scripts in this order:

1. 
2. 
3. 

The DOM template remains disabled and inert. R16AP does not mount it, bind controls, open a file picker, render previews, write IndexedDB/blob/backup payloads, upload to the backend, sync to Google Drive, or mutate Anki data.

## Cache bust



## Evidence

- Smoke: 
- Source check: 
- SHA: 
