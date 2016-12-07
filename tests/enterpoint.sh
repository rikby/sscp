#!/usr/bin/env bash

if [ -f /code/sscp ] && [ ! -L /usr/local/bin/sscp ] ; then
  ln -s /code/sscp /usr/local/bin/sscp
  chmod +x /usr/local/bin/sscp /code/sscp
fi

$@
