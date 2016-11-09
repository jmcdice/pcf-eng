#!/bin/bash
#
# Deploy a simple hugo application for testing CF
# Joey <jmcdonald@pivotal.io>

app='blue'

function cf_push_hugo() {

   # Build a new site in hugo, apply a theme and add a simple hugo config.
   local app=$1
   mkdir $app
   hugo new site $app
   cd $app
   git clone https://github.com/fredrikloch/hugo-uno.git themes/hugo-uno/
   hugo new post/version-1.md
   echo 'theme = "hugo-uno"' >> config.toml
   echo 'basedirectory = "/"' >> config.toml
   perl -pi -e 's/baseurl.*?$//' config.toml
   perl -pi -e 's/title.*?$/title = "Congratulations"/' config.toml
   hugo -Ds '' -t hugo-uno
   perl -pi -e 's/This site.*?$/CF Successfully Deployed <\/p>/' \
     public/categories/index.html \
     public/index.html \
     public/post/version-1/index.html \
     public/tags/index.html \
     themes/hugo-uno/layouts/partials/sidebar.html

   # Generate an application manifest for my sample app.
   cat << EOF > manifest.yml
---
applications:
- name: $app-1
  memory: 512M 
  instances: 1
  buildpack: https://github.com/cloudfoundry/staticfile-buildpack
  path: public
EOF

   # Push to Cloud Foundry
   cf push
}

# Make sure we got some sane looking command line options.

which -s hugo &> /dev/null
if [ $? != '0' ]; then
  echo ""
  echo "   Please install hugo."
  exit 255
fi

action=$1
if [ "$action" = 'deploy' ]; then
  echo "Deploying hugo: $app"
  cf_push_hugo $app
elif [ "$action" = 'delete' ]; then
  cf delete -f $app-1
  rm -rf $app
else
  echo ""
  echo "  $0 [deploy|delete]"
  exit 255
fi

