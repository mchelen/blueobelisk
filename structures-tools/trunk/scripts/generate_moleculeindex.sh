#!/bin/sh

cd new 

ls | while read DIR; do
  if [ -d $DIR ]; then
    cd $DIR
    if [ -e molecule_update.xml ]; then
      rm molecule_update.xml
    fi
    ls *cml| while read FILE; do
      echo $FILE
      NAME=`echo $FILE |cut -d'.' -f1`
      IUPAC=`grep IUPAC $FILE | sed -e 's/<[^>]*>//g' -e 's/ //g'`
      DATE=`date +%Y-%m-%d`
      echo "  <molecule id=\"CS_${NAME}\">" >> molecule_update.xml
      echo "    <name>${IUPAC}</name>" >> molecule_update.xml
      echo "    <filename>${NAME}</filename>" >> molecule_update.xml
      echo "    <authors>Jerome Pansanel</authors>" >> molecule_update.xml
      echo "    <date>${DATE}</date>" >> molecule_update.xml
      echo "  </molecule>" >> molecule_update.xml
    done
    cd ..
  fi
done
