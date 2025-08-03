### Other Worldlee
Idk some vibe coded BS.

#### Steps to prod
##### Database
- create postgres database in firebase. Step 1) create project, Step 2) Upgrade to "blaze" plan, Step 3) find "realtime database"
- add new connection in google cloud
- save DATABASE_URL as GH secret
##### Domain
- create domain
- point it to my hetzner server IP
- update `proxy` to point to new domain name in config/deploy.yaml (ssl: true allows this to be https)
##### CD
- add new dockerhub repo, create new PAT, save in GH secrets as KAMAL registry password.
- use .github/workflows/deploy.yml to set up your deploy pipeline
- you'll need to set up your ssh key for the hetzner server in GH secret
##### Monitoring
- use app signal
