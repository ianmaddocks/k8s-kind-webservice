CREATE
ssh-keygen -t rsa

ADD TO ICLOUD (optional)
ssh-add --apple-use-keychain ~/.ssh/id_rsa
create ~/.ssh/config with
    Host *
    UseKeychain yes
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_rsa

CONNECT TO SERVER
ssh <user>@<ip.address>
ssh-copy-id -i ~/.ssh/id_rsa.pub  <user>@<ip.address>
