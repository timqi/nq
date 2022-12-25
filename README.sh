#!/bin/sh
# curl https://raw.githubusercontent.com/timqi/nq/main/README.sh |sh

nq_path="$HOME/.config/nq"
if [ -d $nq_path ]; then
    cd $nq_path
    git pull
else
    git clone https://github.com/timqi/nq.git $nq_path
fi

case `uname -s` in
Linux) sudo ln -sfv $nq_path/nq /usr/bin;;
Darwin) ln -sfv $nq_path/nq/nq ~/.local/bin;; 
esac

