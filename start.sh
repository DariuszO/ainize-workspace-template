echo "Run TTYD"
echo "Password: $PASSWORD"

chmod -R 555 /workspace

if [ -z "$PASSWORD" ]
then
TTYD_PASS=
else
TTYD_PASS="-c :$PASSWORD"
fi
# Do not change the port number 8020.
ttyd -p 8020 $TTYD_PASS bash &

tail -f /dev/null
