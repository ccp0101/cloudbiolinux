export REPO_PATH="/home/ubuntu/genome-designer-v2"
export GENOME_DESIGNER_PATH="${REPO_PATH}/genome_designer"
export JBROWSE_PATH="${REPO_PATH}/jbrowse"
export DJANGO_PORT=8000

cd $REPO_PATH
git submodule update --init --recursive

pushd jbrowse
./setup.sh
popd

pushd genome_designer
ln -s ../jbrowse jbrowse
popd

pushd genome_designer
./setup.py
popd

pushd genome_designer
python manage.py test
popd

pushd config
cat > nginx.config << EOF
server {
  server_name localhost;

  location /jbrowse {
    alias ${JBROWSE_PATH};
  }

  location /static {
    alias ${GENOME_DESIGNER_PATH}/main/static;
  }

  location / {
    proxy_pass http://127.0.0.1:${DJANGO_PORT};
  }
}
EOF

popd

cat > supervisord.conf << EOF
[supervisord]

[program:gunicorn]
command=gunicorn_django -b 127.0.0.1:${DJANGO_PORT} --workers=4
directory=${GENOME_DESIGNER_PATH}
autostart=True
autorestart=True
redirect_stderr=True

[program:celery]
command=python manage.py celery worker --loglevel=info
directory=${GENOME_DESIGNER_PATH}
autostart=True
autorestart=True
redirect_stderr=True

EOF

sudo ln -s "${REPO_PATH}/config/nginx.config" /etc/nginx/sites-enabled/genome_designer
sudo rm /etc/nginx/sites-enabled/default
sudo /etc/init.d/nginx restart


