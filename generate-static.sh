#!/usr/bin/env sh

./make_style.sh
echo yes | python3 manage.py collectstatic
python3 manage.py compilemessages
python3 manage.py compilejsi18n
