if ! user-lock-exists "luajit-base"; then
  user-luajit-init
  user-lock "luajit-base"
fi

if ! xdg-config-exists-kitty; then
  symlink ~/.user/kitty ~/.config/kitty 
fi

mapkeys "\M-@" cd-project
mapkeys "\M-_" cd-project-in-home

{
  env_files_dir="$MY_DIR/env"
  mapfile -t env_files < <(find "$env_files_dir" -type f -name "*.sh")
  for env in ${env_files[@]}; do source "$env"; done
  unset env_files_dir
  unset env_files
}
