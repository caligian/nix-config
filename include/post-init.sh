if [[ ! -f ~/.config/kitty/kitty.conf ]]; then
  [[ ! -d ~/.config/kitty ]] && mkdir -p ~/.config/kitty
  ln -sf $MY_DIR/kitty ~/.config/kitty
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
