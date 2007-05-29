#!/bin/sh

cd new 

ls | while read DIR; do
  if [ -d $DIR ]; then
    cd $DIR
    ls *gpr| while read FILE; do
      echo $FILE
      NAME=`echo $FILE |cut -d'.' -f1`
      FORMULA=`babel -igpr ${NAME}.gpr -oreport 2> /dev/null | grep "^FORMULA" | sed -e "s/^.*: //"`
      CML_FORMULA=`mwcalc -p ${FORMULA} | grep "CML Formula" | sed -e "s/^.*://"`
      MASS=`babel -igpr $FILE -oreport 2> /dev/null |grep '^MASS' | sed -e "s/^.*: //"`
      EXACT_MASS=`babel -igpr $FILE -oreport 2> /dev/null |grep '^EXACT MASS' | sed -e "s/^.*: //"`
      babel -igpr ${NAME}.gpr -omol ${NAME}.mol
      ../../tools/cInChI-1 ${NAME}.mol
      INCHI_CODE=`cat ${NAME}.mol.txt |grep InChI|cut -d'=' -f2-`
      babel -igpr ${NAME}.gpr -ocml ${NAME}.cml
      cat ${NAME}.cml | sed -e "s#<molecule .*>#<molecule xmlns=\"http://www.xml-cml.org/schema/cml2/core\" id=\"CS_${NAME}\">\n <formula concise=\"${CML_FORMULA}\"/>\n <identifier version=\"InChI/1\">\n  <basic>${INCHI_CODE}</basic>\n </identifier>\n <name convention=\"IUPAC\">${NAME}</name>#" -e "s/<\/bondArray>/<\/bondArray>\n <list>\n  <propertyList>\n   <property dictRef=\"cml:molwt\" title=\"molecular weight\">\n    <scalar dataType=\"xsd:decimal\" dictRef=\"cml:molwt\" units=\"unit:g\">${MASS}<\/scalar>\n   <\/property>\n   <property dictRef=\"chemwt:exact_molwt\" title=\"exact molecular weight\">\n    <scalar dataType=\"xsd:decimal\" dictRef=\"chemwt:exact_molwt\" units=\"unit:g\">${EXACT_MASS}<\/scalar>\n   <\/property>\n   <property dictRef=\"cml:mpt\" title=\"melting point\">\n    <scalar dataType=\"xsd:decimal\" errorValue=\"1.0\" dictRef=\"cml:mpt\" units=\"unit:celsius\"><\/scalar>\n   <\/property>\n   <property dictRef=\"cml:bpt\" title=\"boiling point\">\n    <scalar dataType=\"xsd:decimal\" errorValue=\"1.0\" dictRef=\"cml:bpt\" units=\"unit:celsius\"><\/scalar>\n   <\/property>\n  <\/propertyList>\n <\/list>/" > ${NAME}_1.cml 
      mv ${NAME}_1.cml ${NAME}.cml
      rm ${NAME}.mol*
    done
    cd ..
  fi
done
