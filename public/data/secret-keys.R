library(secret)

## ==== Create a vault
## Run these lines ONCE ONLY
# my_vault <- "/Users/walkerharrison/Desktop/website/static/data/secret-vault.vault"
# create_vault(my_vault)

## ==== Create a user
## This uses the ssh-key we created above, run this code ONCE ONLY
# key_dir = "/Users/walkerharrison/.ssh"
# walkerharrison_public_key <- file.path(key_dir, "blog_vault.pub")
# walkerharrison_private_key <- file.path(key_dir, "blog_vault")
# add_user("walkerharrison", walkerharrison_public_key, vault = my_vault)

# add secrets then delete R after
add_secret("key", "value", user = "walkerharrison", vault = my_vault)
