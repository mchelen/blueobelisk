#!/bin/sh

ls *gpr| while read FILE; do
  echo $FILE
  NAME=`echo $FILE |cut -d'.' -f1`
  FORMULA=`babel -igpr ${NAME}.gpr -oreport 2> /dev/null | grep "^FORMULA" | sed -e "s/^.*: //"`
  CML_FORMULA=`mwcalc -p ${FORMULA} | grep "CML Formula" | sed -e "s/^.*://"`
  MASS=`babel -igpr $FILE -oreport 2> /dev/null |grep '^MASS' | sed -e "s/^.*: //"`
  EXACT_MASS=`babel -igpr $FILE -oreport 2> /dev/null |grep '^EXACT MASS' | sed -e "s/^.*: //"`
  babel -igpr ${NAME}.gpr -omol ${NAME}.mol
  INCHI_CODE=`babel -igpr ${NAME}.gpr -oinchi | sed -e's/InChI=//'`
  babel -igpr ${NAME}.gpr -ocml ${NAME}.cml
  cat ${NAME}.cml | sed -e "s/<?xml.*/<?xml version=\"1.0\" encoding=\"UTF-8\"?>/"\
 -e "s#<molecule .*>#<molecule xmlns=\"http://www.xml-cml.org/schema\"\n\
          xmlns:cml=\"http://www.xml-cml.org/dict/cml\"\n\
	  xmlns:units=\"http://www.xml-cml.org/units/units\"\n\
          xmlns:xsd=\"http://www.w3c.org/2001/XMLSchema\"\n\
          xmlns:iupac=\"http://www.iupac.org\"\n\
          id=\"CS_${NAME}\">\n\
  <formula concise=\"${CML_FORMULA}\"/>\n\
  <identifier convention=\"iupac:inchi\" value=\"${INCHI_CODE}\"/>\n\
  <name convention=\"IUPAC\">${NAME}</name>#"\
 -e's/.*<atomA/  <atomA/' \
 -e's/.*<atom /    <atom /' \
 -e's/.*<\/atomA/  <\/atomA/' \
 -e's/.*<bondA/  <bondA/' \
 -e's/.*<bond /    <bond /' \
 -e "s/.*<\/bondArray>/  <\/bondArray>\n\
  <propertyList>\n\
    <property dictRef=\"cml:molwt\" title=\"Molecular weight\">\n\
      <scalar dataType=\"xsd:double\" dictRef=\"cml:molwt\" units=\"units:g\">${MASS}<\/scalar>\n\
    <\/property>\n\
    <property dictRef=\"cml:monoisotopicwt\" title=\"Monoisotopic weight\">\n\
      <scalar dataType=\"xsd:double\" dictRef=\"cml:monoisotopicwt\" units=\"units:g\">${EXACT_MASS}<\/scalar>\n\
    <\/property>\n\
    <property dictRef=\"cml:mp\" title=\"Melting point\">\n\
      <scalar dataType=\"xsd:double\" errorValue=\"1.0\" dictRef=\"cml:mp\" units=\"units:celsius\"><\/scalar>\n\
    <\/property>\n\
    <property dictRef=\"cml:bp\" title=\"Boiling point\">\n\
      <scalar dataType=\"xsd:double\" errorValue=\"1.0\" dictRef=\"cml:bp\" units=\"units:celsius\"><\/scalar>\n\
    <\/property>\n\
  <\/propertyList>\n/" > ${NAME}_1.cml 
  mv ${NAME}_1.cml ${NAME}.cml
  rm ${NAME}.mol*
done
