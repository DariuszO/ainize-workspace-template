echo "Run TTYD"
echo "Password: $PASSWORD"

if [ "$GH_REPO" ]
then
  echo "Github Repo: $GH_REPO"
  git clone ${GH_REPO}
  git config --global user.email "$USER_EMAIL"
  git config --global user.name "$USER_NAME"
fi

if [ -z "$PASSWORD" ]
then
TTYD_PASS=
else
TTYD_PASS="-c :$PASSWORD"
fi
# Do not change the port number 8020.
ttyd -p 8020 $TTYD_PASS bash &

tail -f /dev/null
