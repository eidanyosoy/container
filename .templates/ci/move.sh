folder=.templates

for i in ${folder[@]}; do
   find ./$i -maxdepth 1 -mindepth 1 -type f -exec basename {} \; | while read app; do
      APP=$(echo ${app} | sed "s#docker-##g" | sed "s#-nightly##g" | sed "s#-version##g" | sed "s#.sh##g")
        cp -rv ./.templates/${app}  "./.templates/${APP}-description.sh"
   done
done
