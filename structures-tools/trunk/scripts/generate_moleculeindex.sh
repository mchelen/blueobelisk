#!/bin/sh

ls *cml| while read FILE; do
  echo $FILE
  NAME=`echo $FILE |cut -d'.' -f1`
  IUPAC=`grep IUPAC $FILE | sed -e 's/<[^>]*>//g' -e 's/ //g'`
  DATE=`date +%Y-%m-%d`
  echo "  <entry id=\"CS_${NAME}\">" >> molecule_update.xml
  echo "    <name xml:lang=\"en\">${IUPAC}</name>" >> molecule_update.xml
  echo "    <filename>${NAME}</filename>" >> molecule_update.xml
  echo "    <authors>Jerome Pansanel</authors>" >> molecule_update.xml
  echo "    <date>${DATE}</date>" >> molecule_update.xml
  echo "  </entry>" >> molecule_update.xml
done

